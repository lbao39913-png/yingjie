class PickedLocalVideo {
  const PickedLocalVideo({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;
}

abstract class VideoPicker {
  Future<PickedLocalVideo?> pickVideo();
}

class UnavailableVideoPicker implements VideoPicker {
  const UnavailableVideoPicker();

  @override
  Future<PickedLocalVideo?> pickVideo() async {
    return null;
  }
}
