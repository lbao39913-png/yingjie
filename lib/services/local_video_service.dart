import 'dart:async';

import '../core/errors/app_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/local_video.dart';

class LocalVideoService {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  List<LocalVideo> all() {
    try {
      final items = LocalStorage.localVideosBox()
          .values
          .whereType<Map>()
          .map((item) => LocalVideo.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id.isNotEmpty)
          .toList();
      items.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      return items;
    } on CacheException {
      return const [];
    }
  }

  LocalVideo? getById(String id) {
    final key = id.trim();
    if (key.isEmpty) {
      return null;
    }
    try {
      final raw = LocalStorage.localVideosBox().get(key);
      if (raw is Map) {
        return LocalVideo.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    } on CacheException {
      return null;
    }
  }

  Future<LocalVideo> import({
    required String title,
    required String filePath,
    required int sizeBytes,
    String? id,
  }) async {
    final path = filePath.trim();
    if (path.isEmpty) {
      throw const CacheException(message: '无法读取所选视频');
    }
    final now = DateTime.now().toUtc();
    final video = LocalVideo(
      id: (id ?? '').trim().isEmpty
          ? 'local-${now.microsecondsSinceEpoch}'
          : id!.trim(),
      title: title.trim().isEmpty ? '本地视频' : title.trim(),
      filePath: path,
      sizeBytes: sizeBytes < 0 ? 0 : sizeBytes,
      createdAt: now,
    );
    try {
      await LocalStorage.localVideosBox().put(video.id, video.toJson());
      _notify();
      return video;
    } on CacheException {
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final key = id.trim();
    if (key.isEmpty) {
      return;
    }
    try {
      await LocalStorage.localVideosBox().delete(key);
      _notify();
    } on CacheException {
      return;
    }
  }

  int count() => all().length;

  void dispose() {
    _changes.close();
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
