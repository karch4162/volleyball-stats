import '../models/match_draft.dart';
import '../models/match_player.dart';

abstract class MatchSetupRepository {
  Future<List<MatchPlayer>> fetchRoster({required String teamId});

  Future<MatchDraft?> loadDraft({required String matchId});

  Future<void> saveDraft({
    required String matchId,
    required MatchDraft draft,
  });
}

