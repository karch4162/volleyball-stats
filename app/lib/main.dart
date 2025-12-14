import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/cache/offline_cache_service.dart';
import 'core/persistence/hive_service.dart';
import 'core/supabase.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_guard.dart';
import 'features/match_setup/data/match_draft_cache.dart';
import 'features/match_setup/home_screen.dart';
import 'features/match_setup/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for offline persistence (CRITICAL: do this first)
  try {
    if (kDebugMode) {
      debugPrint('[Main] Initializing Hive for offline persistence...');
    }
    await HiveService.initialize();
    if (kDebugMode) {
      debugPrint('[Main] ✓ Hive initialized successfully');
      final stats = HiveService.getStorageStats();
      debugPrint('[Main] Storage stats: $stats');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('[Main] ✗ FATAL: Failed to initialize Hive: $e');
      debugPrint('[Main] Stack trace: $stackTrace');
    }
    // Hive failure is critical for offline-first architecture
    throw Exception('Failed to initialize offline storage: $e');
  }
  
  // Load .env file if it exists
  // flutter_dotenv looks for files relative to the app root (app/ directory)
  try {
    // Try loading from app root first
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      debugPrint('[Main] ✓ Loaded .env file successfully');
      final url = dotenv.env['SUPABASE_API_URL']?.trim();
      final key = dotenv.env['SUPABASE_ANON_KEY']?.trim();
      debugPrint('[Main] SUPABASE_API_URL from .env: ${url != null && url.isNotEmpty ? "✓ (${url.length} chars)" : "✗ (missing or empty)"}');
      debugPrint('[Main] SUPABASE_ANON_KEY from .env: ${key != null && key.isNotEmpty ? "✓ (${key.length} chars)" : "✗ (missing or empty)"}');
      if (url != null && url.isNotEmpty) {
        debugPrint('[Main] URL preview: ${url.substring(0, url.length > 50 ? 50 : url.length)}');
        // Check for common issues
        if (url.contains('postgresql://') || url.contains('postgres://')) {
          debugPrint('[Main] ⚠️  WARNING: URL appears to be a database connection string, not HTTP API URL!');
        }
        if (url.endsWith('--') || url.contains('--')) {
          debugPrint('[Main] ⚠️  WARNING: URL may have trailing characters!');
        }
      }
      if (key != null && key.isNotEmpty) {
        debugPrint('[Main] Key preview: ${key.substring(0, key.length > 30 ? 30 : key.length)}...');
      }
    }
  } catch (e) {
    // .env file not found or couldn't be loaded - that's okay, will use --dart-define or defaults
    if (kDebugMode) {
      debugPrint('[Main] ✗ Could not load .env file: $e');
      debugPrint('[Main] Error type: ${e.runtimeType}');
      debugPrint('[Main] Will try --dart-define flags or fall back to in-memory repository');
    }
  }
  
  // Initialize Supabase (may fail if credentials not provided - that's okay)
  try {
    await initializeSupabase();
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('[Main] Error initializing Supabase: $e');
      debugPrint('[Main] Stack trace: $stackTrace');
    }
    // Continue anyway - app will work with in-memory repository
  }
  
    // Initialize cache services
  try {
    if (kDebugMode) {
      debugPrint('[Main] Initializing cache services...');
    }
    final matchDraftCache = await createHiveMatchDraftCache();
    if (kDebugMode) {
      debugPrint('[Main] Match draft cache initialized');
    }
    final offlineCacheService = await createOfflineCacheService();
    if (kDebugMode) {
      debugPrint('[Main] Offline cache service initialized');
    }
    
    // Clear expired cache on app start
    await offlineCacheService.clearExpiredCache();
    if (kDebugMode) {
      debugPrint('[Main] Expired cache cleared');
    }
    
    if (kDebugMode) {
      debugPrint('[Main] Starting app...');
    }
    runApp(
      ProviderScope(
        overrides: [
          matchDraftCacheProvider.overrideWithValue(matchDraftCache),
          offlineCacheServiceProvider.overrideWith((ref) async => offlineCacheService),
        ],
        child: const VolleyballStatsApp(),
      ),
    );
    if (kDebugMode) {
      debugPrint('[Main] App started successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('[Main] Fatal error during initialization: $e');
      debugPrint('[Main] Stack trace: $stackTrace');
    }
    // Show error screen
    runApp(
      MaterialApp(
        title: 'Volleyball Stats',
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Text(
                      stackTrace.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VolleyballStatsApp extends StatelessWidget {
  const VolleyballStatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up error widget builder to catch unhandled exceptions
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        debugPrint('=== Unhandled Flutter Error ===');
        debugPrint('Error: ${details.exception}');
        debugPrint('Stack: ${details.stack}');
      }
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'App Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exception.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      Text(
                        details.stack.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    };

    return MaterialApp(
      title: 'Volleyball Stats',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGuard(
        child: HomeScreen(),
      ),
    );
  }
}
