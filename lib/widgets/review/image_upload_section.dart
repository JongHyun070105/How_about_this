
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eat_this_app/providers/review_provider.dart';

final isPickingImageProvider = StateProvider<bool>((ref) => false);

class ImageUploadSection extends ConsumerWidget {
  const ImageUploadSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(imageProvider);
    final isPicking = ref.watch(isPickingImageProvider);
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: isPicking ? null : () => _pickImage(ref, context),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBDBDBD), width: screenSize.width * 0.005),
            borderRadius: BorderRadius.circular(screenSize.width * 0.0375),
            color: const Color(0xFFF1F1F1),
          ),
          child: _buildImageContent(context, image, screenSize.width, isPicking),
        ),
      ),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    File? imageFile,
    double screenWidth,
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
              size: screenWidth * 0.1,
              color: Colors.grey.shade600,
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              '이미지 업로드',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                fontFamily: 'Do Hyeon',
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.0375),
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
        ref.read(imageProvider.notifier).state = File(picked.path);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 선택에 실패했습니다.')),
      );
    } finally {
      if (context.mounted) {
        ref.read(isPickingImageProvider.notifier).state = false;
      }
    }
  }
}
