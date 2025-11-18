import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

/// Widget that protects routes by requiring authentication
/// Shows login screen if not authenticated, otherwise shows child
class AuthGuard extends ConsumerWidget {
  const AuthGuard({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  final Widget child;
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final supabaseConnected = ref.watch(supabaseClientProvider) != null;

    // If Supabase is not connected, show connection error
    if (!supabaseConnected) {
      return Scaffold(
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
                        'Please configure SUPABASE_API_URL and SUPABASE_ANON_KEY environment variables.\n\n'
                        'Get your API URL from: Supabase Dashboard → Settings → API → Project URL',
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

    // Show loading state while checking auth
    if (authState.isLoading) {
      return loadingWidget ??
          Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
    }

    // Check if authenticated
    final user = authState.valueOrNull;
    if (user == null) {
      // Not authenticated, show login screen
      return const LoginScreen();
    }

    // Authenticated, show protected content
    return child;
  }
}

