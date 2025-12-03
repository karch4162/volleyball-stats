import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Compile-time constants from --dart-define (must be const)
const String _supabaseUrlFromEnv = String.fromEnvironment('SUPABASE_API_URL', defaultValue: '');
const String _supabaseAnonKeyFromEnv = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

// Runtime getters that check --dart-define first, then .env file
String get supabaseUrl {
  // Check compile-time --dart-define first
  if (_supabaseUrlFromEnv.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('[supabaseUrl] Using --dart-define value');
    }
    return _supabaseUrlFromEnv;
  }
  // Fall back to .env file
  try {
    final value = dotenv.env['SUPABASE_API_URL'] ?? '';
    if (kDebugMode && value.isNotEmpty) {
      debugPrint('[supabaseUrl] Using .env value: ${value.substring(0, value.length > 30 ? 30 : value.length)}...');
    }
    // Trim any whitespace that might have been accidentally included
    return value.trim();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[supabaseUrl] dotenv not loaded yet: $e');
    }
    return '';
  }
}

String get supabaseAnonKey {
  // Check compile-time --dart-define first
  if (_supabaseAnonKeyFromEnv.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('[supabaseAnonKey] Using --dart-define value');
    }
    return _supabaseAnonKeyFromEnv;
  }
  // Fall back to .env file
  try {
    final value = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (kDebugMode && value.isNotEmpty) {
      debugPrint('[supabaseAnonKey] Using .env value: ${value.substring(0, value.length > 20 ? 20 : value.length)}...');
    }
    // Trim any whitespace that might have been accidentally included
    return value.trim();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[supabaseAnonKey] dotenv not loaded yet: $e');
    }
    return '';
  }
}

SupabaseClient? _supabaseClient;

Future<SupabaseClient?> initializeSupabase() async {
  if (kDebugMode) {
    print('=== Supabase Initialization ===');
    print('  Checking for credentials...');
    
    // Check --dart-define first (using const values)
    print('  From --dart-define:');
    print('    SUPABASE_API_URL: ${_supabaseUrlFromEnv.isNotEmpty ? "✓ (${_supabaseUrlFromEnv.length} chars)" : "✗ (not provided)"}');
    print('    SUPABASE_ANON_KEY: ${_supabaseAnonKeyFromEnv.isNotEmpty ? "✓ (${_supabaseAnonKeyFromEnv.length} chars)" : "✗ (not provided)"}');
    
    // Check .env file
    try {
      final dotenvUrl = dotenv.env['SUPABASE_API_URL'] ?? '';
      final dotenvKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      print('  From .env file:');
      print('    SUPABASE_API_URL: ${dotenvUrl.isNotEmpty ? "✓ (${dotenvUrl.length} chars)" : "✗ (missing or empty)"}');
      print('    SUPABASE_ANON_KEY: ${dotenvKey.isNotEmpty ? "✓ (${dotenvKey.length} chars)" : "✗ (missing or empty)"}');
    } catch (e) {
      print('  From .env file: ✗ (dotenv not loaded: $e)');
    }
    
    // Final values (from getters)
    print('  Final values:');
    print('    SUPABASE_API_URL: ${supabaseUrl.isNotEmpty ? "✓ (${supabaseUrl.length} chars)" : "✗ (empty)"}');
    print('    SUPABASE_ANON_KEY: ${supabaseAnonKey.isNotEmpty ? "✓ (${supabaseAnonKey.length} chars)" : "✗ (empty)"}');
    if (supabaseUrl.isNotEmpty) {
      print('    URL preview: ${supabaseUrl.substring(0, supabaseUrl.length > 50 ? 50 : supabaseUrl.length)}...');
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

