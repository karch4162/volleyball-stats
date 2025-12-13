import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../../core/theme/app_colors.dart';
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
    final supabaseClient = ref.watch(supabaseClientProvider);
    final supabaseConnected = supabaseClient != null;
    
    if (kDebugMode) {
      debugPrint('[AuthGuard] Supabase connected: $supabaseConnected');
      debugPrint('[AuthGuard] Auth state loading: ${authState.isLoading}');
      debugPrint('[AuthGuard] Auth state has value: ${authState.hasValue}');
      debugPrint('[AuthGuard] Auth state has error: ${authState.hasError}');
      if (authState.hasError) {
        debugPrint('[AuthGuard] Auth error: ${authState.error}');
      }
    }

    // If Supabase is not connected, show connection error
    if (!supabaseConnected) {
      if (kDebugMode) {
        debugPrint('[AuthGuard] Showing Supabase Not Connected screen');
      }
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Supabase Not Connected',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please configure SUPABASE_API_URL and SUPABASE_ANON_KEY in your .env file.\n\n'
                    'Create a .env file in the app/ directory with:\n'
                    'SUPABASE_API_URL=https://your-project.supabase.co\n'
                    'SUPABASE_ANON_KEY=your-anon-key\n\n'
                    'Get your credentials from: Supabase Dashboard → Settings → API',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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

