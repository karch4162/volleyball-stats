import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global logger instance for the application
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    // Timestamp is useful for debugging
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: kDebugMode ? Level.debug : Level.warning,
);

/// Create a feature-specific logger
Logger createLogger(String featureName) {
  return Logger(
    printer: PrefixPrinter(
      PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      debug: '[$featureName]',
      trace: '[$featureName]',
      info: '[$featureName]',
      warning: '[$featureName]',
      error: '[$featureName]',
      fatal: '[$featureName]',
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );
}
