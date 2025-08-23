import 'package:flutter/material.dart';

void showAppDialog(BuildContext context, {
  required String title,
  required String message,
}) {
  if (!context.mounted) return;

  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 768;
  final titleFontSize = (screenWidth * (isTablet ? 0.035 : 0.045)).clamp(16.0, 24.0);
  final contentFontSize = (screenWidth * (isTablet ? 0.028 : 0.04)).clamp(14.0, 20.0);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
        ),
        title: Text(
          title,
          style: TextStyle(fontFamily: 'Do Hyeon', fontSize: titleFontSize),
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Do Hyeon', fontSize: contentFontSize),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              '확인',
              style: TextStyle(fontFamily: 'Do Hyeon', fontSize: contentFontSize),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
