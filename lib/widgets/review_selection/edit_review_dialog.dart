
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eat_this_app/providers/review_provider.dart';

class EditReviewDialog extends ConsumerStatefulWidget {
  final int index;
  final String currentReview;

  const EditReviewDialog({
    super.key,
    required this.index,
    required this.currentReview,
  });

  @override
  ConsumerState<EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends ConsumerState<EditReviewDialog> {
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.currentReview);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text(
        '리뷰 수정',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Do Hyeon',
              fontSize: screenWidth * 0.05,
            ),
      ),
      content: TextField(
        controller: _editController,
        maxLines: null, // Allow multiple lines
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '리뷰 내용을 수정해주세요',
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'Do Hyeon',
              fontSize: screenWidth * 0.04,
            ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            '취소',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Do Hyeon',
                  color: Colors.grey,
                  fontSize: screenWidth * 0.04,
                ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(
            '저장',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Do Hyeon',
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                ),
          ),
          onPressed: () {
            final newReview = _editController.text;
            if (newReview.isNotEmpty) {
              final currentReviews = ref.read(generatedReviewsProvider);
              final updatedReviews = List<String>.from(currentReviews);
              updatedReviews[widget.index] = newReview;
              ref.read(generatedReviewsProvider.notifier).state = updatedReviews;
              Navigator.of(context).pop();
            } else {
              // Optionally show a snackbar or error message if review is empty
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('리뷰 내용은 비워둘 수 없습니다.', style: TextStyle(fontFamily: 'Do Hyeon')),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
