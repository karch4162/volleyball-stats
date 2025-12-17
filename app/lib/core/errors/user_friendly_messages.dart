import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_errors.dart';

/// Converts technical errors into user-friendly messages
class UserFriendlyMessages {
  /// Converts an error object into a user-friendly message
  static String fromError(Object error) {
    // Handle known custom exceptions first
    if (error is SupabaseNotConnectedException) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    
    if (error is NotAuthenticatedException) {
      return 'You need to be signed in to perform this action.';
    }
    
    if (error is OfflineEntityCreationException) {
      return 'Cannot create ${error.entityType} while offline. Please connect to the internet.';
    }

    // Handle Supabase errors
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }
    
    if (error is AuthException) {
      return _handleAuthError(error);
    }
    
    if (error is StorageException) {
      return 'Storage error: ${error.message}';
    }

    // Handle common Flutter/Dart errors
    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    }
    
    if (error is TypeError) {
      return 'Data type mismatch. Please try again or contact support.';
    }

    // Network-related errors
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') || 
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network connection error. Please check your internet and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('certificate') || errorString.contains('ssl')) {
      return 'Security certificate error. Please check your connection.';
    }

    // Default: sanitize the error message
    return _sanitizeGenericError(error);
  }

  /// Handles Postgrest (database) errors
  static String _handlePostgrestError(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    // Row level security errors
    if (code == '42501' || message.contains('permission') || message.contains('rls')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Foreign key violations
    if (code == '23503' || message.contains('foreign key')) {
      return 'Cannot complete operation due to existing relationships.';
    }

    // Unique constraint violations
    if (code == '23505' || message.contains('unique constraint') || message.contains('duplicate')) {
      return 'This item already exists. Please use a different value.';
    }

    // Not null violations
    if (code == '23502' || message.contains('not null')) {
      return 'Required information is missing. Please fill in all required fields.';
    }

    // Check constraint violations
    if (code == '23514' || message.contains('check constraint')) {
      return 'Invalid data. Please check your input values.';
    }

    // Connection errors
    if (message.contains('connection') || message.contains('timeout')) {
      return 'Database connection error. Please try again.';
    }

    // Default database error
    return 'Database error: ${error.message}';
  }

  /// Handles Supabase Auth errors
  static String _handleAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') || 
        message.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.contains('email already registered') ||
        message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }

    if (message.contains('weak password') || message.contains('password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }

    if (message.contains('session')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (message.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }

    // Default auth error
    return 'Authentication error: ${error.message}';
  }

  /// Sanitizes generic error messages
  static String _sanitizeGenericError(Object error) {
    String message = error.toString();

    // Remove common technical prefixes
    message = message
        .replaceFirst('Exception: ', '')
        .replaceFirst('Error: ', '')
        .replaceFirst('FormatException: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('ArgumentError: ', '');

    // Remove stack trace indicators
    if (message.contains('\n')) {
      message = message.split('\n').first;
    }

    // Truncate very long messages
    if (message.length > 150) {
      message = '${message.substring(0, 147)}...';
    }

    // If message is too technical or empty, use generic message
    if (message.isEmpty || 
        message.length < 10 ||
        message.contains('Instance of') ||
        message.contains('<')) {
      return 'An unexpected error occurred. Please try again.';
    }

    return message;
  }

  /// Returns a user-friendly message for common operation types
  static String forOperation(String operation, [Object? error]) {
    final base = {
      'create': 'Unable to create item',
      'update': 'Unable to update item',
      'delete': 'Unable to delete item',
      'load': 'Unable to load data',
      'save': 'Unable to save changes',
      'sync': 'Unable to sync data',
      'export': 'Unable to export data',
      'import': 'Unable to import data',
    }[operation] ?? 'Operation failed';

    if (error != null) {
      return '$base: ${fromError(error)}';
    }

    return '$base. Please try again.';
  }
}
