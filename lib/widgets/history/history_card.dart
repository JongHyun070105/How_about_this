
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:review_ai/providers/review_provider.dart';
import 'package:review_ai/widgets/review/rating_row.dart';

class HistoryCard extends StatelessWidget {
  final ReviewHistoryEntry entry;

  const HistoryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 음식명
            Text(
              entry.foodName.isNotEmpty ? entry.foodName : '음식명 없음',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.05,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            // 별점 정보
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Column(
                children: [
                  RatingRow(
                    label: '배달',
                    rating: entry.deliveryRating,
                    iconSize: screenWidth * 0.05,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  RatingRow(
                    label: '맛',
                    rating: entry.tasteRating,
                    iconSize: screenWidth * 0.05,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  RatingRow(
                    label: '양',
                    rating: entry.portionRating,
                    iconSize: screenWidth * 0.05,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  RatingRow(
                    label: '가격',
                    rating: entry.priceRating,
                    iconSize: screenWidth * 0.05,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            // 리뷰 스타일
            if (entry.reviewStyle.isNotEmpty)
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Text(
                      entry.reviewStyle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontFamily: 'Do Hyeon',
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: screenHeight * 0.02),
            // AI 생성 리뷰 섹션 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI 생성 리뷰',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    color: Colors.blue,
                    size: screenWidth * 0.05,
                  ),
                  onPressed: () {
                    final allReviewsText = entry.generatedReviews.join('\n\n');
                    Clipboard.setData(
                      ClipboardData(
                        text: allReviewsText,
                      ),
                    );
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          '모든 AI 생성 리뷰가 클립보드에 복사되었습니다.',
                          style: const TextStyle(
                            fontFamily: 'Do Hyeon',
                          ),
                        ),
                        duration: const Duration(
                          seconds: 2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            // 생성된 리뷰들
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.generatedReviews.asMap().entries.map((e) {
                  final isLast = e.key == entry.generatedReviews.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? 0 : screenHeight * 0.015,
                    ),
                    child: Text(
                      e.value,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        fontFamily: 'Do Hyeon',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
