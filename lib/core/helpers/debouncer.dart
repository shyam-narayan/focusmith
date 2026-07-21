import 'dart:async';

/// Delays rapid callbacks — used for editor autosave.
class Debouncer {
  Debouncer({this.duration = const Duration(seconds: 2)});

  final Duration duration;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
