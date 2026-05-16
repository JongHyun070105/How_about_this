import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:review_ai/presentation/widgets/notification_settings_sheet.dart';
import 'package:review_ai/presentation/widgets/history/dialogs/user_stats_dialog.dart';
import 'package:review_ai/presentation/screens/review_screen.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/config/app_constants.dart';

/// 오늘의 추천 화면 - AppBar
class TodayRecommendationAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const TodayRecommendationAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final textTheme = Theme.of(context).textTheme;

    return PreferredSize(
      preferredSize: preferredSize,
      child: SafeArea(
        child: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          titleSpacing: responsive.horizontalPadding(),
          centerTitle: false,
          title: _buildTitle(context, responsive, textTheme),
          actions: _buildActions(context, ref, responsive),
        ),
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Semantics(
        header: true,
        label: '앱 제목: 이거 먹자!',
        child: Text(
          '이거 먹자!',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: responsive.appBarFontSize(),
            fontFamily: 'SCDream',
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    Responsive responsive,
  ) {
    return [
      IconButton(
        icon: Icon(
          Icons.notifications_outlined,
          size: responsive.iconSize(),
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => SettingsSheet.show(context),
        tooltip: '알림 설정',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      IconButton(
        icon: Icon(
          Icons.analytics,
          size: responsive.iconSize(),
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const UserStatsDialog(),
        ),
        tooltip: '내 식습관 통계',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      IconButton(
        icon: Icon(
          Icons.rate_review,
          size: responsive.iconSize(),
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReviewScreen(
              food: FoodRecommendation(
                name: AppConstants.defaultFoodName,
                imageUrl: AppConstants.defaultFoodImage,
              ),
              category: '기타',
            ),
          ),
        ),
        tooltip: '리뷰 작성',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
    ];
  }
}
