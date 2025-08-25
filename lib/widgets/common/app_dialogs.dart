import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showAppDialog(BuildContext context, {
  required String title,
  required String message,
  bool isError = false,
}) {
  if (!context.mounted) return;

  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Do Hyeon',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            message,
            style: const TextStyle(fontFamily: 'Do Hyeon', fontSize: 16),
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(fontFamily: 'Do Hyeon'),
            ),
          ),
        ],
      );
    },
  );
}
