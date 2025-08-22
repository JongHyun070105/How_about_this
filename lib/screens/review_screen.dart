import 'package:reviewai_flutter/config/app_constants.dart';
import 'package:reviewai_flutter/config/security_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:reviewai_flutter/providers/review_provider.dart';
import 'package:reviewai_flutter/providers/food_providers.dart';
import 'package:reviewai_flutter/screens/review_selection_screen.dart';
import 'package:reviewai_flutter/screens/history_screen.dart';
import 'package:reviewai_flutter/services/gemini_service.dart';
import 'package:reviewai_flutter/screens/today_recommendation_screen.dart';
import 'package:reviewai_flutter/widgets/review/image_upload_section.dart';
import 'package:reviewai_flutter/widgets/review/rating_row.dart';
import 'package:reviewai_flutter/widgets/review/review_style_section.dart';
import 'package:reviewai_flutter/widgets/dialogs/review_dialogs.dart';
import 'package:reviewai_flutter/main.dart'; // Add this import

class ReviewScreen extends ConsumerStatefulWidget {
  final FoodRecommendation food;

  const ReviewScreen({super.key, required this.food});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  RewardedAd? _rewardedAd;
  final TextEditingController _foodNameController = TextEditingController();
  bool _isProcessing = false;
  late Size screenSize;
  int _adLoadAttempts = 0; // 광고 로드 시도 횟수
  static const int _maxAdLoadAttempts = 3; // 최대 재시도 횟수
  static const Duration _adRetryDelay = Duration(seconds: 3); // 재시도 간 지연 시간

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _loadAd();
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedFood = widget.food;
      final isDefaultFood = selectedFood.name == AppConstants.defaultFoodName;

      final foodNameToSet = isDefaultFood ? '' : selectedFood.name;

