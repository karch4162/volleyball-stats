import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_client_provider.dart';

/// Service for authentication operations
class AuthService {
  AuthService(this._client);

  final SupabaseClient? _client;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }
    
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }
    
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }
    
    await _client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }
    
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Get current session
  Session? getCurrentSession() {
    return _client?.auth.currentSession;
  }

  /// Get current user
  User? getCurrentUser() {
    return _client?.auth.currentUser;
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

