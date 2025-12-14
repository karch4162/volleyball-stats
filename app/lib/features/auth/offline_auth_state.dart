import 'package:hive/hive.dart';
import '../../core/persistence/hive_service.dart';
import '../../core/utils/logger.dart';

final _logger = createLogger('OfflineAuthState');

/// Represents offline authentication state
class OfflineAuthState {
  const OfflineAuthState({
    required this.isOfflineMode,
    this.cachedUserId,
    this.cachedUserEmail,
    this.lastSignedInAt,
  });

  final bool isOfflineMode;
  final String? cachedUserId;
  final String? cachedUserEmail;
  final DateTime? lastSignedInAt;

  factory OfflineAuthState.anonymous() {
    return const OfflineAuthState(
      isOfflineMode: true,
      cachedUserId: 'offline_user',
      cachedUserEmail: 'offline@local',
    );
  }

  factory OfflineAuthState.fromMap(Map<String, dynamic> map) {
    return OfflineAuthState(
      isOfflineMode: map['is_offline_mode'] as bool? ?? false,
      cachedUserId: map['cached_user_id'] as String?,
      cachedUserEmail: map['cached_user_email'] as String?,
      lastSignedInAt: map['last_signed_in_at'] != null
          ? DateTime.parse(map['last_signed_in_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_offline_mode': isOfflineMode,
      if (cachedUserId != null) 'cached_user_id': cachedUserId,
      if (cachedUserEmail != null) 'cached_user_email': cachedUserEmail,
      if (lastSignedInAt != null)
        'last_signed_in_at': lastSignedInAt!.toIso8601String(),
    };
  }

  OfflineAuthState copyWith({
    bool? isOfflineMode,
    String? cachedUserId,
    String? cachedUserEmail,
    DateTime? lastSignedInAt,
  }) {
    return OfflineAuthState(
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      cachedUserId: cachedUserId ?? this.cachedUserId,
      cachedUserEmail: cachedUserEmail ?? this.cachedUserEmail,
      lastSignedInAt: lastSignedInAt ?? this.lastSignedInAt,
    );
  }

  bool get hasCache => cachedUserId != null && cachedUserEmail != null;
}

/// Service for managing offline auth state
class OfflineAuthService {
  static const String _authStateKey = 'offline_auth_state';

  /// Save offline auth state to Hive
  Future<void> saveOfflineState(OfflineAuthState state) async {
    try {
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      await box.put(_authStateKey, state.toMap());
      _logger.i('Saved offline auth state');
    } catch (e, st) {
      _logger.e('Failed to save offline auth state', error: e, stackTrace: st);
    }
  }

  /// Load offline auth state from Hive
  Future<OfflineAuthState?> loadOfflineState() async {
    try {
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      final stateMap = box.get(_authStateKey);
      
      if (stateMap != null) {
        final state = OfflineAuthState.fromMap(
          Map<String, dynamic>.from(stateMap),
        );
        _logger.i('Loaded offline auth state: ${state.cachedUserEmail}');
        return state;
      }
    } catch (e) {
      _logger.w('Failed to load offline auth state', error: e);
    }
    return null;
  }

  /// Cache current user session for offline access
  Future<void> cacheUserSession({
    required String userId,
    required String userEmail,
  }) async {
    final state = OfflineAuthState(
      isOfflineMode: false,
      cachedUserId: userId,
      cachedUserEmail: userEmail,
      lastSignedInAt: DateTime.now(),
    );
    await saveOfflineState(state);
    _logger.i('Cached user session: $userEmail');
  }

  /// Enable offline mode (skip authentication)
  Future<void> enableOfflineMode() async {
    final state = OfflineAuthState.anonymous();
    await saveOfflineState(state);
    _logger.i('Enabled offline mode');
  }

  /// Clear offline auth state
  Future<void> clearOfflineState() async {
    try {
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      await box.delete(_authStateKey);
      _logger.i('Cleared offline auth state');
    } catch (e) {
      _logger.w('Failed to clear offline auth state', error: e);
    }
  }
}
