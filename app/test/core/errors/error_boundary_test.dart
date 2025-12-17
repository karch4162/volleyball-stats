import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/core/errors/error_boundary.dart';

void main() {
  group('RetryHelper', () {
    test('succeeds on first attempt', () async {
      int attemptCount = 0;
      
      final result = await RetryHelper.withRetry(
        operation: () async {
          attemptCount++;
          return 'success';
        },
      );

      expect(result, equals('success'));
      expect(attemptCount, equals(1));
    });

    test('retries on failure and eventually succeeds', () async {
      int attemptCount = 0;
      
      final result = await RetryHelper.withRetry(
        operation: () async {
          attemptCount++;
          if (attemptCount < 3) {
            throw Exception('Failed attempt $attemptCount');
          }
          return 'success';
        },
        maxAttempts: 3,
      );

      expect(result, equals('success'));
      expect(attemptCount, equals(3));
    });

    test('throws after max attempts reached', () async {
      int attemptCount = 0;
      
      expect(
        () => RetryHelper.withRetry(
          operation: () async {
            attemptCount++;
            throw Exception('Always fails');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsException,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(attemptCount, equals(3));
    });

    test('calls onRetry callback before each retry', () async {
      final retries = <int>[];
      int attemptCount = 0;
      
      try {
        await RetryHelper.withRetry(
          operation: () async {
            attemptCount++;
            throw Exception('Failed attempt $attemptCount');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
          onRetry: (attempt, error) {
            retries.add(attempt);
          },
        );
      } catch (e) {
        // Expected to fail
      }

      expect(retries, equals([1, 2])); // Called after 1st and 2nd attempts
      expect(attemptCount, equals(3));
    });

    test('uses exponential backoff', () async {
      final delays = <Duration>[];
      DateTime? lastAttemptTime;
      int attemptCount = 0;

      try {
        await RetryHelper.withRetry(
          operation: () async {
            final now = DateTime.now();
            if (lastAttemptTime != null) {
              delays.add(now.difference(lastAttemptTime!));
            }
            lastAttemptTime = now;
            attemptCount++;
            throw Exception('Always fails');
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 100),
        );
      } catch (e) {
        // Expected to fail
      }

      expect(attemptCount, equals(3));
      expect(delays.length, equals(2));
      // Second delay should be approximately double the first
      // (with some tolerance for timing variations)
      if (delays.length == 2) {
        final firstDelay = delays[0].inMilliseconds;
        final secondDelay = delays[1].inMilliseconds;
        expect(secondDelay, greaterThan(firstDelay));
        // Second delay should be roughly 2x first delay
        expect(secondDelay / firstDelay, greaterThan(1.5));
        expect(secondDelay / firstDelay, lessThan(2.5));
      }
    });

    test('respects max delay cap', () async {
      final delays = <Duration>[];
      DateTime? lastAttemptTime;

      try {
        await RetryHelper.withRetry(
          operation: () async {
            final now = DateTime.now();
            if (lastAttemptTime != null) {
              delays.add(now.difference(lastAttemptTime!));
            }
            lastAttemptTime = now;
            throw Exception('Always fails');
          },
          maxAttempts: 5,
          initialDelay: const Duration(milliseconds: 100),
          maxDelay: const Duration(milliseconds: 300),
        );
      } catch (e) {
        // Expected to fail
      }

      // All delays should be capped at maxDelay
      for (final delay in delays) {
        expect(delay.inMilliseconds, lessThan(400)); // Some tolerance
      }
    });

    test('handles different error types', () async {
      // Test with various error types
      final errors = [
        Exception('Standard exception'),
        'String error',
        ArgumentError('Invalid argument'),
        StateError('Bad state'),
      ];

      for (final error in errors) {
        int attemptCount = 0;
        expect(
          () => RetryHelper.withRetry(
            operation: () async {
              attemptCount++;
              throw error;
            },
            maxAttempts: 2,
            initialDelay: const Duration(milliseconds: 10),
          ),
          throwsA(equals(error)),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        expect(attemptCount, equals(2));
      }
    });

    test('works with different return types', () async {
      // Test with int
      final intResult = await RetryHelper.withRetry<int>(
        operation: () async => 42,
      );
      expect(intResult, equals(42));

      // Test with String
      final stringResult = await RetryHelper.withRetry<String>(
        operation: () async => 'test',
      );
      expect(stringResult, equals('test'));

      // Test with List
      final listResult = await RetryHelper.withRetry<List<String>>(
        operation: () async => ['a', 'b', 'c'],
      );
      expect(listResult, equals(['a', 'b', 'c']));

      // Test with null
      final nullResult = await RetryHelper.withRetry<String?>(
        operation: () async => null,
      );
      expect(nullResult, isNull);
    });
  });
}
