import 'package:flutter/material.dart';

class EmptyHistory extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const EmptyHistory({
    super.key,
    this.title = '아직 생성된 리뷰가 없습니다.',
    this.message = '메인 화면에서 첫 리뷰를 작성해보세요!',
    this.icon = Icons.history_toggle_off,
  });

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
              icon,
              size: screenWidth * 0.2,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              title,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.045,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
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
