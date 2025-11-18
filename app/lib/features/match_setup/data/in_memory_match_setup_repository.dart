import 'dart:async';

import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import 'match_setup_repository.dart';

class InMemoryMatchSetupRepository implements MatchSetupRepository {
  InMemoryMatchSetupRepository({
    List<MatchPlayer>? seedRoster,
    Map<String, MatchDraft>? seedDrafts,
    Map<String, RosterTemplate>? seedTemplates,
  })  : _roster = seedRoster ?? _defaultRoster,
        _drafts = seedDrafts ?? <String, MatchDraft>{},
        _templates = seedTemplates ?? <String, RosterTemplate>{};

  final List<MatchPlayer> _roster;
  final Map<String, MatchDraft> _drafts;
  final Map<String, RosterTemplate> _templates;

  static final List<MatchPlayer> _defaultRoster = [
    const MatchPlayer(
      id: 'player-avery',
      name: 'Avery Harper',
      jerseyNumber: 2,
      position: 'Setter',
    ),
    const MatchPlayer(
      id: 'player-bailey',
      name: 'Bailey Jordan',
      jerseyNumber: 5,
      position: 'Opposite',
    ),
    const MatchPlayer(
      id: 'player-casey',
      name: 'Casey Lane',
      jerseyNumber: 11,
      position: 'Outside Hitter',
    ),
    const MatchPlayer(
      id: 'player-devon',
      name: 'Devon Cruz',
      jerseyNumber: 9,
      position: 'Middle Blocker',
    ),
    const MatchPlayer(
      id: 'player-elliot',
      name: 'Elliot Kim',
      jerseyNumber: 4,
      position: 'Libero',
    ),
    const MatchPlayer(
      id: 'player-finley',
      name: 'Finley Brooks',
      jerseyNumber: 7,
      position: 'Middle Blocker',
    ),
    const MatchPlayer(
      id: 'player-greer',
      name: 'Greer Miles',
      jerseyNumber: 10,
      position: 'Outside Hitter',
    ),
  ];

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _roster;
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
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _templates[template.id] = template;
  }

  @override
  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _templates.remove(templateId);
  }

  @override
  Future<void> updateTemplateUsage({
    required String teamId,
    required String templateId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final template = _templates[templateId];
    if (template != null) {
      _templates[templateId] = template.markUsed();
    }
  }
}

