import 'package:flutter/cupertino.dart';

import 'package:in_app_review/in_app_review.dart';
import 'package:review_ai/widgets/common/app_dialogs.dart';

// Replaced showValidationDialog
void showValidationDialog(BuildContext context, Size screenSize) {
  showAppDialog(
    context,
    title: '입력 오류',
    message: '모든 입력을 완료해주세요.',
    isError: true,
  );
}

// Replaced showImageErrorDialog
void showImageErrorDialog(
  BuildContext context,
  String message,
  Size screenSize,
) {
  showAppDialog(context, title: '이미지 오류', message: message, isError: true);
}

void showReviewPromptDialog(
  BuildContext context,
  double screenWidth,
  double screenHeight,
) {
  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: const Text(
          '리뷰 작성은 어떠세요?',
          style: TextStyle(fontFamily: 'Do Hyeon', fontWeight: FontWeight.bold),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            '앱 개선을 위해 잠시 시간을 내어 리뷰를 작성해주시면 감사하겠습니다!',
            style: TextStyle(fontFamily: 'Do Hyeon', fontSize: 16),
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: const Text('나중에', style: TextStyle(fontFamily: 'Do Hyeon')),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final InAppReview inAppReview = InAppReview.instance;
              if (await inAppReview.isAvailable()) {
                inAppReview.requestReview();
              }
            },
            child: const Text(
              '리뷰 작성',
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
