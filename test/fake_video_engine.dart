import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yingjie/core/errors/app_exception.dart';
import 'package:yingjie/features/player/video_engine.dart';

class FakeVideoEngine implements VideoEngine {
  FakeVideoEngine({
    this.failOpen = false,
    this.openDelay = Duration.zero,
    this.videoDuration = const Duration(seconds: 120),
  });

  bool failOpen;
  Duration openDelay;
  Completer<void>? openGate;
  Duration videoDuration;
  Duration currentPosition = Duration.zero;
  bool playing = false;
  bool initialized = false;
  double currentVolume = 1;
  double currentSpeed = 1;
  bool buffering = false;
  int openCount = 0;
  int playCount = 0;
  int pauseCount = 0;
  int seekCount = 0;
  int speedCount = 0;
  int disposeCount = 0;
  Uri? openedUrl;
  bool _disposed = false;
  VoidCallback? _onChanged;
  final StreamController<VideoEngineEvent> _events =
      StreamController<VideoEngineEvent>.broadcast();

  @override
  bool get isInitialized => initialized;

  @override
  bool get isPlaying => playing;

  @override
  bool get isBuffering => buffering;

  @override
  Duration get duration => videoDuration;

  @override
  Duration get position => currentPosition;

  @override
  double get volume => currentVolume;

  @override
  double get playbackSpeed => currentSpeed;

  @override
  double get aspectRatio => 16 / 9;

  @override
  Stream<VideoEngineEvent> get events => _events.stream;

  @override
  void attach(VoidCallback onChanged) {
    _onChanged = onChanged;
  }

  @override
  Widget buildView() {
    return const ColoredBox(
      key: Key('fake-video'),
      color: Colors.black,
    );
  }

  @override
  Future<void> open(Uri url) async {
    openCount++;
    openedUrl = url;
    initialized = false;
    if (openDelay > Duration.zero) {
      await Future<void>.delayed(openDelay);
    }
    if (openGate != null) {
      await openGate!.future;
    }
    if (_disposed) {
      return;
    }
    if (failOpen) {
      throw const PlaybackException(message: '播放失败，请检查网络后重试');
    }
    initialized = true;
    _onChanged?.call();
  }

  @override
  Future<void> play() async {
    playCount++;
    playing = true;
    _onChanged?.call();
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    playing = false;
    _onChanged?.call();
  }

  @override
  Future<void> seekTo(Duration next) async {
    seekCount++;
    currentPosition = next;
    _onChanged?.call();
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume.clamp(0.0, 1.0);
    _onChanged?.call();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    speedCount++;
    currentSpeed = speed;
    _onChanged?.call();
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    _disposed = true;
    _onChanged = null;
    final gate = openGate;
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }
    await _events.close();
  }

  void tick(Duration next) {
    currentPosition = next;
    _onChanged?.call();
  }

  void emitCompleted() {
    playing = false;
    currentPosition = videoDuration;
    _events.add(VideoEngineEvent.completed);
    _onChanged?.call();
  }

  void emitError() {
    _events.add(VideoEngineEvent.error);
  }

  void emitBuffering(bool value) {
    buffering = value;
    _onChanged?.call();
  }
}
