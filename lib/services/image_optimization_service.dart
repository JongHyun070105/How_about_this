import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Offloads image decode/resize/encode work to a background isolate.
///
/// Returns `null` when the image is already within limits or cannot be decoded.
Future<Uint8List?> optimizeUploadedImageBytes(
  Uint8List bytes, {
  int maxDimension = 800,
  int jpegQuality = 85,
}) {
  if (bytes.isEmpty) return Future.value(null);

  return Isolate.run(() {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      if (image.width <= maxDimension && image.height <= maxDimension) {
        return null;
      }

      final resized = img.copyResize(
        image,
        width: image.width > image.height ? maxDimension : null,
        height: image.height > image.width ? maxDimension : null,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
    } catch (e) {
      return null;
    }
  });
}
