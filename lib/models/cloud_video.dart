import 'json_values.dart';

enum CloudVideoStatus {
  pending,
  uploading,
  uploaded,
  failed;

  static CloudVideoStatus parse(Object? raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'uploading':
        return CloudVideoStatus.uploading;
      case 'uploaded':
      case 'ready':
      case 'completed':
      case 'complete':
        return CloudVideoStatus.uploaded;
      case 'failed':
      case 'error':
        return CloudVideoStatus.failed;
      default:
        return CloudVideoStatus.pending;
    }
  }

  String get wire {
    return switch (this) {
      CloudVideoStatus.pending => 'pending',
      CloudVideoStatus.uploading => 'uploading',
      CloudVideoStatus.uploaded => 'uploaded',
      CloudVideoStatus.failed => 'failed',
    };
  }
}

class UploadSession {
  const UploadSession({
    required this.videoId,
    required this.uploadId,
    required this.chunkSize,
    required this.chunkTotal,
    this.nextChunkIndex = 0,
  });

  final String videoId;
  final String uploadId;
  final int chunkSize;
  final int chunkTotal;
  final int nextChunkIndex;

  factory UploadSession.fromJson(Map<String, dynamic> json) {
    return UploadSession(
      videoId: JsonValues.string(json['videoId'] ?? json['id']),
      uploadId: JsonValues.string(json['uploadId']),
      chunkSize: JsonValues.integer(json['chunkSize']) ?? 0,
      chunkTotal: JsonValues.integer(json['chunkTotal']) ?? 0,
      nextChunkIndex: JsonValues.integer(json['nextChunkIndex']) ?? 0,
    );
  }
}

class CloudVideo {
  const CloudVideo({
    required this.id,
    required this.userId,
    required this.title,
    required this.sizeBytes,
    this.durationMs,
    this.cover = '',
    this.playUrl = '',
    this.localPath = '',
    this.isPrivate = false,
    this.status = CloudVideoStatus.pending,
    this.createdAt,
    this.updatedAt,
    this.uploadId = '',
    this.uploadedBytes = 0,
    this.chunkIndex = 0,
    this.chunkTotal = 0,
  });

  final String id;
  final String userId;
  final String title;
  final int sizeBytes;
  final int? durationMs;
  final String cover;
  final String playUrl;
  final String localPath;
  final bool isPrivate;
  final CloudVideoStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String uploadId;
  final int uploadedBytes;
  final int chunkIndex;
  final int chunkTotal;

  bool get isUploaded => status == CloudVideoStatus.uploaded;

  bool get isFailed => status == CloudVideoStatus.failed;

  bool get isUploading => status == CloudVideoStatus.uploading;

  double get progress {
    if (sizeBytes <= 0) {
      return 0;
    }
    final value = uploadedBytes / sizeBytes;
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  String? get resolvedPlayUrl {
    final remote = playUrl.trim();
    if (remote.startsWith('http://') ||
        remote.startsWith('https://') ||
        remote.startsWith('file:') ||
        remote.startsWith('content:')) {
      return remote;
    }
    final local = localPath.trim();
    if (local.isEmpty) {
      return remote.isEmpty ? null : remote;
    }
    final uri = Uri.tryParse(local);
    if (uri != null && uri.hasScheme) {
      return local;
    }
    return Uri.file(local).toString();
  }

  CloudVideo copyWith({
    String? id,
    String? userId,
    String? title,
    int? sizeBytes,
    int? durationMs,
    String? cover,
    String? playUrl,
    String? localPath,
    bool? isPrivate,
    CloudVideoStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uploadId,
    int? uploadedBytes,
    int? chunkIndex,
    int? chunkTotal,
  }) {
    return CloudVideo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationMs: durationMs ?? this.durationMs,
      cover: cover ?? this.cover,
      playUrl: playUrl ?? this.playUrl,
      localPath: localPath ?? this.localPath,
      isPrivate: isPrivate ?? this.isPrivate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploadId: uploadId ?? this.uploadId,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkTotal: chunkTotal ?? this.chunkTotal,
    );
  }

  factory CloudVideo.fromJson(Map<String, dynamic> json) {
    return CloudVideo(
      id: JsonValues.string(json['id']),
      userId: JsonValues.string(json['userId']),
      title: JsonValues.string(json['title']),
      sizeBytes: JsonValues.integer(json['sizeBytes']) ?? 0,
      durationMs: JsonValues.integer(json['durationMs']),
      cover: JsonValues.string(json['cover']),
      playUrl: JsonValues.string(json['playUrl'] ?? json['url']),
      localPath: JsonValues.string(json['localPath']),
      isPrivate: JsonValues.flag(json['isPrivate']),
      status: CloudVideoStatus.parse(json['status']),
      createdAt: JsonValues.date(json['createdAt']),
      updatedAt: JsonValues.date(json['updatedAt']),
      uploadId: JsonValues.string(json['uploadId']),
      uploadedBytes: JsonValues.integer(json['uploadedBytes']) ?? 0,
      chunkIndex: JsonValues.integer(json['chunkIndex']) ?? 0,
      chunkTotal: JsonValues.integer(json['chunkTotal']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'sizeBytes': sizeBytes,
      'durationMs': durationMs,
      'cover': cover,
      'playUrl': playUrl,
      'localPath': localPath,
      'isPrivate': isPrivate,
      'status': status.wire,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'uploadId': uploadId,
      'uploadedBytes': uploadedBytes,
      'chunkIndex': chunkIndex,
      'chunkTotal': chunkTotal,
    };
  }
}
