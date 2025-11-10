import '../models/match_draft.dart';

abstract class MatchDraftCache {
  Future<MatchDraft?> load(String matchId);

  Future<void> save(String matchId, MatchDraft draft);

  Future<void> clear(String matchId);
}

class InMemoryMatchDraftCache implements MatchDraftCache {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<MatchDraft?> load(String matchId) async {
    final snapshot = _storage[matchId];
    if (snapshot == null) {
      return null;
    }
    return MatchDraft.fromMap(Map<String, dynamic>.from(snapshot));
  }

  @override
  Future<void> save(String matchId, MatchDraft draft) async {
    _storage[matchId] = Map<String, dynamic>.from(draft.toMap());
  }

  @override
  Future<void> clear(String matchId) async {
    _storage.remove(matchId);
  }
}

