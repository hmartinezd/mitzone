import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/presence_providers.dart';
import '../domain/foreground_presence_controller.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/storage_providers.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../data/foreground_location_sources.dart';
import '../data/encounter_providers.dart';

class ForegroundPresenceCard extends ConsumerStatefulWidget {
  const ForegroundPresenceCard({super.key});
  @override
  ConsumerState<ForegroundPresenceCard> createState() =>
      _ForegroundPresenceCardState();
}

class _ForegroundPresenceCardState extends ConsumerState<ForegroundPresenceCard>
    with WidgetsBindingObserver {
  ForegroundPresenceStatus status = ForegroundPresenceStatus.inactive;
  bool consent = false;
  bool stopped = false;
  Timer? expiryTimer;
  bool _inFlight = false;
  ForegroundLocationFailure? failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>(() async {
      final value = await ref
          .read(localStorageProvider)
          .getBool('foreground_presence_consent.v1');
      if (mounted && value == true) setState(() => consent = true);
    });
  }

  Future<void> _activate() async {
    if (_inFlight) return;
    if (!consent) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discover people nearby'),
          content: const Text(
            'When you choose “I’m here”, Mitzone may use your current location while this feature is active to help discover people associated with nearby real-world activity. It uses coarse place context, not your exact location, and does not track you in the background. You can stop at any time.',
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
      if (accepted != true || !mounted) return;
      consent = true;
      await ref
          .read(localStorageProvider)
          .setBool('foreground_presence_consent.v1', true);
    }
    setState(() {
      status = ForegroundPresenceStatus.locating;
      _inFlight = true;
      failure = null;
    });
    try {
      if (ref.read(productionModeProvider)) {
        final service = ref.read(foregroundPresenceServiceProvider);
        final result = await service.record(
          consent: consent,
          onLocationResolved: () {
            if (mounted) {
              setState(() => status = ForegroundPresenceStatus.recording);
            }
          },
        );
        if (mounted) {
          failure = service.lastLocationFailure;
          setState(() => status = result);
          _inFlight = false;
          if (result == ForegroundPresenceStatus.recorded) {
            ref.invalidate(encountersForCurrentUserProvider);
          }
          expiryTimer?.cancel();
          final expiry = service.expiresAt;
          if (result == ForegroundPresenceStatus.recorded && expiry != null) {
            expiryTimer = Timer(expiry.difference(DateTime.now().toUtc()), () {
              if (mounted) {
                setState(() {
                  status = ForegroundPresenceStatus.inactive;
                  stopped = false;
                });
              }
            });
          }
        }
      } else {
        final evidence = await ref
            .read(locationObservationSourceProvider)
            .observeForeground();
        if (mounted) {
          setState(
            () => status = evidence.observedAt.isUtc
                ? ForegroundPresenceStatus.recorded
                : ForegroundPresenceStatus.unavailable,
          );
          if (evidence.observedAt.isUtc) {
            ref.invalidate(encountersForCurrentUserProvider);
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => status = ForegroundPresenceStatus.unavailable);
      }
    } finally {
      _inFlight = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = Text(
      switch (status) {
        ForegroundPresenceStatus.locating => 'Finding your location…',
        ForegroundPresenceStatus.recording => 'Confirming your presence…',
        ForegroundPresenceStatus.recorded || ForegroundPresenceStatus.active =>
          'You’re discoverable here for a limited time.',
        ForegroundPresenceStatus.unavailable =>
          'We couldn’t confirm your location.',
        _ => 'Discover people you may have shared a place and time with.',
      },
      style: theme.textTheme.bodySmall?.copyWith(
        color: const Color(0xFFA6B3C4),
        height: 1.35,
      ),
    );
    final actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      children: [
        if (failure == ForegroundLocationFailure.permissionPermanentlyDenied)
          TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text('Settings'),
          )
        else if (failure == ForegroundLocationFailure.servicesDisabled)
          TextButton(
            onPressed: () => Geolocator.openLocationSettings(),
            child: const Text('Settings'),
          )
        else if (status == ForegroundPresenceStatus.unavailable)
          TextButton(onPressed: _activate, child: const Text('Try again')),
        if (status == ForegroundPresenceStatus.recorded ||
            status == ForegroundPresenceStatus.active)
          TextButton(
            onPressed: () async {
              try {
                if (ref.read(productionModeProvider)) {
                  await ref
                      .read(foregroundPresenceGatewayProvider)
                      .stopForegroundPresence();
                }
                if (mounted) {
                  setState(() {
                    stopped = true;
                    status = ForegroundPresenceStatus.inactive;
                  });
                }
              } catch (_) {}
            },
            child: const Text('Stop'),
          )
        else if (!stopped)
          SizedBox(
            width: 104,
            child: FilledButton(
              onPressed:
                  status == ForegroundPresenceStatus.locating ||
                      status == ForegroundPresenceStatus.recording
                  ? null
                  : _activate,
              child: const Text('I’m here'),
            ),
          ),
      ],
    );

    return Card(
      color: const Color(0xFF0D1724),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E2C3B)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canShowInline =
                constraints.maxWidth /
                    MediaQuery.textScalerOf(context).scale(1) >=
                300;
            if (canShowInline) {
              return Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 8),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 4), actions],
            );
          },
        ),
      ),
    );
  }
}
