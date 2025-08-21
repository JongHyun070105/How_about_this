
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showValidationDialog(BuildContext context, Size screenSize) {
  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text(
        '입력 오류',
        style: TextStyle(
          fontFamily: 'Do Hyeon',
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Padding(
        padding: EdgeInsets.only(top: screenSize.height * 0.01),
        child: Text(
          '모든 입력을 완료해주세요.',
          style: TextStyle(fontFamily: 'Do Hyeon', fontSize: screenSize.width * 0.04),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인', style: TextStyle(fontFamily: 'Do Hyeon')),
        ),
      ],
    ),
  );
}

void showImageErrorDialog(BuildContext context, String message, Size screenSize) {
  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text(
        '이미지 오류',
        style: TextStyle(
          fontFamily: 'Do Hyeon',
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          message,
          style: TextStyle(fontFamily: 'Do Hyeon', fontSize: screenSize.width * 0.04),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인', style: TextStyle(fontFamily: 'Do Hyeon')),
        ),
      ],
    ),
  );
}
