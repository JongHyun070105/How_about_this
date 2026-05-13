import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:review_ai/services/image_optimization_service.dart';

void main() {
  test('optimizeUploadedImageBytes returns null for small images', () async {
    final image = img.Image(width: 100, height: 100);
    final bytes = Uint8List.fromList(img.encodeJpg(image));

    final optimized = await optimizeUploadedImageBytes(bytes);

    expect(optimized, isNull);
  });

  test('optimizeUploadedImageBytes resizes large images', () async {
    final image = img.Image(width: 2000, height: 1000);
    final bytes = Uint8List.fromList(img.encodeJpg(image));

    final optimized = await optimizeUploadedImageBytes(bytes);

    expect(optimized, isNotNull);
    final decoded = img.decodeImage(optimized!);
    expect(decoded, isNotNull);
    expect(decoded!.width, 800);
    expect(decoded.height, 400);
  });
}
