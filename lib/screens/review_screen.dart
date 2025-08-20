import 'package:reviewai_flutter/config/app_constants.dart';
import 'package:reviewai_flutter/config/security_config.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:reviewai_flutter/providers/review_provider.dart';
import 'package:reviewai_flutter/providers/food_providers.dart';
import 'package:reviewai_flutter/screens/review_selection_screen.dart';
import 'package:reviewai_flutter/screens/history_screen.dart';
import 'package:reviewai_flutter/services/gemini_service.dart';
import 'package:reviewai_flutter/screens/today_recommendation_screen.dart';

final isPickingImageProvider = StateProvider<bool>((ref) => false);

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
    if (_rewardedAd != null) return;

    RewardedAd.load(
      adUnitId: _getAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _configureAdCallbacks(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
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
        _generateReviews();
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
    final screenSize = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(reviewLoadingProvider);

    ref.listen(foodNameProvider, (prev, next) {
      if (_foodNameController.text != next) {
        _foodNameController.text = next;
      }
    });

    return PopScope(
      canPop: !isLoading,
      onPopInvoked: (didPop) {
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
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _navigateToHistoryScreen(),
          tooltip: '히스토리',
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
            _buildImageUploadSection(screenSize),
            SizedBox(height: screenSize.height * 0.03),
            _buildFoodNameInput(screenSize),
            SizedBox(height: screenSize.height * 0.02),
            ..._buildRatingRows(),
            SizedBox(height: screenSize.height * 0.03),
            _buildReviewStyleSection(textTheme, screenSize.width),
            SizedBox(height: screenSize.height * 0.03),
            _buildGenerateButton(screenSize, isLoading),
            SizedBox(height: screenSize.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(Size screenSize) {
    final image = ref.watch(imageProvider);
    final isPicking = ref.watch(isPickingImageProvider);

    return GestureDetector(
      onTap: isPicking ? null : _pickImage,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBDBDBD), width: 2),
            borderRadius: BorderRadius.circular(15),
            color: const Color(0xFFF1F1F1),
          ),
          child: _buildImageContent(image, screenSize.width, isPicking),
        ),
      ),
    );
  }

  Widget _buildImageContent(
    File? imageFile,
    double screenWidth,
    bool isPicking,
  ) {
    if (isPicking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (imageFile == null || !imageFile.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: screenWidth * 0.1,
              color: Colors.grey.shade600,
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              '이미지 업로드',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                fontFamily: 'Do Hyeon',
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFoodNameInput(Size screenSize) {
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

  List<Widget> _buildRatingRows() {
    return [
      _buildRatingRow(
        '배달',
        ref.watch(deliveryRatingProvider),
        (r) => ref.read(deliveryRatingProvider.notifier).state = r,
      ),
      _buildRatingRow(
        '맛',
        ref.watch(tasteRatingProvider),
        (r) => ref.read(tasteRatingProvider.notifier).state = r,
      ),
      _buildRatingRow(
        '양',
        ref.watch(portionRatingProvider),
        (r) => ref.read(portionRatingProvider.notifier).state = r,
      ),
      _buildRatingRow(
        '가격',
        ref.watch(priceRatingProvider),
        (r) => ref.read(priceRatingProvider.notifier).state = r,
      ),
    ];
  }

  Widget _buildRatingRow(String label, double rating, Function(double) onRate) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth * 0.12,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.04,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onRate((index + 1).toDouble()),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                    ),
                    child: Icon(
                      Icons.star,
                      color: index < rating
                          ? Colors.amber
                          : Colors.grey.shade300,
                      size: screenWidth * 0.07,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStyleSection(TextTheme textTheme, double screenWidth) {
    final reviewStyles = ref.watch(reviewStylesProvider);
    final selectedStyle = ref.watch(selectedReviewStyleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '리뷰 스타일',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Do Hyeon',
            fontSize: screenWidth * 0.045,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: reviewStyles.map((style) {
            return ChoiceChip(
              label: Text(
                style,
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: screenWidth * 0.035,
                ),
              ),
              selected: selectedStyle == style,
              onSelected: (isSelected) {
                if (isSelected) {
                  ref.read(selectedReviewStyleProvider.notifier).state = style;
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(Size screenSize, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: screenSize.height * 0.065 < 50 ? 50 : screenSize.height * 0.065,
      child: ElevatedButton(
        onPressed: (isLoading || _isProcessing) ? null : _handleGenerateReview,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _pickImage() async {
    if (ref.read(isPickingImageProvider)) return;

    ref.read(isPickingImageProvider.notifier).state = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        ref.read(imageProvider.notifier).state = File(picked.path);
      }
    } catch (e) {
      _showErrorSnackBar('이미지 선택에 실패했습니다.');
    } finally {
      if (mounted) {
        ref.read(isPickingImageProvider.notifier).state = false;
      }
    }
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
        await GeminiService.validateImage(imageFile);
      }

      // 2. Show Ad (if all validations passed)
      ref.read(reviewLoadingProvider.notifier).state =
          false; // Hide loading before showing ad

      if (_rewardedAd != null) {
        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {
            _generateReviews();
          },
        );
        _rewardedAd = null;
      } else {
        _generateReviews();
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
      _showValidationDialog();
      return false;
    }
    return true;
  }

  void _showValidationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          '입력 오류',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            '모든 입력을 완료해주세요.',
            style: TextStyle(fontFamily: 'Do Hyeon', fontSize: 16),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(fontFamily: 'Do Hyeon')),
          ),
        ],
      ),
    );
  }

  void _generateReviews() async {
    ref.read(reviewLoadingProvider.notifier).state = true;

    try {
      final reviews = await GeminiService.generateReviews(
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
      _showImageErrorDialog(errorMessage);
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

  void _showImageErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text(
          '이미지 오류',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            style: const TextStyle(fontFamily: 'Do Hyeon', fontSize: 16),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(fontFamily: 'Do Hyeon')),
          ),
        ],
      ),
    );
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
