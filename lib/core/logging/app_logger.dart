/// Interface for the application logger.
///
/// Permits dependency injection of different logging strategies (e.g. console logging,
/// file logging, or mock logging for unit tests).
abstract class AppLogger {
  /// Log a message at the debug level.
  void debug(String message, {dynamic error, StackTrace? stackTrace});

  /// Log a message at the informational level.
  void info(String message, {dynamic error, StackTrace? stackTrace});

  /// Log a message at the warning level.
  void warning(String message, {dynamic error, StackTrace? stackTrace});

  /// Log a message at the error level.
  void error(String message, {dynamic error, StackTrace? stackTrace});
}
