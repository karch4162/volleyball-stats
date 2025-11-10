import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

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

class HiveMatchDraftCache implements MatchDraftCache {
  HiveMatchDraftCache(this._box);

  final Box<String> _box;

  @override
  Future<MatchDraft?> load(String matchId) async {
    final jsonString = _box.get(matchId);
    if (jsonString == null) {
      return null;
    }
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return MatchDraft.fromMap(map);
  }

  @override
  Future<void> save(String matchId, MatchDraft draft) async {
    final jsonString = jsonEncode(draft.toMap());
    await _box.put(matchId, jsonString);
  }

  @override
  Future<void> clear(String matchId) async {
    await _box.delete(matchId);
  }
}

const String matchDraftCacheBoxName = 'match_draft_cache';

bool _hiveInitialized = false;

Future<MatchDraftCache> createHiveMatchDraftCache() async {
  if (!_hiveInitialized) {
    await Hive.initFlutter();
    _hiveInitialized = true;
  }
  final box = Hive.isBoxOpen(matchDraftCacheBoxName)
      ? Hive.box<String>(matchDraftCacheBoxName)
      : await Hive.openBox<String>(matchDraftCacheBoxName);
  return HiveMatchDraftCache(box);
}

