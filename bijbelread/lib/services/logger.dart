import 'package:logging/logging.dart';

/// Application logger service for BijbelRead
class AppLogger {
  static Logger? _logger;

  /// Initialize the logger with the specified level
  static void init({Level level = Level.INFO}) {
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      // In a real app, you might want to send logs to a service
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
    _logger = Logger('BijbelRead');
  }

  /// Get the logger instance, initializing if necessary
  static Logger get _loggerInstance {
    if (_logger == null) {
      init(); // Initialize with default settings if not already done
    }
    return _logger!;
  }

  /// Log info messages
  static void info(String message) {
    _loggerInstance.info(message);
  }

  /// Log warning messages
  static void warning(String message) {
    _loggerInstance.warning(message);
  }

  /// Log error messages
  static void error(String message) {
    _loggerInstance.severe(message);
  }

  /// Log debug messages
  static void debug(String message) {
    _loggerInstance.fine(message);
  }
}