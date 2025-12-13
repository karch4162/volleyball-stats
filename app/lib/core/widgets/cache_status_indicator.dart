import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/match_setup/providers.dart';

/// Widget that displays cache/offline status indicator
class CacheStatusIndicator extends ConsumerWidget {
  const CacheStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final offlineCacheAsync = ref.watch(offlineCacheServiceProvider);
    
    // If connected and authenticated, don't show indicator
    if (client != null && isAuthenticated) {
      return const SizedBox.shrink();
    }
    
    // Check if we have valid cached data
    final offlineCache = offlineCacheAsync.valueOrNull;
    final hasValidCache = offlineCache != null && offlineCache.isCacheValid;
    
    if (!hasValidCache) {
      // No cache - show offline indicator
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.rose.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.rose.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: AppColors.rose,
            ),
            SizedBox(width: 6),
            Text(
              'Offline',
              style: TextStyle(
                color: AppColors.rose,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    // Has cache - show cached data indicator
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.indigoDark.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.indigo.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_download_rounded,
            size: 16,
            color: AppColors.indigo,
          ),
          SizedBox(width: 6),
          Text(
            'Viewing cached data',
            style: TextStyle(
              color: AppColors.indigo,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

