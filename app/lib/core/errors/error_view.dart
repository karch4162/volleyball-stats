import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'user_friendly_messages.dart';

/// Reusable error view widget that displays errors in a user-friendly way
/// with optional retry functionality.
/// 
/// Example:
/// ```dart
/// if (snapshot.hasError) {
///   return ErrorView(
///     error: snapshot.error!,
///     onRetry: () => ref.refresh(dataProvider),
///   );
/// }
/// ```
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
    this.compact = false,
  });

  /// The error object to display
  final Object error;

  /// Optional retry callback
  final VoidCallback? onRetry;

  /// Optional custom message instead of auto-generated one
  final String? customMessage;

  /// If true, uses a more compact layout
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? UserFriendlyMessages.fromError(error);

    if (compact) {
      return _CompactErrorView(
        message: message,
        onRetry: onRetry,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.rose,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact error view for inline error display
class _CompactErrorView extends StatelessWidget {
  const _CompactErrorView({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.rose.withOpacity(0.1),
        border: Border.all(color: AppColors.rose.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.rose,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              color: AppColors.indigo,
              tooltip: 'Try again',
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading view with error fallback
/// Useful for async data loading scenarios
class LoadingOrErrorView extends StatelessWidget {
  const LoadingOrErrorView({
    super.key,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.loadingMessage,
  });

  final bool isLoading;
  final Object? error;
  final VoidCallback? onRetry;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (loadingMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                loadingMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ],
        ),
      );
    }

    if (error != null) {
      return ErrorView(
        error: error!,
        onRetry: onRetry,
      );
    }

    return const SizedBox.shrink();
  }
}
