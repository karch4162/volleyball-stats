import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

SupabaseClient? _supabaseClient;

Future<SupabaseClient?> initializeSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    return null;
  }

  if (_supabaseClient != null) {
    return _supabaseClient;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  _supabaseClient = Supabase.instance.client;
  return _supabaseClient;
}

SupabaseClient? getSupabaseClientOrNull() {
  return _supabaseClient;
}

/// Singleton access to the Supabase client
class SupabaseSingleton {
  SupabaseSingleton._(); // Private constructor
  
  static SupabaseSingleton? _instance;
  
  /// Get the singleton instance
  static SupabaseSingleton get instance => _instance ??= SupabaseSingleton._();
  
  /// Get the client instance
  SupabaseClient? get client => _supabaseClient;
}

