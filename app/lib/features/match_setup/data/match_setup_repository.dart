import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';

abstract class MatchSetupRepository {
  Future<List<MatchPlayer>> fetchRoster({required String teamId});

  Future<MatchDraft?> loadDraft({required String matchId});

  Future<void> saveDraft({
    required String teamId,
    required String matchId,
    required MatchDraft draft,
  });

  // Roster Template methods
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId});

  Future<void> saveRosterTemplate({
    required String teamId,
    required RosterTemplate template,
  });

  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  });

  Future<void> updateTemplateUsage({
    required String teamId,
    required String templateId,
  });
}

