import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:review_ai/providers/review_provider.dart';

final isPickingImageProvider = StateProvider<bool>((ref) => false);

class ImageUploadSection extends ConsumerWidget {
  const ImageUploadSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewProvider);
    final image = reviewState.image;
    final isPicking = ref.watch(isPickingImageProvider);

    return GestureDetector(
      onTap: isPicking ? null : () => _pickImage(ref, context),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // 음식명 필드와 같은 흰색 배경
            borderRadius: BorderRadius.circular(
              12.0,
            ), // 음식명 필드와 같은 border radius
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.0,
            ), // 음식명 필드와 같은 border
          ),
          child: _buildImageContent(context, image, isPicking),
        ),
      ),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    File? imageFile,
    bool isPicking,
  ) {
    if (isPicking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (imageFile == null || !imageFile.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48.0, // 고정된 크기로 변경
              color: Colors.grey[400], // 음식명 필드 힌트 텍스트와 비슷한 색상
            ),
            const SizedBox(height: 12.0), // 고정된 간격
            Text(
              '이미지 업로드',
              style: TextStyle(
                fontSize: 16.0, // 고정된 폰트 크기
                fontFamily: 'Do Hyeon', // 음식명 필드와 같은 폰트
                color: Colors.grey[500], // 음식명 필드와 비슷한 색상
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0), // 음식명 필드와 같은 border radius
        image: DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover),
      ),
    );
  }

  void _pickImage(WidgetRef ref, BuildContext context) async {
    if (ref.read(isPickingImageProvider)) return;

    ref.read(isPickingImageProvider.notifier).state = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        ref.read(reviewProvider.notifier).setImage(File(picked.path));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지 선택에 실패했습니다.')));
    } finally {
      if (context.mounted) {
        ref.read(isPickingImageProvider.notifier).state = false;
      }
    }
  }
}