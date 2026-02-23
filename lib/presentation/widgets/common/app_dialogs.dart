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
    // 취소/기본 버튼
    CupertinoDialogAction(
      isDefaultAction: onConfirm == null, // 확인 액션이 없으면 이것이 기본 버튼
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        onConfirm != null ? '나중에' : cancelButtonText,
        style: TextStyle(
          fontFamily: 'SCDream',
          color: Theme.of(context).primaryColor,
        ),
      ),
    ),
  ];

  // 확인 버튼 (예: 업데이트용)
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
          style: TextStyle(
            fontFamily: 'SCDream',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
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
