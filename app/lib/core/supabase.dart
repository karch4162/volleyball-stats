import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = String.fromEnvironment('SUPABASE_API_URL', defaultValue: '');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

SupabaseClient? _supabaseClient;

Future<SupabaseClient?> initializeSupabase() async {
  if (kDebugMode) {
    print('=== Supabase Initialization ===');
    print('  SUPABASE_API_URL provided: ${supabaseUrl.isNotEmpty}');
    print('  SUPABASE_ANON_KEY provided: ${supabaseAnonKey.isNotEmpty}');
    if (supabaseUrl.isNotEmpty) {
      print('  URL: ${supabaseUrl.substring(0, supabaseUrl.length > 50 ? 50 : supabaseUrl.length)}...');
    }
  }

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    if (kDebugMode) {
      print('  ⚠️  Missing environment variables - Supabase not initialized');
    }
    return null;
  }

  // Validate URL format - must be HTTP/HTTPS, not PostgreSQL connection string
  if (supabaseUrl.startsWith('postgresql://') || supabaseUrl.startsWith('postgres://')) {
    if (kDebugMode) {
      print('  ✗ ERROR: Invalid URL format!');
      print('  You provided a PostgreSQL connection string, but Supabase Flutter needs the HTTP API URL.');
      print('  Example: https://your-project-ref.supabase.co');
      print('  Get your API URL from: Supabase Dashboard → Settings → API → Project URL');
    }
    return null;
  }

  if (!supabaseUrl.startsWith('http://') && !supabaseUrl.startsWith('https://')) {
    if (kDebugMode) {
      print('  ✗ ERROR: URL must start with http:// or https://');
      print('  Provided URL: $supabaseUrl');
    }
    return null;
  }

  if (_supabaseClient != null) {
    if (kDebugMode) {
      print('  ✓ Using existing Supabase client');
    }
    return _supabaseClient;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Configure deep linking for email verification and password reset
      // This allows the app to handle verification links from emails
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // Deep link configuration will be handled by the app's deep linking setup
      ),
    );

    _supabaseClient = Supabase.instance.client;
    
    if (kDebugMode) {
      print('  ✓ Supabase initialized successfully');
    }
    
    return _supabaseClient;
  } catch (e) {
    if (kDebugMode) {
      print('  ✗ Error initializing Supabase: $e');
      if (e.toString().contains('postgresql://') || e.toString().contains('credentials')) {
        print('');
        print('  ⚠️  IMPORTANT: You are using a PostgreSQL connection string!');
        print('  Supabase Flutter requires the HTTP API URL, not the database connection string.');
        print('  Get your API URL from: Supabase Dashboard → Settings → API → Project URL');
        print('  It should look like: https://xxxxx.supabase.co');
      }
    }
    return null;
  }
}

SupabaseClient? getSupabaseClientOrNull() {
  // Try to get from instance if cached is null (in case initialization happened elsewhere)
  if (_supabaseClient == null) {
    try {
      _supabaseClient = Supabase.instance.client;
    } catch (e) {
      // Supabase not initialized
      return null;
    }
  }
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

