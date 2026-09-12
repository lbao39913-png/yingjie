import 'package:file_picker/file_picker.dart';

import 'video_picker.dart';

class SystemVideoPicker implements VideoPicker {
  const SystemVideoPicker();

  @override
  Future<PickedLocalVideo?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.first;
    final path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    return PickedLocalVideo(
      path: path,
      name: file.name,
      sizeBytes: file.size,
    );
  }
}
