import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that provides error handling for async operations and state management.
/// 
/// Wraps a child widget and provides retry functionality when errors occur.
/// Best used with FutureBuilder or StreamBuilder patterns.
/// 
/// Example:
/// ```dart
/// ErrorBoundary(
///   child: FutureBuilder(
///     future: fetchData(),
///     builder: (context, snapshot) {
///       if (snapshot.hasError) {
///         return ErrorBoundary.errorWidget(
///           context,
///           snapshot.error!,
///           onRetry: () => setState(() {}),
///         );
///       }
///       return MyWidget(snapshot.data);
///     },
///   ),
/// )
/// ```
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  /// The widget to display
  final Widget child;

  /// Called when an error occurs (for logging)
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Creates a standardized error widget with retry functionality
  static Widget errorWidget(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              customMessage ?? _sanitizeErrorMessage(error),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sanitizes error messages to be user-friendly
  static String _sanitizeErrorMessage(Object error) {
    final errorString = error.toString();
    
    // Remove common technical prefixes
    String message = errorString
        .replaceFirst('Exception: ', '')
        .replaceFirst('Error: ', '')
        .replaceFirst('FormatException: ', '');
    
    // Truncate very long messages
    if (message.length > 150) {
      message = '${message.substring(0, 147)}...';
    }
    
    return message;
  }
}

/// Retry helper with exponential backoff
class RetryHelper {
  /// Executes an async operation with exponential backoff retry logic
  /// 
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry (default: 1 second)
  /// [maxDelay] - Maximum delay between retries (default: 10 seconds)
  /// [onRetry] - Optional callback called before each retry
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    void Function(int attempt, Object error)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (error, stackTrace) {
        if (attempt >= maxAttempts) {
          // Max attempts reached, rethrow the error
          if (kDebugMode) {
            debugPrint('Max retry attempts ($maxAttempts) reached');
            debugPrint('Error: $error');
            debugPrint('Stack: $stackTrace');
          }
          rethrow;
        }

        // Call retry callback
        onRetry?.call(attempt, error);

        if (kDebugMode) {
          debugPrint('Retry attempt $attempt/$maxAttempts after ${delay.inSeconds}s');
        }

        // Wait before retrying
        await Future.delayed(delay);

        // Exponential backoff: double the delay, but cap at maxDelay
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }
}
