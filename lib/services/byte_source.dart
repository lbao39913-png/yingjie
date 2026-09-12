import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

abstract class ByteSource {
  int get length;

  Future<List<int>> read(int offset, int length);
}

class MemoryByteSource implements ByteSource {
  MemoryByteSource(this._bytes);

  final List<int> _bytes;

  @override
  int get length => _bytes.length;

  @override
  Future<List<int>> read(int offset, int length) async {
    if (offset < 0 || offset > _bytes.length) {
      return const [];
    }
    final end = min(_bytes.length, offset + length);
    return _bytes.sublist(offset, end);
  }
}

class FileByteSource implements ByteSource {
  FileByteSource(this._file, this.length);

  final File _file;

  @override
  final int length;

  static Future<FileByteSource> open(String path) async {
    final file = File(path);
    final size = await file.length();
    return FileByteSource(file, size);
  }

  @override
  Future<List<int>> read(int offset, int length) async {
    final raf = await _file.open();
    try {
      await raf.setPosition(offset);
      final buffer = Uint8List(length);
      final read = await raf.readInto(buffer);
      if (read < length) {
        return buffer.sublist(0, read);
      }
      return buffer;
    } finally {
      await raf.close();
    }
  }
}
