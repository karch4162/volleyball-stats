import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_provider.dart';
import '../providers/supabase_client_provider.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

/// Widget that guards routes requiring Supabase connection and authentication
/// Shows error message if not connected/authenticated, otherwise shows child
class ConnectionGuard extends ConsumerWidget {
  const ConnectionGuard({
    super.key,
    required this.child,
    this.requireAuth = true,
    this.requireConnection = true,
    this.errorWidget,
  });

  final Widget child;
  final bool requireAuth;
  final bool requireConnection;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseConnected = ref.watch(supabaseClientProvider) != null;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Check connection requirement
    if (requireConnection && !supabaseConnected) {
      return errorWidget ??
          Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Supabase Not Connected',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This feature requires a Supabase connection.\n\n'
                            'Please configure SUPABASE_API_URL and SUPABASE_ANON_KEY environment variables.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
    }

    // Check authentication requirement
    if (requireAuth && !isAuthenticated) {
      return errorWidget ??
          Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outlined,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Authentication Required',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please sign in to access this feature.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
    }

    // All requirements met, show child
    return child;
  }
}

