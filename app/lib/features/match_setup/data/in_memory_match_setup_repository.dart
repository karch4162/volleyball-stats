import 'dart:async';

import '../../../core/errors/repository_errors.dart';
import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import 'match_setup_repository.dart';

/// Read-only in-memory repository that returns empty data
/// Used when Supabase is not connected - prevents hardcoded data from being used
class InMemoryMatchSetupRepository implements MatchSetupRepository {
  InMemoryMatchSetupRepository({
    Map<String, MatchDraft>? seedDrafts,
    Map<String, RosterTemplate>? seedTemplates,
    Map<String, List<MatchPlayer>>? seedRoster,
  })  : _drafts = seedDrafts ?? <String, MatchDraft>{},
        _templates = seedTemplates ?? <String, RosterTemplate>{},
        _roster = seedRoster ?? <String, List<MatchPlayer>>{};

  final Map<String, MatchDraft> _drafts;
  final Map<String, RosterTemplate> _templates;
  final Map<String, List<MatchPlayer>> _roster;

  @override
  bool get supportsEntityCreation => false; // Never allow creation offline

  @override
  bool get isConnected => false; // Not connected to Supabase

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    // Return seeded roster if available, otherwise empty list
    // This allows tests to seed data while preventing hardcoded production data
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _roster[teamId] ?? [];
  }

  @override
  Future<MatchDraft?> loadDraft({required String matchId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _drafts[matchId];
  }

  @override
  Future<void> saveDraft({
    required String teamId,
    required String matchId,
    required MatchDraft draft,
  }) async {
    // Allow draft saving to in-memory cache for offline editing
    // But note: drafts won't sync to Supabase until connected
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _drafts[matchId] = draft;
  }

  @override
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // Sort by useCount descending, then lastUsedAt descending, then name
    final templates = _templates.values.toList()
      ..sort((a, b) {
        if (a.useCount != b.useCount) {
          return b.useCount.compareTo(a.useCount);
        }
        if (a.lastUsedAt != null && b.lastUsedAt != null) {
          return b.lastUsedAt!.compareTo(a.lastUsedAt!);
        }
        if (a.lastUsedAt != null) return -1;
        if (b.lastUsedAt != null) return 1;
        return a.name.compareTo(b.name);
      });
    return templates;
  }

  @override
  Future<void> saveRosterTemplate({
    required String teamId,
    required RosterTemplate template,
  }) async {
    // Block entity creation when offline
    throw const OfflineEntityCreationException('roster template');
  }

  @override
  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  }) async {
    // Block deletion when offline
    throw const OfflineEntityCreationException('roster template deletion');
  }

  @override
  Future<void> updateTemplateUsage({
    required String teamId,
    required String templateId,
  }) async {
    // Block updates when offline (templates are Supabase-only)
    throw const OfflineEntityCreationException('roster template update');
  }

  @override
  Future<List<dynamic>> fetchMatchSummaries({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? opponent,
    String? seasonLabel,
  }) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchMatchDetails({
    required String matchId,
  }) async {
    return null;
  }

  @override
  Future<Map<String, dynamic>> fetchSeasonStats({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? opponentIds,
    String? seasonLabel,
  }) async {
    return {};
  }
}

