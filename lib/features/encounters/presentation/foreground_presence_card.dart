import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/valinor_colors.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/encounter_providers.dart';
import '../data/foreground_location_sources.dart';
import '../data/foreground_presence_preferences.dart';
import '../data/foreground_presence_refresher.dart';
import '../data/presence_providers.dart';
import '../domain/foreground_presence_controller.dart';

/// Account-keyed state prevents consent or an in-flight UI from crossing users.
class ForegroundPresenceCard extends ConsumerWidget {
  const ForegroundPresenceCard({this.emphasized = false, super.key});
  final bool emphasized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(currentUserIdProvider)
        .when(
          data: (id) => _AccountPresenceCard(
            key: ValueKey(id),
            userId: id,
            emphasized: emphasized,
          ),
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Loading presence controls…'),
            ),
          ),
          error: (_, _) => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sign in to manage voluntary presence.'),
            ),
          ),
        );
  }
}

class _AccountPresenceCard extends ConsumerStatefulWidget {
  const _AccountPresenceCard({
    super.key,
    required this.userId,
    required this.emphasized,
  });
  final bool emphasized;
  final String userId;
  @override
  ConsumerState<_AccountPresenceCard> createState() =>
      _AccountPresenceCardState();
}

class _AccountPresenceCardState extends ConsumerState<_AccountPresenceCard>
    with WidgetsBindingObserver {
  ForegroundPresenceStatus status = ForegroundPresenceStatus.inactive;
  bool consent = false;
  bool restoring = true;
  bool busy = false;
  bool stopping = false;
  bool stopFailed = false;
  bool stopConfirmed = false;
  DateTime? expiresAt;
  Timer? expiryTimer;
  String? feedback;
  ForegroundLocationFailure? failure;
  late final ForegroundPresenceRefresher refresher;
  bool _visible = false;
  bool _refreshAuthorized = false;
  AppLifecycleState? _lifecycle;

  ForegroundPresencePreferences get preferences =>
      ForegroundPresencePreferences(
        ref.read(localStorageProvider),
        widget.userId,
      );
  bool get stillThisAccount =>
      mounted && ref.read(currentUserIdProvider).value == widget.userId;
  bool get recorded =>
      status == ForegroundPresenceStatus.recorded ||
      status == ForegroundPresenceStatus.active;
  bool get canObserve =>
      stillThisAccount &&
      _visible &&
      (_lifecycle == null || _lifecycle == AppLifecycleState.resumed);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = WidgetsBinding.instance.lifecycleState;
    refresher = ForegroundPresenceRefresher(
      mayObserve: () => canObserve && _refreshAuthorized && !busy,
      refresh: _refresh,
    );
    unawaited(_restore());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _syncRefresher();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _syncRefresher();
  }

  void _syncRefresher() {
    final expiry = expiresAt;
    if (_refreshAuthorized && canObserve && !busy && expiry != null) {
      refresher.start(expiry);
    } else {
      refresher.pause();
      if (_refreshAuthorized && !canObserve && mounted) {
        ref.read(foregroundPresenceServiceProvider).cancelPendingObservation();
      }
    }
  }

  Future<void> _refresh() async {
    if (!canObserve || !_refreshAuthorized || busy) return;
    final service = ref.read(foregroundPresenceServiceProvider);
    final result = await service.refresh(
      consent: consent,
      isStillAuthorized: () =>
          canObserve &&
          _refreshAuthorized &&
          !busy &&
          expiresAt != null &&
          DateTime.now().toUtc().isBefore(expiresAt!),
    );
    if (!canObserve || !_refreshAuthorized || busy) return;
    if (result == ForegroundPresenceStatus.recorded) {
      // The secured RPC preserves the original deadline on refresh. Never
      // extend the client session, even if a stale server returns a later one.
      ref.invalidate(encountersForCurrentUserProvider);
    } else {
      refresher.pause();
      setState(() {
        _refreshAuthorized = false;
        failure = service.lastLocationFailure;
        feedback =
            'Presence updates paused. Your last record still expires automatically. Resume or use Stop.';
      });
    }
  }

  Future<void> _restore() async {
    try {
      final savedConsent = await preferences.hasConsent();
      final savedExpiry = await preferences.lastExpiry();
      if (!stillThisAccount) return;
      setState(() {
        consent = savedConsent;
        restoring = false;
        if (savedExpiry != null &&
            savedExpiry.isAfter(DateTime.now().toUtc())) {
          expiresAt = savedExpiry;
          status = ForegroundPresenceStatus.recorded;
          feedback =
              'Your last recorded presence has not reached its expiry. You can stop it below.';
        }
      });
      _scheduleExpiry();
    } catch (_) {
      if (mounted) {
        setState(() {
          restoring = false;
          feedback =
              'Couldn’t restore presence controls. Consent will be requested again. Stop is still available.';
        });
      }
    }
  }

  void _scheduleExpiry() {
    expiryTimer?.cancel();
    final expiry = expiresAt;
    if (expiry == null) return;
    final remaining = expiry.difference(DateTime.now().toUtc());
    void expire() {
      if (!mounted) return;
      refresher.pause();
      setState(() {
        _refreshAuthorized = false;
        status = ForegroundPresenceStatus.inactive;
        expiresAt = null;
        stopFailed = false;
        feedback =
            'Your last recorded presence has expired. Activate again only when you choose.';
      });
    }

    if (remaining <= Duration.zero) {
      expire();
    } else {
      expiryTimer = Timer(remaining, expire);
    }
  }

  Future<void> _activate() async {
    if (busy || restoring || (recorded && _refreshAuthorized) || !canObserve) {
      return;
    }
    final resuming = recorded && expiresAt != null;
    setState(() {
      busy = true;
      feedback = null;
      stopConfirmed = false;
    });
    try {
      if (!consent) {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Choose to be discoverable'),
            content: const SingleChildScrollView(
              child: Text(
                'Discovery location permission is separate from presence. When you choose “Activate presence”, your current location is sent to Mitzone to create a short-lived, coarse shared-place record. While this screen is visible and the app is in the foreground, it refreshes about once a minute, for at most 30 minutes. Other people do not see your exact coordinates. This makes you eligible for shared-context encounters. Mitzone does not collect presence in the background. The record expires automatically, or you can use Stop to remove your active presence record.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (accepted != true || !stillThisAccount) return;
        await preferences.saveConsent();
        if (!stillThisAccount) return;
        consent = true;
      }
      if (!stillThisAccount) return;
      setState(() {
        status = ForegroundPresenceStatus.locating;
        failure = null;
      });
      if (ref.read(productionModeProvider)) {
        final service = ref.read(foregroundPresenceServiceProvider);
        final result = resuming
            ? await service.refresh(
                consent: consent,
                isStillAuthorized: () =>
                    canObserve &&
                    expiresAt != null &&
                    DateTime.now().toUtc().isBefore(expiresAt!),
              )
            : await service.record(
                consent: consent,
                isStillAuthorized: () => canObserve,
                onLocationResolved: () {
                  if (stillThisAccount) {
                    setState(() => status = ForegroundPresenceStatus.recording);
                  }
                },
              );
        if (!stillThisAccount) return;
        setState(() {
          failure = service.lastLocationFailure;
          status = resuming && result != ForegroundPresenceStatus.recorded
              ? ForegroundPresenceStatus.recorded
              : result;
          if (resuming && result != ForegroundPresenceStatus.recorded) {
            feedback =
                'Couldn’t resume the existing session. Use Stop, then choose “I’m here” to start a new session.';
          }
          if (result == ForegroundPresenceStatus.recorded) {
            expiresAt = service.expiresAt;
            stopFailed = false;
            _refreshAuthorized = true;
          }
        });
        if (result == ForegroundPresenceStatus.recorded) {
          ref.invalidate(encountersForCurrentUserProvider);
          _scheduleExpiry();
          try {
            await preferences.saveExpiry(expiresAt);
          } catch (_) {
            if (mounted) {
              setState(
                () => feedback =
                    'Presence was recorded, but its local status could not be saved. Stop remains available.',
              );
            }
          }
        }
      } else {
        // Explicit local/test mode only: this never calls the server gateway.
        final evidence = await ref
            .read(locationObservationSourceProvider)
            .observeForeground();
        if (!stillThisAccount) return;
        setState(
          () => status = evidence.observedAt.isUtc
              ? ForegroundPresenceStatus.recorded
              : ForegroundPresenceStatus.unavailable,
        );
        if (evidence.observedAt.isUtc) {
          ref.invalidate(encountersForCurrentUserProvider);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          status = ForegroundPresenceStatus.unavailable;
          feedback = 'Couldn’t activate presence. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
      if (mounted) _syncRefresher();
    }
  }

  Future<void> _stop() async {
    if (busy || restoring) return;
    _refreshAuthorized = false;
    refresher.pause();
    setState(() {
      busy = true;
      stopping = true;
      feedback = null;
    });
    try {
      if (ref.read(productionModeProvider)) {
        await ref.read(foregroundPresenceServiceProvider).stop();
      }
      if (!stillThisAccount) return;
      expiryTimer?.cancel();
      setState(() {
        status = ForegroundPresenceStatus.inactive;
        expiresAt = null;
        stopFailed = false;
        stopConfirmed = true;
        feedback =
            'Your active presence record was stopped. This does not remove previous encounters or connections.';
      });
      ref.invalidate(encountersForCurrentUserProvider);
      try {
        await preferences.saveExpiry(null);
      } catch (_) {
        if (mounted) {
          setState(
            () => feedback =
                'Stop was confirmed, but local status could not be updated. No new presence is being recorded.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          stopFailed = true;
          feedback =
              'Couldn’t confirm Stop. Your previous presence may remain discoverable until its expiry. Retry Stop.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          stopping = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    refresher.pause();
    expiryTimer?.cancel();
    super.dispose();
  }

  void _showPrivacy() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Presence & privacy'),
      content: const SingleChildScrollView(
        child: Text(
          'Browsing and attendance intent do not activate presence. Activation sends your current location to Mitzone to create a coarse shared-place record. Other people do not see your exact coordinates. Updates occur only while these controls are visible and the app is in the foreground, for at most 30 minutes. Stop removes the active record; existing encounters and connections are retained. Contact requires mutual acceptance, and blocks restrict access.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = widget.emphasized
        ? Colors.white
        : theme.colorScheme.onSurface;
    final muted = widget.emphasized
        ? Colors.white.withValues(alpha: .85)
        : theme.colorScheme.onSurfaceVariant;
    final text = restoring
        ? 'Loading presence controls…'
        : switch (status) {
            ForegroundPresenceStatus.locating => 'Finding your location…',
            ForegroundPresenceStatus.recording => 'Confirming your presence…',
            ForegroundPresenceStatus.recorded ||
            ForegroundPresenceStatus.active => 'Presence active',
            ForegroundPresenceStatus.unavailable =>
              'We couldn’t confirm your location.',
            _ =>
              stopConfirmed
                  ? 'Presence stopped.'
                  : 'Off until you choose to activate.',
          };
    final stopLabel = stopping
        ? 'Stopping…'
        : stopFailed
        ? 'Retry Stop'
        : 'Stop';
    return Card(
      color: widget.emphasized ? ValinorColors.blue : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Voluntary presence',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Presence privacy',
                  onPressed: _showPrivacy,
                  color: foreground,
                  icon: const Icon(Icons.info_outline, size: 20),
                ),
              ],
            ),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 4),
            Text(
              'Coarse place · foreground only · up to 30 minutes',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (expiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Record expires at ${TimeOfDay.fromDateTime(expiresAt!.toLocal()).format(context)}.',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            if (recorded || stopFailed) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: busy || restoring ? null : _stop,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(stopLabel),
              ),
            ],
            if (feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    feedback!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.emphasized
                          ? foreground
                          : stopFailed
                          ? theme.colorScheme.error
                          : muted,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (failure ==
                    ForegroundLocationFailure.permissionPermanentlyDenied ||
                failure == ForegroundLocationFailure.servicesDisabled)
              TextButton(
                onPressed: busy
                    ? null
                    : () =>
                          failure == ForegroundLocationFailure.servicesDisabled
                          ? Geolocator.openLocationSettings()
                          : Geolocator.openAppSettings(),
                child: const Text('Settings'),
              ),
            if (!recorded || !_refreshAuthorized)
              FilledButton(
                onPressed: busy || restoring ? null : _activate,
                child: Text(
                  recorded
                      ? 'Resume presence'
                      : status == ForegroundPresenceStatus.unavailable
                      ? 'Try again'
                      : 'Activate presence',
                ),
              ),
            // Missing local expiry does not prove the server has no record.
            if (!recorded && !stopFailed && ref.watch(productionModeProvider))
              TextButton(
                onPressed: busy || restoring ? null : _stop,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: Text(stopLabel),
              ),
          ],
        ),
      ),
    );
  }
}
