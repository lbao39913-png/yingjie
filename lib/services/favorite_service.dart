import 'dart:async';

import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/video.dart';

class FavoriteService {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  bool contains(String id) {
    final key = id.trim();
    if (key.isEmpty) {
      return false;
    }
    try {
      return LocalStorage.favoritesBox().containsKey(key);
    } on CacheException {
      return false;
    }
  }

  Future<void> add(Video video) async {
    final key = video.id.trim();
    if (key.isEmpty || contains(key)) {
      return;
    }
    try {
      final json = video.toJson();
      json['favoritedAt'] = DateTime.now().toIso8601String();
      await LocalStorage.favoritesBox().put(key, json);
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<void> remove(String id) async {
    final key = id.trim();
    if (key.isEmpty) {
      return;
    }
    try {
      await LocalStorage.favoritesBox().delete(key);
      _notify();
    } on CacheException {
      return;
    }
  }

  Future<bool> toggle(Video video) async {
    if (contains(video.id)) {
      await remove(video.id);
      return false;
    }
    await add(video);
    return true;
  }

  Future<void> mergeAll(List<Video> videos) async {
    for (final video in videos) {
      await add(video);
    }
  }

  int count() {
    try {
      return all().length;
    } on CacheException {
      return 0;
    }
  }

  Future<void> clear() async {
    try {
      await LocalStorage.favoritesBox().clear();
      _notify();
    } on CacheException {
      return;
    }
  }

  List<Video> all() {
    final box = LocalStorage.favoritesBox();
    final parsed = <_FavoriteEntry>[];
    var order = 0;
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(raw);
      final video = Video.fromJson(map);
      if (video.id.trim().isEmpty) {
        continue;
      }
      parsed.add(
        _FavoriteEntry(
          video: video,
          favoritedAt: DateTime.tryParse('${map['favoritedAt'] ?? ''}'),
          order: order,
        ),
      );
      order += 1;
    }
    parsed.sort((a, b) {
      final aAt = a.favoritedAt;
      final bAt = b.favoritedAt;
      if (aAt != null && bAt != null) {
        final byTime = bAt.compareTo(aAt);
        if (byTime != 0) {
          return byTime;
        }
      } else if (aAt != null) {
        return -1;
      } else if (bAt != null) {
        return 1;
      }
      return b.order.compareTo(a.order);
    });
    return parsed.map((item) => item.video).toList(growable: false);
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}

class _FavoriteEntry {
  const _FavoriteEntry({
    required this.video,
    required this.favoritedAt,
    required this.order,
  });

  final Video video;
  final DateTime? favoritedAt;
  final int order;
}
