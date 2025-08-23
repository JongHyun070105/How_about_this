import 'package:flutter/material.dart';

class ReviewPromptDialog extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const ReviewPromptDialog({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.only(bottom: 12, top: 12),
      title: Text(
        '리뷰 작성 팁!',
        style: TextStyle(
          fontFamily: 'Do Hyeon',
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        '추천된 음식이 마음에 드셨나요? 드신 후, 상단의 리뷰 작성 버튼을 눌러 AI를 활용해서 리뷰를 작성해보세요!',
        style: TextStyle(fontFamily: 'Do Hyeon', fontSize: screenWidth * 0.04),
        textAlign: TextAlign.center,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '확인',
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}
