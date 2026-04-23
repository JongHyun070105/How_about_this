import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:review_ai/config/security_config.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/presentation/providers/app_providers.dart';
import 'package:review_ai/presentation/providers/food_providers.dart';
import 'package:review_ai/presentation/viewmodels/today_recommendation_viewmodel.dart';
import 'package:review_ai/presentation/widgets/common/app_dialogs.dart';
import 'package:review_ai/presentation/widgets/history/dialogs/food_recommendation_dialog.dart';
import 'package:review_ai/presentation/widgets/today_recommendation/today_recommendation_appbar.dart';
import 'package:review_ai/presentation/widgets/today_recommendation/today_recommendation_body.dart';
import 'package:review_ai/services/recommendation_service.dart';
import 'package:review_ai/services/user_preference_service.dart';
import 'package:review_ai/services/weather_service.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class TodayRecommendationScreen extends ConsumerStatefulWidget {
  const TodayRecommendationScreen({super.key});

  @override
  ConsumerState<TodayRecommendationScreen> createState() =>
      _TodayRecommendationScreenState();
}

class _TodayRecommendationScreenState
    extends ConsumerState<TodayRecommendationScreen> {
  final List<String> _loadingMessages = [
    '음식 추천 중...',
    '맛있는 메뉴 찾는 중...',
    'AI가 고민 중...',
    '오늘의 메뉴를 골라볼게요...',
  ];
  int _currentMessageIndex = 0;
  Timer? _messageRotationTimer;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  WeatherCondition? _currentWeather;
  String _weatherMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) return;
      }

      final position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          ).catchError((e) {
            debugPrint('Location fetch timeout or error: $e');
            return Position(
              longitude: 127.0,
              latitude: 37.5,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          });

      final weather = await WeatherService().getCurrentWeather(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _weatherMessage = _getWeatherMessage(weather);
        });
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
    }
  }

  String _getWeatherMessage(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.rain:
      case WeatherCondition.drizzle:
      case WeatherCondition.thunderstorm:
        return '비가 오네요 ☔ 뜨끈한 국물이나 파전 어때요?';
      case WeatherCondition.snow:
        return '눈이 내려요 ❄️ 따뜻한 전골 요리 추천해요!';
      case WeatherCondition.clear:
        return '날씨가 참 좋네요 ☀️ 시원한 냉면이나 아이스 커피?';
      case WeatherCondition.clouds:
        return '구름 낀 날 ☁️ 기분 전환할 맛있는 음식!';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _messageRotationTimer?.cancel();
    super.dispose();
  }

  void _startLoadingMessageRotation() {
    _currentMessageIndex = 0;
    _messageRotationTimer?.cancel();
    _messageRotationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  void _stopLoadingMessageRotation() {
    _messageRotationTimer?.cancel();
    _messageRotationTimer = null;
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: SecurityConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {
          _bannerAd = ad as BannerAd;
          _isBannerAdLoaded = true;
        }),
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          setState(() => _isBannerAdLoaded = false);
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isLoading = ref.watch(todayRecommendationViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: const TodayRecommendationAppBar(),
          body: TodayRecommendationBody(
            weatherMessage: _weatherMessage,
            currentWeather: _currentWeather,
            bannerAd: _bannerAd,
            isBannerAdLoaded: _isBannerAdLoaded,
            onShowRecommendationDialog: _showRecommendationDialog,
            onStartLoadingRotation: _startLoadingMessageRotation,
            onStopLoadingRotation: _stopLoadingMessageRotation,
          ),
        ),
        if (isLoading) _buildLoadingOverlay(responsive, textTheme),
      ],
    );
  }

  Widget _buildLoadingOverlay(Responsive responsive, TextTheme textTheme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: responsive.iconSize() * 2,
              height: responsive.iconSize() * 2,
              child: Semantics(
                label: '음식 추천 중',
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4,
                ),
              ),
            ),
            SizedBox(height: responsive.verticalSpacing()),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Semantics(
                liveRegion: true,
                label: '상태: ${_loadingMessages[_currentMessageIndex]}',
                child: Text(
                  _loadingMessages[_currentMessageIndex],
                  key: ValueKey<int>(_currentMessageIndex),
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SCDream',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecommendationDialog(
    BuildContext context, {
    required String category,
    required List<FoodRecommendation> foods,
    required Color color,
  }) {
    void openDialog() async {
      final history = await UserPreferenceService.getFoodSelectionHistory();
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentFoods = history
          .where((s) => s.selectedAt.isAfter(sevenDaysAgo))
          .map((s) => s.foodName)
          .toSet()
          .toList();

      final analysis = await UserPreferenceService.analyzeUserPreferences();
      final resultTuple = RecommendationService.pickSmartFood(
        foods,
        recentFoods,
        analysis,
        weather: _currentWeather,
      );

      ref.read(selectedFoodProvider.notifier).state = resultTuple.food;

      if (!context.mounted) return;

      final result = await showDialog<dynamic>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        builder: (_) => SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.easeOutBack,
                ),
              ),
          child: FoodRecommendationDialog(
            category: category,
            recommended: resultTuple.food,
            foods: foods,
            color: color,
            reason: resultTuple.reason,
          ),
        ),
      );

      if (!context.mounted) return;
      await _handleDialogResult(context, result, openDialog);
    }

    openDialog();
  }

  Future<void> _handleDialogResult(
    BuildContext context,
    dynamic result,
    VoidCallback openDialog,
  ) async {
    if (!context.mounted) return;
    if (result == 'search') return;

    if (result == true) {
      final usageTrackingService = ref.read(usageTrackingServiceProvider);
      final hasReachedLimit = await usageTrackingService
          .hasReachedTotalRecommendationLimit();

      if (hasReachedLimit && context.mounted) {
        showAppDialog(
          context,
          title: '일일 추천 한도 초과',
          message: '오늘의 음식 추천 한도에 도달했습니다. 내일 다시 이용해주세요!',
        );
        return;
      }

      await usageTrackingService.incrementTotalRecommendationCount();
      if (context.mounted) openDialog();
    } else {
      await _showReviewPromptIfNeeded(context);
    }
  }

  Future<void> _showReviewPromptIfNeeded(BuildContext context) async {
    final usageTrackingService = ref.read(usageTrackingServiceProvider);
    final currentCount = await usageTrackingService
        .getTotalRecommendationCount();
    if (_shouldShowReviewPrompt(currentCount) && context.mounted) {
      showAppDialog(
        context,
        title: '리뷰 작성 팁!',
        message:
            '추천된 음식이 마음에 드셨나요? 드신 후, 상단의 리뷰 작성 버튼을 눌러 AI를 활용해서 리뷰를 작성해보세요!',
      );
    }
  }

  bool _shouldShowReviewPrompt(int count) =>
      count == 1 || count == 10 || count == 20 || count == 40;
}
