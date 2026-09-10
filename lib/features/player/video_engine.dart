import 'package:flutter/widgets.dart';

enum VideoEngineEvent { completed, error }

abstract class VideoEngine {
  Future<void> open(Uri url);

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(Duration position);

  Future<void> setVolume(double volume);

  Future<void> setPlaybackSpeed(double speed);

  Future<void> dispose();

  bool get isInitialized;

  bool get isPlaying;

  bool get isBuffering;

  Duration get position;

  Duration get duration;

  double get volume;

  double get playbackSpeed;

  double get aspectRatio;

  Stream<VideoEngineEvent> get events;

  void attach(VoidCallback onChanged);

  Widget buildView();
}

typedef VideoEngineFactory = VideoEngine Function();
