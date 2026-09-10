import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_engine.dart';

class VideoPlayerEngine implements VideoEngine {
  VideoPlayerController? _controller;
  VoidCallback? _onChanged;
  final StreamController<VideoEngineEvent> _events =
      StreamController<VideoEngineEvent>.broadcast();
  bool _disposed = false;
  bool _completedEmitted = false;

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  @override
  bool get isBuffering => _controller?.value.isBuffering ?? false;

  @override
  Duration get position => _controller?.value.position ?? Duration.zero;

  @override
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  @override
  double get volume => _controller?.value.volume ?? 1;

  @override
  double get playbackSpeed => _controller?.value.playbackSpeed ?? 1;

  @override
  double get aspectRatio {
    final value = _controller?.value.aspectRatio ?? 0;
    if (value <= 0) {
      return 16 / 9;
    }
    return value;
  }

  @override
  Stream<VideoEngineEvent> get events => _events.stream;

  @override
  void attach(VoidCallback onChanged) {
    _onChanged = onChanged;
  }

  @override
  Widget buildView() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return VideoPlayer(controller);
  }

  @override
  Future<void> open(Uri url) async {
    await _releaseController();
    _completedEmitted = false;
    final controller = VideoPlayerController.networkUrl(url);
    _controller = controller;
    controller.addListener(_handleValue);
    await controller.initialize();
    if (_disposed) {
      await _releaseController();
    }
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _controller?.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.setPlaybackSpeed(speed);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _onChanged = null;
    await _releaseController();
    await _events.close();
  }

  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) {
      return;
    }
    controller.removeListener(_handleValue);
    await controller.dispose();
  }

  void _handleValue() {
    if (_disposed) {
      return;
    }
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final value = controller.value;
    if (value.hasError) {
      if (!_events.isClosed) {
        _events.add(VideoEngineEvent.error);
      }
      return;
    }
    final duration = value.duration;
    if (!_completedEmitted &&
        duration > Duration.zero &&
        value.position >= duration &&
        !value.isPlaying) {
      _completedEmitted = true;
      if (!_events.isClosed) {
        _events.add(VideoEngineEvent.completed);
      }
    }
    _onChanged?.call();
  }
}
