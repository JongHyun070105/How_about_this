import 'package:flutter/material.dart';

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: screenWidth * 0.2,
              color: Colors.grey,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              '아직 생성된 리뷰가 없습니다.',
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.045,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              '메인 화면에서 첫 리뷰를 작성해보세요!',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.035,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
