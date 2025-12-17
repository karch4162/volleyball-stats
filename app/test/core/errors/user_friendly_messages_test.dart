import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:volleyball_stats_app/core/errors/repository_errors.dart';
import 'package:volleyball_stats_app/core/errors/user_friendly_messages.dart';

void main() {
  group('UserFriendlyMessages', () {
    group('Custom exceptions', () {
      test('converts SupabaseNotConnectedException correctly', () {
        final message = UserFriendlyMessages.fromError(
          const SupabaseNotConnectedException(),
        );
        expect(message, contains('connect to the server'));
        expect(message, contains('internet connection'));
      });

      test('converts NotAuthenticatedException correctly', () {
        final message = UserFriendlyMessages.fromError(
          const NotAuthenticatedException(),
        );
        expect(message, contains('signed in'));
      });

      test('converts OfflineEntityCreationException correctly', () {
        final message = UserFriendlyMessages.fromError(
          const OfflineEntityCreationException('team'),
        );
        expect(message, contains('Cannot create team'));
        expect(message, contains('offline'));
      });
    });

    group('Postgrest errors', () {
      test('converts permission errors correctly', () {
        final error = PostgrestException(
          message: 'permission denied for table players',
          code: '42501',
        );
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('permission'));
      });

      test('converts foreign key errors correctly', () {
        final error = PostgrestException(
          message: 'foreign key constraint violation',
          code: '23503',
        );
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('existing relationships'));
      });

      test('converts unique constraint errors correctly', () {
        final error = PostgrestException(
          message: 'unique constraint violation',
          code: '23505',
        );
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('already exists'));
      });

      test('converts not null errors correctly', () {
        final error = PostgrestException(
          message: 'null value in column violates not-null constraint',
          code: '23502',
        );
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('Required information'));
        expect(message, contains('missing'));
      });
    });

    group('Auth errors', () {
      test('converts invalid credentials error', () {
        final error = AuthException('Invalid login credentials');
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('Invalid email or password'));
      });

      test('converts email already registered error', () {
        final error = AuthException('Email already registered');
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('already exists'));
      });

      test('converts weak password error', () {
        final error = AuthException('Weak password');
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('Password is too weak'));
      });

      test('converts rate limit error', () {
        final error = AuthException('Rate limit exceeded');
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('Too many attempts'));
      });
    });

    group('Generic errors', () {
      test('removes Exception prefix', () {
        final error = Exception('Something went wrong');
        final message = UserFriendlyMessages.fromError(error);
        expect(message, equals('Something went wrong'));
      });

      test('removes Error prefix', () {
        final error = 'Error: File not found';
        final message = UserFriendlyMessages.fromError(error);
        expect(message, equals('File not found'));
      });

      test('truncates very long messages', () {
        final longMessage = 'a' * 200;
        final message = UserFriendlyMessages.fromError(longMessage);
        expect(message.length, lessThanOrEqualTo(150));
        expect(message, endsWith('...'));
      });

      test('handles network errors', () {
        final error = 'SocketException: Network unreachable';
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('Network connection error'));
      });

      test('handles timeout errors', () {
        final error = 'TimeoutException: Request timeout';
        final message = UserFriendlyMessages.fromError(error);
        expect(message, contains('timed out'));
      });
    });

    group('forOperation', () {
      test('returns message for create operation', () {
        final message = UserFriendlyMessages.forOperation('create');
        expect(message, contains('Unable to create item'));
      });

      test('returns message for update operation', () {
        final message = UserFriendlyMessages.forOperation('update');
        expect(message, contains('Unable to update item'));
      });

      test('includes error details when provided', () {
        final message = UserFriendlyMessages.forOperation(
          'load',
          const SupabaseNotConnectedException(),
        );
        expect(message, contains('Unable to load data'));
        expect(message, contains('connect to the server'));
      });

      test('handles unknown operations gracefully', () {
        final message = UserFriendlyMessages.forOperation('unknown');
        expect(message, contains('Operation failed'));
      });
    });
  });
}
