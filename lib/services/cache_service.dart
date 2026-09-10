import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  CacheService({
    Future<int> Function()? measure,
    Future<void> Function()? clear,
  })  : _measure = measure ?? measureDiskCache,
        _clear = clear ?? clearDiskCache;

  final Future<int> Function() _measure;
  final Future<void> Function() _clear;

  Future<int> sizeBytes() => _measure();

  Future<void> clearCache() => _clear();

  String sizeLabel(int bytes) {
    if (bytes <= 0) {
      return '暂无可清理缓存';
    }
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '缓存大小 $kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '缓存大小 $mb MB';
  }

  static Future<int> measureDiskCache() async {
    try {
      final root = await getTemporaryDirectory();
      final dir = Directory('${root.path}/${DefaultCacheManager.key}');
      if (!dir.existsSync()) {
        return 0;
      }
      var total = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clearDiskCache() async {
    await DefaultCacheManager().emptyCache();
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}
