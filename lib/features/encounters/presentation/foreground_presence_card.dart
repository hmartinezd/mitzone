import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/foreground_presence_service.dart';
import '../data/presence_providers.dart';
import '../domain/foreground_presence_controller.dart';
import '../domain/presence_consent.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/storage_providers.dart';

class ForegroundPresenceCard extends ConsumerStatefulWidget {
  const ForegroundPresenceCard({super.key});
  @override ConsumerState<ForegroundPresenceCard> createState() => _ForegroundPresenceCardState();
}

class _ForegroundPresenceCardState extends ConsumerState<ForegroundPresenceCard> {
  ForegroundPresenceStatus status = ForegroundPresenceStatus.inactive;
  bool consent = false;
  bool stopped = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final value = await ref.read(localStorageProvider).getBool('foreground_presence_consent.v1');
      if (mounted && value == true) setState(() => consent = true);
    });
  }

  Future<void> _activate() async {
    if (!consent) {
      final accepted = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Discover people nearby'),
        content: const Text('Mitzone uses your location only while you actively use this feature to help identify people who may have shared the same place and time. It does not track you in the background or share your exact location.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue'))],
      ));
      if (accepted != true || !mounted) return;
      consent = true;
      await ref.read(localStorageProvider).setBool('foreground_presence_consent.v1', true);
    }
    setState(() => status = ForegroundPresenceStatus.locating);
    try {
      if (ref.read(productionModeProvider)) {
        final result = await ref.read(foregroundPresenceServiceProvider)!.record(
          consent: consent,
          permission: ref.read(foregroundPermissionProvider).value ?? LocationPermissionState.notRequested,
        );
        if (mounted) setState(() => status = result);
      } else {
        final evidence = await ref.read(locationObservationSourceProvider).observeForeground();
        if (mounted) setState(() => status = evidence.observedAt.isUtc ? ForegroundPresenceStatus.recorded : ForegroundPresenceStatus.unavailable);
      }
    } catch (_) { if (mounted) setState(() => status = ForegroundPresenceStatus.unavailable); }
  }

  @override Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      Expanded(child: Text(switch (status) {
        ForegroundPresenceStatus.locating => 'Finding your location…',
        ForegroundPresenceStatus.recorded || ForegroundPresenceStatus.active => 'You’re discoverable here for a limited time.',
        ForegroundPresenceStatus.unavailable => 'We couldn’t confirm your location.',
        _ => 'Discover people you may have shared a place and time with.',
      })),
      const SizedBox(width: 12),
      if (status == ForegroundPresenceStatus.recorded || status == ForegroundPresenceStatus.active)
        TextButton(onPressed: () async {
          if (ref.read(productionModeProvider)) {
            await ref.read(presenceRepositoryProvider).stopForegroundPresence();
          }
          if (mounted) setState(() { stopped = true; status = ForegroundPresenceStatus.inactive; });
        }, child: const Text('Stop'))
      else if (!stopped) FilledButton(onPressed: status == ForegroundPresenceStatus.locating ? null : _activate, child: const Text('I’m here')),
    ]),
  ));
}
