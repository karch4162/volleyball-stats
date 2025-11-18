import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/cache/offline_cache_service.dart';
import 'core/supabase.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_guard.dart';
import 'features/match_setup/data/match_draft_cache.dart';
import 'features/match_setup/home_screen.dart';
import 'features/match_setup/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  final matchDraftCache = await createHiveMatchDraftCache();
  final offlineCacheService = await createOfflineCacheService();
  
  // Clear expired cache on app start
  await offlineCacheService.clearExpiredCache();
  
  runApp(
    ProviderScope(
      overrides: [
        matchDraftCacheProvider.overrideWithValue(matchDraftCache),
        offlineCacheServiceProvider.overrideWith((ref) async => offlineCacheService),
      ],
      child: const VolleyballStatsApp(),
    ),
  );
}

class VolleyballStatsApp extends StatelessWidget {
  const VolleyballStatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volleyball Stats',
      theme: AppTheme.darkTheme,
      home: const AuthGuard(
        child: HomeScreen(),
      ),
    );
  }
}
