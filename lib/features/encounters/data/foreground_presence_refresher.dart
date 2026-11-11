import 'dart:async';

/// Refreshes only a still-authorized, bounded foreground session.
/// The server's original expiry is the deadline; refresh never extends it.
class ForegroundPresenceRefresher {
  ForegroundPresenceRefresher({
    required this.mayObserve,
    required this.refresh,
    DateTime Function()? now,
    this.interval = const Duration(seconds: 60),
  }) : now = now ?? (() => DateTime.now().toUtc());

  final bool Function() mayObserve;
  final Future<void> Function() refresh;
  final DateTime Function() now;
  final Duration interval;
  Timer? _timer;
  bool _inFlight = false;

  void start(DateTime deadline) {
    pause();
    if (!now().isBefore(deadline) || !mayObserve()) return;
    _timer = Timer.periodic(interval, (_) async {
      if (!now().isBefore(deadline) || !mayObserve()) {
        pause();
        return;
      }
      if (_inFlight) return;
      _inFlight = true;
      try {
        await refresh();
      } finally {
        _inFlight = false;
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }
}
