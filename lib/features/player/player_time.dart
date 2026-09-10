String formatPlayerTime(Duration duration) {
  final total = duration.inSeconds;
  final safe = total < 0 ? 0 : total;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final seconds = safe % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$mm:$ss';
  }
  return '$mm:$ss';
}

String formatPlayerTimeRange(Duration position, Duration duration) {
  return '${formatPlayerTime(position)} / ${formatPlayerTime(duration)}';
}
