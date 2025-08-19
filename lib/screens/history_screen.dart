import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/providers/review_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(reviewHistoryProvider);
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '리뷰 AI',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
            fontFamily: 'Do Hyeon',
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.02),
              // 섹션 제목
              Text(
                '리뷰 히스토리',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Do Hyeon',
                  fontSize: screenWidth * 0.06,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // 히스토리 목록
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off,
                                size: screenWidth * 0.2,
                                color: Colors.grey,
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Text(
                                '아직 생성된 리뷰가 없습니다.',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'Do Hyeon',
                                  fontSize: screenWidth * 0.045,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Text(
                                '메인 화면에서 첫 리뷰를 작성해보세요!',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Do Hyeon',
                                  fontSize: screenWidth * 0.035,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          return ref.refresh(reviewHistoryProvider);
                        },
                        child: ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = history[history.length - 1 - index];
                            return Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin:
                                  EdgeInsets.only(bottom: screenHeight * 0.02),
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.04),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 음식명
                                    Text(
                                      entry.foodName.isNotEmpty
                                          ? entry.foodName
                                          : '음식명 없음',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Do Hyeon',
                                        fontSize: screenWidth * 0.05,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    // 별점 정보
                                    Container(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.03),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildRatingRow(
                                            '배달',
                                            entry.deliveryRating,
                                            textTheme,
                                            context,
                                          ),
                                          const SizedBox(height: 4),
                                          _buildRatingRow(
                                            '맛',
                                            entry.tasteRating,
                                            textTheme,
                                            context,
                                          ),
                                          const SizedBox(height: 4),
                                          _buildRatingRow(
                                            '양',
                                            entry.portionRating,
                                            textTheme,
                                            context,
                                          ),
                                          const SizedBox(height: 4),
                                          _buildRatingRow(
                                            '가격',
                                            entry.priceRating,
                                            textTheme,
                                            context,
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
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              entry.reviewStyle,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'AI 생성 리뷰',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
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
                                            final allReviewsText = entry
                                                .generatedReviews
                                                .join('\n\n');
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
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.03),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: entry.generatedReviews
                                            .asMap()
                                            .entries
                                            .map((e) {
                                          final isLast = e.key ==
                                              entry.generatedReviews.length -
                                                  1;
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: isLast
                                                  ? 0
                                                  : screenHeight * 0.015,
                                            ),
                                            child: Text(
                                              e.value,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                height: 1.4,
                                                fontFamily: 'Do Hyeon',
                                                fontSize:
                                                    screenWidth * 0.035,
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
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(
      String label, double rating, TextTheme textTheme, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      children: [
        SizedBox(
          width: screenWidth * 0.12,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: 'Do Hyeon',
              fontSize: screenWidth * 0.038,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < rating ? Colors.amber : Colors.grey.shade300,
                size: screenWidth * 0.05,
              );
            }),
          ),
        ),
      ],
    );
  }
}
