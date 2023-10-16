import 'package:matrix/matrix.dart';

class ImageFileInfo extends FileInfo {
  ImageFileInfo(
    super.fileName,
    super.filePath,
    super.fileSize, {
    this.width,
    this.height,
  });

  final int? width;

  final int? height;

  @override
  Map<String, dynamic> get metadata => ({
        'mimetype': mimeType,
        'size': fileSize,
        if (width != null) 'w': width!.toDouble(),
        if (height != null) 'h': height!.toDouble(),
      });

  @override
  List<Object?> get props => [width, height, ...super.props];
}
