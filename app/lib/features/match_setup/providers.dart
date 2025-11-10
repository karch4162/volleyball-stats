import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/supabase_client_provider.dart';
import 'data/data.dart';
import 'models/match_player.dart';
import 'constants.dart';

final matchDraftCacheProvider = Provider<MatchDraftCache>((ref) {
  return InMemoryMatchDraftCache();
});

final matchSetupRepositoryProvider = Provider<MatchSetupRepository>((ref) {
  final cache = ref.watch(matchDraftCacheProvider);
  final client = ref.watch(supabaseClientProvider);
  final baseRepository = client != null
      ? SupabaseMatchSetupRepository(client, teamId: defaultTeamId)
      : InMemoryMatchSetupRepository();

  return CachedMatchSetupRepository(
    primary: baseRepository,
    cache: cache,
    teamId: defaultTeamId,
  );
});

final matchSetupRosterProvider =
    FutureProvider.autoDispose<List<MatchPlayer>>((ref) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return repository.fetchRoster(teamId: defaultTeamId);
});