      _foodNameController.text = foodNameToSet;
      ref.read(foodNameProvider.notifier).state = foodNameToSet;
    });
  }

  void _loadAd() {
    if (_rewardedAd != null) {
      _adLoadAttempts = 0; // 광고 로드 성공 시 시도 횟수 초기화
      return;
    }

    RewardedAd.load(
      adUnitId: _getAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _configureAdCallbacks(ad);
          _adLoadAttempts = 0; // 광고 로드 성공 시 시도 횟수 초기화
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _adLoadAttempts++; // 광고 로드 실패 시 시도 횟수 증가
          _showErrorSnackBar(
            '광고 로드 실패: ${error.message}',
          ); // Display error to user
        },
      ),
    );
  }

  String _getAdUnitId() {
    return SecurityConfig.rewardedAdUnitId;
  }

  void _configureAdCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadAd();
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadAd();
        _showErrorSnackBar('광고 로드에 실패했습니다. 잠시 후 다시 시도해주세요.'); // Inform user
      },
    );
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(reviewLoadingProvider);

    ref.listen(foodNameProvider, (prev, next) {
      if (_foodNameController.text != next) {
        _foodNameController.text = next;
      }
    });

    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          resetAllProviders(ref);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: _buildAppBar(textTheme, screenSize.width),
            body: _buildBody(screenSize, textTheme, isLoading),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TextTheme textTheme, double screenWidth) {
    return AppBar(
      title: Text(
        '리뷰 AI',
        style: textTheme.headlineMedium?.copyWith(
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
          fontFamily: 'Do Hyeon',
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _navigateToRecommendationScreen(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _navigateToHistoryScreen(),
          tooltip: '히스토리',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildBody(Size screenSize, TextTheme textTheme, bool isLoading) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: screenSize.height * 0.02),
            const ImageUploadSection(),
            SizedBox(height: screenSize.height * 0.03),
            _buildFoodNameInput(),
            SizedBox(height: screenSize.height * 0.02),
            RatingRow(
              label: '배달',
              rating: ref.watch(deliveryRatingProvider),
              onRate: (r) {
                debugPrint('배달 rating updated to: $r');
                ref.read(deliveryRatingProvider.notifier).state = r;
              },
            ),
            RatingRow(
              label: '맛',
              rating: ref.watch(tasteRatingProvider),
              onRate: (r) {
                debugPrint('맛 rating updated to: $r');
                ref.read(tasteRatingProvider.notifier).state = r;
              },
            ),
            RatingRow(
              label: '양',
              rating: ref.watch(portionRatingProvider),
              onRate: (r) {
                debugPrint('양 rating updated to: $r');
                ref.read(portionRatingProvider.notifier).state = r;
              },
            ),
            RatingRow(
              label: '가격',
              rating: ref.watch(priceRatingProvider),
              onRate: (r) {
                debugPrint('가격 rating updated to: $r');
                ref.read(priceRatingProvider.notifier).state = r;
              },
            ),
            SizedBox(height: screenSize.height * 0.03),
            const ReviewStyleSection(),
            SizedBox(height: screenSize.height * 0.03),
            _buildGenerateButton(isLoading),
            SizedBox(height: screenSize.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodNameInput() {
    return TextField(
      controller: _foodNameController,
      maxLength: AppConstants.maxFoodNameLength,
      onChanged: (text) => ref.read(foodNameProvider.notifier).state = text,
      decoration: InputDecoration(
        labelText: '음식명을 입력해주세요',
        counterText: "",
        labelStyle: Theme.of(
          context,
        ).inputDecorationTheme.labelStyle?.copyWith(fontFamily: 'Do Hyeon'),
      ),
      style: TextStyle(
        fontFamily: 'Do Hyeon',
        fontSize: screenSize.width * 0.04,
      ),
    );
  }

  Widget _buildGenerateButton(bool isLoading) {
    final double buttonHeight =
        screenSize.height * 0.065 < screenSize.height * 0.0625
        ? screenSize.height * 0.0625
        : screenSize.height * 0.065;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: (isLoading || _isProcessing) ? null : _handleGenerateReview,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.015),
        ),
        child: Text(
          '리뷰 생성하기',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: screenSize.width * 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }

  void _handleGenerateReview() async {
    if (_isProcessing) return;
    if (!_validateInputs()) return;

    setState(() {
      _isProcessing = true;
    });
    ref.read(reviewLoadingProvider.notifier).state = true;

    try {
      // 1. Image Validation (if image exists)
      final imageFile = ref.read(imageProvider);
      if (imageFile != null) {
        await ref.read(geminiServiceProvider).validateImage(imageFile);
      }

      // 2. Show Ad (if all validations passed)
      ref.read(reviewLoadingProvider.notifier).state =
          false; // Hide loading before showing ad

      if (kDebugMode) {
        // Debug mode: Bypass ad and directly generate reviews
        _generateReviews();
      } else if (_rewardedAd != null) {
        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            _generateReviews();
          },
        );
        _rewardedAd = null;
      } else {
        // 광고 로드 실패 시 재시도 로직
        if (_adLoadAttempts < _maxAdLoadAttempts) {
          _showErrorSnackBar(
            '광고가 준비되지 않았습니다. 잠시 후 다시 시도합니다. (${_adLoadAttempts + 1}/$_maxAdLoadAttempts)',
          );
          await Future.delayed(_adRetryDelay); // 일정 시간 대기
          _loadAd(); // 광고 재로드 시도
        } else {
          // 최대 재시도 횟수 초과 시 리뷰 생성 진행
          _showErrorSnackBar('광고 로드에 실패하여 리뷰 생성을 진행합니다.');
          _adLoadAttempts = 0; // 시도 횟수 초기화
          _generateReviews();
        }
        if (mounted) {
          setState(() {
            _isProcessing = false; // Reset processing state
          });
        }
      }
    } catch (e) {
      // 3. Handle all errors (from validation or image check)
      ref.read(reviewLoadingProvider.notifier).state = false;
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      _handleGenerationError(e);
    }
  }

  bool _validateInputs() {
    final foodName = ref.read(foodNameProvider);
    final delivery = ref.read(deliveryRatingProvider);
    final taste = ref.read(tasteRatingProvider);
    final portion = ref.read(portionRatingProvider);
    final price = ref.read(priceRatingProvider);

    if (foodName.isEmpty ||
        delivery == 0 ||
        taste == 0 ||
        portion == 0 ||
        price == 0) {
      showValidationDialog(context, screenSize);
      return false;
    }
    return true;
  }

  void _generateReviews() async {
    ref.read(reviewLoadingProvider.notifier).state = true;

    try {
      final reviews = await ref
          .read(geminiServiceProvider)
          .generateReviews(
            foodName: ref.read(foodNameProvider),
            deliveryRating: ref.read(deliveryRatingProvider),
            tasteRating: ref.read(tasteRatingProvider),
            portionRating: ref.read(portionRatingProvider),
            priceRating: ref.read(priceRatingProvider),
            reviewStyle: ref.read(selectedReviewStyleProvider),
            foodImage: ref.read(imageProvider),
          );

      ref.read(generatedReviewsProvider.notifier).state = reviews;

      if (_isSuccessfulGeneration(reviews)) {
        _navigateToReviewSelection();
      } else {
        _showErrorSnackBar('리뷰 생성에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      _handleGenerationError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      ref.read(reviewLoadingProvider.notifier).state = false;
    }
  }

  bool _isSuccessfulGeneration(List<String> reviews) {
    return reviews.isNotEmpty && !reviews.first.contains('오류');
  }

  void _handleGenerationError(dynamic error) {
    final errorString = error.toString();
    final errorMessage = _getErrorMessage(errorString);

    if (errorString.contains('부적절한 이미지') ||
        errorString.contains('이미지가 음식 리뷰에 적합하지 않습니다')) {
      showImageErrorDialog(context, errorMessage, screenSize);
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  String _getErrorMessage(String errorString) {
    if (errorString.contains('부적절한 이미지')) {
      return '업로드하신 이미지가 음식 사진이 아닙니다. 음식 사진을 업로드해주세요.';
    } else if (errorString.contains('이미지가 음식 리뷰에 적합하지 않습니다')) {
      return '음식을 명확히 식별할 수 있는 사진을 업로드해주세요.';
    } else {
      return '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  // 네비게이션 메서드들
  void _navigateToRecommendationScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TodayRecommendationScreen()),
      (route) => false,
    );
  }

  void _navigateToHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void _navigateToReviewSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewSelectionScreen()),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Do Hyeon')),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
