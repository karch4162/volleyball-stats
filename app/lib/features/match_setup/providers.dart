import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/cache/cache_sync_service.dart';
import '../../core/cache/offline_cache_service.dart';
import '../../core/providers/supabase_client_provider.dart';
import '../auth/auth_provider.dart';
import '../teams/team_providers.dart';
import 'data/data.dart';
import 'data/read_only_cached_repository.dart';
import 'models/match_draft.dart';
import 'models/match_player.dart';
import 'models/roster_template.dart';
import 'constants.dart';

final matchDraftCacheProvider = Provider<MatchDraftCache>((ref) {
  return InMemoryMatchDraftCache();
});

final offlineCacheServiceProvider = FutureProvider<OfflineCacheService>((ref) async {
  // This will be initialized in main.dart and provided via override
  throw UnimplementedError('OfflineCacheService must be provided via override');
});

/// Provider that syncs cache when user is authenticated and connected
final cacheSyncProvider = FutureProvider<void>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  // Only sync if connected and authenticated
  if (client == null || userId == null) {
    return;
  }

  // Wait for offline cache service to be available
  final offlineCacheAsync = ref.watch(offlineCacheServiceProvider);
  final offlineCache = offlineCacheAsync.valueOrNull;
  
  // Only sync if cache service is available
  if (offlineCache == null) {
    return;
  }
  
  final syncService = CacheSyncService(cache: offlineCache, client: client);

  // Sync cache in background (don't block UI)
  try {
    await syncService.syncCache(userId: userId);
  } catch (e) {
    if (kDebugMode) {
      print('CacheSyncProvider: Error syncing cache: $e');
    }
    // Don't throw - cache sync failure shouldn't block app
  }
});

final matchSetupRepositoryProvider = Provider<MatchSetupRepository>((ref) {
  final cache = ref.watch(matchDraftCacheProvider);
  final client = ref.watch(supabaseClientProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final offlineCacheAsync = ref.watch(offlineCacheServiceProvider);
  
  if (kDebugMode) {
    print('=== Creating Match Setup Repository ===');
    print('  Supabase client: ${client != null ? "CONNECTED" : "NOT CONNECTED"}');
    print('  Authenticated: $isAuthenticated');
  }
  
  // Use selected team ID or fallback to default (for backwards compatibility during migration)
  final selectedTeamId = ref.watch(selectedTeamIdProvider);
  final effectiveTeamId = selectedTeamId ?? defaultTeamId;

  // If connected and authenticated, use Supabase repository with caching
  if (client != null && isAuthenticated) {
    if (kDebugMode) {
      print('  ✓ Using SupabaseMatchSetupRepository (authenticated, can create entities)');
    }
    
    final baseRepository = SupabaseMatchSetupRepository(client);
    return CachedMatchSetupRepository(
      primary: baseRepository,
      cache: cache,
      teamId: effectiveTeamId,
    );
  }
  
  // If offline, try to use read-only cached repository if cache is available
  final offlineCacheValue = offlineCacheAsync.valueOrNull;
  if (offlineCacheValue != null && offlineCacheValue.isCacheValid) {
    if (kDebugMode) {
      print('  📱 Using ReadOnlyCachedRepository (offline, viewing cached data)');
    }
    
    return ReadOnlyCachedRepository(
      cache: offlineCacheValue,
      draftCache: cache,
      teamId: effectiveTeamId,
    );
  }
  
  // Fallback to in-memory repository (empty, read-only)
  if (kDebugMode) {
    print('  ⚠️  Using InMemoryMatchSetupRepository (read-only, no cached data)');
    print('  ⚠️  Entity creation blocked - requires Supabase connection + authentication');
  }
  
  final baseRepository = InMemoryMatchSetupRepository();
  return CachedMatchSetupRepository(
    primary: baseRepository,
    cache: cache,
    teamId: effectiveTeamId,
  );
});

// Roster Template Providers
final rosterTemplatesProvider = FutureProvider.family<List<RosterTemplate>, String>((ref, teamId) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return await repository.loadRosterTemplates(teamId: teamId);
});

final rosterTemplatesDefaultProvider = FutureProvider<List<RosterTemplate>>((ref) {
  final repository = ref.watch(matchSetupRepositoryProvider);
  final selectedTeamId = ref.watch(selectedTeamIdProvider);
  final effectiveTeamId = selectedTeamId ?? defaultTeamId;
  return repository.loadRosterTemplates(teamId: effectiveTeamId);
});

// Template actions provider (for mutations)
final templateActionsProvider = Provider<TemplateActions>((ref) {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return TemplateActions(repository: repository, ref: ref);
});

class TemplateActions {
  TemplateActions({required this.repository, required this.ref});

  final MatchSetupRepository repository;
  final Ref ref;

  Future<void> saveTemplate({
    required String teamId,
    required String name,
    String? description,
    required Set<String> playerIds,
    Map<int, String>? defaultRotation,
  }) async {
    final template = RosterTemplate(
      id: const Uuid().v4(),
      name: name,
      description: description,
      playerIds: playerIds,
      defaultRotation: defaultRotation ?? const {},
      createdAt: DateTime.now(),
    );

    await repository.saveRosterTemplate(teamId: teamId, template: template);
    ref.invalidate(rosterTemplatesDefaultProvider);
  }

  Future<void> deleteTemplate({
    required String teamId,
    required String templateId,
  }) async {
    await repository.deleteRosterTemplate(teamId: teamId, templateId: templateId);
    ref.invalidate(rosterTemplatesDefaultProvider);
  }

  Future<void> useTemplate({
    required String teamId,
    required String templateId,
  }) async {
    await repository.updateTemplateUsage(teamId: teamId, templateId: templateId);
    ref.invalidate(rosterTemplatesDefaultProvider);
  }
}

final matchSetupRosterProvider =
    FutureProvider.autoDispose<List<MatchPlayer>>((ref) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  final selectedTeamId = ref.watch(selectedTeamIdProvider);
  final effectiveTeamId = selectedTeamId ?? defaultTeamId;
  return repository.fetchRoster(teamId: effectiveTeamId);
});

// Provider for last match draft
final lastMatchDraftProvider = FutureProvider<MatchDraft?>((ref) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  // For now, try loading the default draft ID
  // In a real implementation, you'd query for the most recent draft
  try {
    return await repository.loadDraft(matchId: defaultMatchDraftId);
  } catch (_) {
    return null;
  }
});

