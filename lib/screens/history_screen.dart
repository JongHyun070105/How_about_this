import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // Responsive calculations
    final isTablet = screenWidth >= 768;
    final isSmallScreen = screenWidth < 600;

    // Dynamic font sizes
    final appBarFontSize = (screenWidth * (isTablet ? 0.032 : 0.05)).clamp(
      16.0,
      28.0,
    );
    final titleFontSize = (screenWidth * (isTablet ? 0.038 : 0.06)).clamp(
      18.0,
      32.0,
    );

    // Dynamic spacing
    final horizontalPadding = (screenWidth * (isTablet ? 0.06 : 0.04)).clamp(
      16.0,
      48.0,
    );
    final verticalSpacing = (screenHeight * (isTablet ? 0.025 : 0.02)).clamp(
      12.0,
      24.0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '리뷰 AI',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: appBarFontSize,
            fontFamily: 'Do Hyeon',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        // Responsive leading button
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: (screenWidth * (isTablet ? 0.04 : 0.06)).clamp(20.0, 32.0),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: verticalSpacing),

              // Section title with responsive styling
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  '리뷰 히스토리',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                    fontSize: titleFontSize,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              SizedBox(height: verticalSpacing),

              // History list with responsive design
              Expanded(
                child: history.isEmpty
                    ? const EmptyHistory()
                    : RefreshIndicator(
                        onRefresh: () async {
                          return ref.refresh(reviewHistoryProvider);
                        },
                        color: Theme.of(context).primaryColor,
                        backgroundColor: Colors.white,
                        strokeWidth: isTablet ? 3.0 : 2.5,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: history.length,
                          separatorBuilder: (context, index) => SizedBox(
                            height: (screenHeight * (isTablet ? 0.015 : 0.01))
                                .clamp(8.0, 16.0),
                          ),
                          itemBuilder: (context, index) {
                            final entry = history[history.length - 1 - index];
                            return AnimatedContainer(
                              duration: Duration(
                                milliseconds: 300 + (index * 50),
                              ),
                              curve: Curves.easeOutCubic,
                              child: HistoryCard(entry: entry),
                            );
                          },
                        ),
                      ),
              ),

              // Bottom padding for better scrolling experience
              SizedBox(height: (screenHeight * 0.02).clamp(12.0, 20.0)),
            ],
          ),
        ),
      ),
    );
  }
}
