import 'dart:typed_data';

import 'package:matrix/matrix.dart';

class VideoFileInfo extends FileInfo {
  final Uint8List? imagePlaceholderBytes;

  final Duration? duration;

  final int? width;

  final int? height;

  VideoFileInfo(
    super.fileName,
    super.filePath,
    super.fileSize, {
    this.imagePlaceholderBytes,
    this.width,
    this.height,
    this.duration,
  });

  @override
  Map<String, dynamic> get metadata => ({
        'mimetype': mimeType,
        'size': fileSize,
        if (width != null) 'w': width!.toDouble(),
        if (height != null) 'h': height!.toDouble(),
        if (duration != null) 'duration': duration!.inMilliseconds,
      });

  @override
  List<Object?> get props => [
        width,
        height,
        duration,
        imagePlaceholderBytes,
        ...super.props,
      ];
}
