import 'dart:async';

import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/playback_record.dart';

class HistoryService {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  static String storageKey(String mediaId, [String? episodeId]) {
    final id = mediaId.trim();
    final ep = (episodeId ?? '').trim();
    if (ep.isEmpty) {
      return id;
    }
    return '$id|$ep';
  }

  PlaybackRecord? load(String mediaId, {String? episodeId}) {
    final id = mediaId.trim();
    if (id.isEmpty) {
      return null;
    }
    final ep = (episodeId ?? '').trim();
    if (ep.isNotEmpty) {
      final byEpisode = _read(storageKey(id, ep));
      if (byEpisode != null) {
        return byEpisode;
      }
      final legacy = _read(id);
      if (legacy == null) {
        return null;
      }
      final legacyEpisode = legacy.episodeId.trim();
      if (legacyEpisode.isEmpty || legacyEpisode == ep) {
        return legacy;
      }
      return null;
    }
    return _read(id) ?? _newestFor(id);
  }

  Future<void> save(PlaybackRecord record) async {
    final key = storageKey(record.videoId, record.episodeId);
    if (key.isEmpty) {
      return;
    }
    try {
      await LocalStorage.playbackHistoryBox().put(key, record.toJson());
      final mediaId = record.videoId.trim();
      if (record.episodeId.trim().isNotEmpty && key != mediaId) {
        final legacy = _read(mediaId);
        if (legacy != null) {
          final legacyEpisode = legacy.episodeId.trim();
          if (legacyEpisode.isEmpty ||
              legacyEpisode == record.episodeId.trim()) {
            await LocalStorage.playbackHistoryBox().delete(mediaId);
          }
        }
      }
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<void> mergeAll(List<PlaybackRecord> records) async {
    for (final record in records) {
      final existing = load(record.videoId, episodeId: record.episodeId);
      if (existing == null || record.watchedAt.isAfter(existing.watchedAt)) {
        await save(record);
      }
    }
  }

  Future<void> remove(String mediaId, {String? episodeId}) async {
    final id = mediaId.trim();
    if (id.isEmpty) {
      return;
    }
    try {
      final box = LocalStorage.playbackHistoryBox();
      final ep = (episodeId ?? '').trim();
      if (ep.isNotEmpty) {
        await box.delete(storageKey(id, ep));
        final legacy = _read(id);
        if (legacy != null) {
          final legacyEpisode = legacy.episodeId.trim();
          if (legacyEpisode.isEmpty || legacyEpisode == ep) {
            await box.delete(id);
          }
        }
      } else {
        await box.delete(id);
        final stale = <dynamic>[];
        for (final key in box.keys) {
          if (key.toString().startsWith('$id|')) {
            stale.add(key);
          }
        }
        for (final key in stale) {
          await box.delete(key);
        }
      }
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<void> clear() async {
    try {
      await LocalStorage.clearPlaybackHistory();
      _notify();
    } on CacheException {
      return;
    }
  }

  List<PlaybackRecord> all() {
    final box = LocalStorage.playbackHistoryBox();
    final parsed = <PlaybackRecord>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map) {
        continue;
      }
      try {
        final record = PlaybackRecord.fromJson(Map<String, dynamic>.from(raw));
        if (record.videoId.trim().isEmpty) {
          continue;
        }
        parsed.add(record);
      } catch (_) {
        continue;
      }
    }
    parsed.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return parsed;
  }

  int count() {
    try {
      return all().length;
    } on CacheException {
      return 0;
    }
  }

  PlaybackRecord? _read(String key) {
    if (key.isEmpty) {
      return null;
    }
    try {
      final raw = LocalStorage.playbackHistoryBox().get(key);
      if (raw is Map) {
        return PlaybackRecord.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  PlaybackRecord? _newestFor(String mediaId) {
    try {
      for (final record in all()) {
        if (record.videoId.trim() == mediaId) {
          return record;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
