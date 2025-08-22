import 'package:eat_this_app/config/app_constants.dart';
import 'package:eat_this_app/config/security_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:eat_this_app/providers/review_provider.dart';
import 'package:eat_this_app/providers/food_providers.dart';
import 'package:eat_this_app/screens/review_selection_screen.dart';
import 'package:eat_this_app/screens/history_screen.dart';
import 'package:eat_this_app/services/gemini_service.dart';
import 'package:eat_this_app/screens/today_recommendation_screen.dart';
import 'package:eat_this_app/widgets/review/image_upload_section.dart';
import 'package:eat_this_app/widgets/review/rating_row.dart';
import 'package:eat_this_app/widgets/review/review_style_section.dart';
import 'package:eat_this_app/widgets/dialogs/review_dialogs.dart';
import 'package:eat_this_app/main.dart';

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
  int _adLoadAttempts = 0;
  static const int _maxAdLoadAttempts = 3;
  static const Duration _adRetryDelay = Duration(seconds: 3);

  // Responsive variables
  late double screenWidth;
  late double screenHeight;
  late bool isTablet;
  late bool isSmallScreen;
  late double appBarFontSize;
  late double inputFontSize;
  late double buttonFontSize;
  late double horizontalPadding;
  late double verticalSpacing;
  late double buttonHeight;

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

  void _calculateResponsiveSizes() {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isTablet = screenWidth >= 768;
    isSmallScreen = screenWidth < 600;

    // Dynamic font sizes
    appBarFontSize = (screenWidth * (isTablet ? 0.032 : 0.05)).clamp(
      16.0,
      28.0,
    );
    inputFontSize = (screenWidth * (isTablet ? 0.028 : 0.04)).clamp(14.0, 20.0);
    buttonFontSize = (screenWidth * (isTablet ? 0.03 : 0.04)).clamp(14.0, 22.0);

    // Dynamic spacing and padding
    horizontalPadding = (screenWidth * (isTablet ? 0.06 : 0.04)).clamp(
      16.0,
      48.0,
    );
    verticalSpacing = (screenHeight * (isTablet ? 0.025 : 0.02)).clamp(
      12.0,
      24.0,
    );

    // Button height with constraints
    buttonHeight = (screenHeight * (isTablet ? 0.07 : 0.065)).clamp(48.0, 72.0);
  }

  void _loadAd() {
    if (_rewardedAd != null) {
      _adLoadAttempts = 0;
      return;
    }

    RewardedAd.load(
      adUnitId: _getAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _configureAdCallbacks(ad);
          _adLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _adLoadAttempts++;
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
        _showAdErrorDialog('광고 로드에 실패했습니다. 잠시 후 다시 시도해주세요.');
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
    _calculateResponsiveSizes();
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
            backgroundColor: Colors.white,
            appBar: _buildAppBar(textTheme),
            body: _buildBody(textTheme, isLoading),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TextTheme textTheme) {
    final iconSize = (screenWidth * (isTablet ? 0.04 : 0.06)).clamp(20.0, 32.0);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        '리뷰 AI',
        style: textTheme.headlineMedium?.copyWith(
          fontSize: appBarFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Do Hyeon',
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: iconSize),
        onPressed: () => _navigateToRecommendationScreen(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, size: iconSize),
          onPressed: () => _navigateToHistoryScreen(),
          tooltip: '히스토리',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildBody(TextTheme textTheme, bool isLoading) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: verticalSpacing),

              // Image upload with responsive sizing
              Container(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * (isTablet ? 0.3 : 0.25),
                ),
                child: const ImageUploadSection(),
              ),

              SizedBox(height: verticalSpacing * 1.5),
              _buildFoodNameInput(),
              SizedBox(height: verticalSpacing),

              // Rating rows with responsive spacing
              Column(
                children: [
                  RatingRow(
                    label: '배달',
                    rating: ref.watch(deliveryRatingProvider),
                    onRate: (r) {
                      debugPrint('배달 rating updated to: $r');
                      ref.read(deliveryRatingProvider.notifier).state = r;
                    },
                  ),
                  SizedBox(height: verticalSpacing * 0.25),
                  RatingRow(
                    label: '맛',
                    rating: ref.watch(tasteRatingProvider),
                    onRate: (r) {
                      debugPrint('맛 rating updated to: $r');
                      ref.read(tasteRatingProvider.notifier).state = r;
                    },
                  ),
                  SizedBox(height: verticalSpacing * 0.25),
                  RatingRow(
                    label: '양',
                    rating: ref.watch(portionRatingProvider),
                    onRate: (r) {
                      debugPrint('양 rating updated to: $r');
                      ref.read(portionRatingProvider.notifier).state = r;
                    },
                  ),
                  SizedBox(height: verticalSpacing * 0.25),
                  RatingRow(
                    label: '가격',
                    rating: ref.watch(priceRatingProvider),
                    onRate: (r) {
                      debugPrint('가격 rating updated to: $r');
                      ref.read(priceRatingProvider.notifier).state = r;
                    },
                  ),
                ],
              ),

              SizedBox(height: verticalSpacing * 1.5),
              const ReviewStyleSection(),
              SizedBox(height: verticalSpacing * 1.5),
              _buildGenerateButton(isLoading),
              SizedBox(height: verticalSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodNameInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
        border: Border.all(
          color: const Color(0xFFBDBDBD), // Matched image upload border color
          width: isTablet ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        controller: _foodNameController,
        maxLength: AppConstants.maxFoodNameLength,
        onChanged: (text) => ref.read(foodNameProvider.notifier).state = text,
        style: TextStyle(fontFamily: 'Do Hyeon', fontSize: inputFontSize),
        decoration: InputDecoration(
          labelText: '음식명을 입력해주세요',
          counterText: "",
          labelStyle: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: inputFontSize * 0.9,
            color: Colors.grey.shade600,
          ),
          border: InputBorder.none, // Keep no border for the TextField itself
          focusedBorder: InputBorder.none, // Ensure no border when focused
          enabledBorder: InputBorder.none, // Ensure no border when enabled
          contentPadding: EdgeInsets.all(
            (screenWidth * (isTablet ? 0.04 : 0.035)).clamp(12.0, 20.0),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
        boxShadow: [
          if (!isLoading && !_isProcessing)
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: isTablet ? 8.0 : 6.0,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (isLoading || _isProcessing) ? null : _handleGenerateReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: (isLoading || _isProcessing)
              ? Colors.grey.shade400
              : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
          ),
          padding: EdgeInsets.symmetric(
            vertical: (screenHeight * 0.015).clamp(8.0, 16.0),
          ),
        ),
        child: Text(
          '리뷰 생성하기',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: isTablet ? 4.0 : 3.0,
              ),
              SizedBox(height: verticalSpacing),
              Text(
                '리뷰를 생성하고 있습니다...',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Do Hyeon',
                  fontSize: inputFontSize,
                ),
              ),
            ],
          ),
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
      final imageFile = ref.read(imageProvider);
      if (imageFile != null) {
        await ref.read(geminiServiceProvider).validateImage(imageFile);
      }

      ref.read(reviewLoadingProvider.notifier).state = false;

      if (kDebugMode) {
        _generateReviews();
      } else if (_rewardedAd != null) {
        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            _generateReviews();
          },
        );
        _rewardedAd = null;
      } else {
        if (_adLoadAttempts < _maxAdLoadAttempts) {
          _showAdErrorDialog(
            '광고가 준비되지 않았습니다. 잠시 후 다시 시도합니다. (${_adLoadAttempts + 1}/$_maxAdLoadAttempts)',
          );
          await Future.delayed(_adRetryDelay);
          _loadAd();
        } else {
          _showAdErrorDialog('광고 로드에 실패하여 리뷰 생성을 진행합니다.');
          _adLoadAttempts = 0;
          _generateReviews();
        }
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
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
      showValidationDialog(context, Size(screenWidth, screenHeight));
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
        _showAdErrorDialog('리뷰 생성에 실패했습니다. 다시 시도해주세요.');
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
      showImageErrorDialog(
        context,
        errorMessage,
        Size(screenWidth, screenHeight),
      );
    } else {
      _showAdErrorDialog(errorMessage);
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

  void _showAdErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
          ),
          title: Text(
            '알림',
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: (screenWidth * (isTablet ? 0.035 : 0.045)).clamp(
                16.0,
                24.0,
              ),
            ),
          ),
          content: Text(
            message,
            style: TextStyle(fontFamily: 'Do Hyeon', fontSize: inputFontSize),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '확인',
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: inputFontSize,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
