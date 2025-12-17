import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'offline_auth_state.dart';

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

    // If Supabase is not connected, offer offline mode
    if (!supabaseConnected) {
      if (kDebugMode) {
        debugPrint('[AuthGuard] Supabase not connected, showing offline options');
      }
      return _OfflineOptionsScreen(child: child);
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

/// Screen shown when Supabase is not connected, offering offline mode
class _OfflineOptionsScreen extends StatefulWidget {
  const _OfflineOptionsScreen({required this.child});

  final Widget child;

  @override
  State<_OfflineOptionsScreen> createState() => _OfflineOptionsScreenState();
}

class _OfflineOptionsScreenState extends State<_OfflineOptionsScreen> {
  bool _isLoadingOffline = false;
  final _offlineAuthService = OfflineAuthService();

  Future<void> _continueOffline() async {
    setState(() => _isLoadingOffline = true);
    
    try {
      await _offlineAuthService.enableOfflineMode();
      
      if (mounted) {
        // Navigate to protected content in offline mode
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enable offline mode: $e'),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingOffline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No internet connection detected. You can still use the app offline with limited features.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Offline:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        Icons.sports_volleyball,
                        'Record match stats',
                        true,
                      ),
                      _buildFeatureItem(
                        Icons.save_outlined,
                        'Local data storage',
                        true,
                      ),
                      _buildFeatureItem(
                        Icons.sync_outlined,
                        'Auto-sync when online',
                        true,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Not Available Offline:',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        Icons.cloud_upload_outlined,
                        'Cloud backup',
                        false,
                      ),
                      _buildFeatureItem(
                        Icons.people_outline,
                        'Team sharing',
                        false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoadingOffline ? null : _continueOffline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.glass,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingOffline
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue Offline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your data will be synced automatically when you reconnect.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
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

  Widget _buildFeatureItem(IconData icon, String text, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 20,
            color: available ? AppColors.emerald : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: available ? AppColors.textSecondary : AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

