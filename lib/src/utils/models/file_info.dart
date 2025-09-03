import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

class FileInfo with EquatableMixin {
  final String fileName;
  final String filePath;
  final int fileSize;
  final Stream<List<int>>? readStream;
  final String? customMimeType;

  FileInfo(
    this.fileName,
    this.filePath,
    this.fileSize, {
    this.readStream,
    this.customMimeType,
  });

  factory FileInfo.empty() {
    return FileInfo('', '', 0);
  }

  String get mimeType =>
      customMimeType ?? lookupMimeType(filePath) ?? lookupMimeType(fileName) ?? 'application/octet-stream';


  Map<String, dynamic> get metadata => ({
        'mimetype': mimeType,
        'size': fileSize,
      });

  factory FileInfo.fromMatrixFile(MatrixFile file) {
    if (file.msgType == MessageTypes.Image) {
      return ImageFileInfo(
        file.name,
        file.filePath ?? '',
        file.size,
        width: file.info['w'],
        height: file.info['h'],
        customMimeType: file.mimeType,
      );
    } else if (file.msgType == MessageTypes.Video) {
      return VideoFileInfo(
        file.name,
        file.filePath ?? '',
        file.size,
        imagePlaceholderBytes: file.bytes ?? Uint8List(0),
        width: file.info['w'],
        height: file.info['h'],
        duration: file.info['duration'] != null && file.info['duration'] is int
            ? Duration(milliseconds: file.info['duration'])
            : null,
        customMimeType: file.mimeType,
      );
    }
    return FileInfo(file.name, file.filePath ?? '', file.size, customMimeType: file.mimeType,);
  }

  @override
  List<Object?> get props => [fileName, filePath, fileSize, readStream];
}
