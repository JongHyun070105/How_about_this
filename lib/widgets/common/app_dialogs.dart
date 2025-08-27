import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showAppDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isError = false,
  String? confirmButtonText,
  VoidCallback? onConfirm,
  String cancelButtonText = '확인',
}) {
  if (!context.mounted) return;

  final actions = <Widget>[
    // Cancel/Default Button
    CupertinoDialogAction(
      isDefaultAction:
          onConfirm == null, // It's the default if there's no confirm action
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        onConfirm != null ? '나중에' : cancelButtonText,
        style: const TextStyle(fontFamily: 'SCDream', color: Colors.blue),
      ),
    ),
  ];

  // Confirm Button (e.g., for updates)
  if (onConfirm != null && confirmButtonText != null) {
    actions.add(
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: () {
          Navigator.of(context).pop();
          onConfirm();
        },
        child: Text(
          confirmButtonText,
          style: const TextStyle(
            fontFamily: 'SCDream',
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SCDream',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            message,
            style: const TextStyle(fontFamily: 'SCDream', fontSize: 16),
          ),
        ),
        actions: actions,
      );
    },
  );
}
