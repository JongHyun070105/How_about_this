import 'package:flutter/material.dart';
import 'package:eat_this_app/widgets/history/empty_history.dart';
import 'package:eat_this_app/widgets/history/history_card.dart';
import 'package:eat_this_app/providers/review_provider.dart';

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
                    ? const EmptyHistory()
                    : RefreshIndicator(
                        onRefresh: () async {
                          return ref.refresh(reviewHistoryProvider);
                        },
                        child: ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = history[history.length - 1 - index];
                            return HistoryCard(entry: entry);
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

  
}
