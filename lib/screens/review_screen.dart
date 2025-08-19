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

class ReviewScreen extends ConsumerStatefulWidget {
  final FoodRecommendation food;

  const ReviewScreen({super.key, required this.food});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  RewardedAd? _rewardedAd;
  final TextEditingController _foodNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedFood = widget.food;
      _foodNameController.text = selectedFood.name;
      ref.read(foodNameProvider.notifier).state = selectedFood.name;
    });
    _loadAd();
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void _showAdAndGenerateReview(BuildContext context) {
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
      if (!context.mounted) return;
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
            textAlign: TextAlign.center,
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              '모든 입력을 완료해주세요.',
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '확인',
                style: TextStyle(fontFamily: 'Do Hyeon', color: Colors.red),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_rewardedAd == null) {
      _generateReviews(context);
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadAd();
        _generateReviews(context);
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => _generateReviews(context),
    );

    _rewardedAd = null;
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Widget _buildSafeImage(File? imageFile, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (imageFile == null || !imageFile.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: width * 0.1,
              color: Colors.grey.shade600,
            ),
            SizedBox(height: width * 0.02),
            Text(
              '이미지 업로드',
              style: TextStyle(
                fontSize: width * 0.04,
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final image = ref.watch(imageProvider);
    final reviewStyles = ref.watch(reviewStylesProvider);
    final selectedStyle = ref.watch(selectedReviewStyleProvider);
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(reviewLoadingProvider);

    ref.listen(foodNameProvider, (prev, next) {
      if (_foodNameController.text != next) _foodNameController.text = next;
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              '리뷰 AI',
              style: textTheme.headlineMedium?.copyWith(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                fontFamily: 'Do Hyeon',
              ),
            ),
            centerTitle: true,
            toolbarHeight: height * 0.07,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.restaurant_menu),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TodayRecommendationScreen(),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: height * 0.02),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          ref.read(imageProvider.notifier).state = File(
                            picked.path,
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '이미지 선택에 실패했습니다.',
                              style: TextStyle(fontFamily: 'Do Hyeon'),
                            ),
                          ),
                        );
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFBDBDBD),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          color: const Color(0xFFF1F1F1),
                        ),
                        child: _buildSafeImage(image, context),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  TextField(
                    controller: _foodNameController,
                    onChanged: (text) =>
                        ref.read(foodNameProvider.notifier).state = text,
                    decoration: InputDecoration(
                      labelText: '음식명을 입력해주세요',
                      labelStyle: Theme.of(context)
                          .inputDecorationTheme
                          .labelStyle
                          ?.copyWith(fontFamily: 'Do Hyeon'),
                    ),
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: width * 0.04,
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  _buildRatingRow(
                    '배달',
                    ref.watch(deliveryRatingProvider),
                    (r) => ref.read(deliveryRatingProvider.notifier).state = r,
                    context,
                  ),
                  _buildRatingRow(
                    '맛',
                    ref.watch(tasteRatingProvider),
                    (r) => ref.read(tasteRatingProvider.notifier).state = r,
                    context,
                  ),
                  _buildRatingRow(
                    '양',
                    ref.watch(portionRatingProvider),
                    (r) => ref.read(portionRatingProvider.notifier).state = r,
                    context,
                  ),
                  _buildRatingRow(
                    '가격',
                    ref.watch(priceRatingProvider),
                    (r) => ref.read(priceRatingProvider.notifier).state = r,
                    context,
                  ),
                  SizedBox(height: height * 0.03),
                  Text(
                    '리뷰 스타일',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Do Hyeon',
                      fontSize: width * 0.045,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: reviewStyles.map((style) {
                      return ChoiceChip(
                        label: Text(
                          style,
                          style: TextStyle(
                            fontFamily: 'Do Hyeon',
                            fontSize: width * 0.035,
                          ),
                        ),
                        selected: selectedStyle == style,
                        onSelected: (isSelected) {
                          if (isSelected) {
                            ref
                                    .read(selectedReviewStyleProvider.notifier)
                                    .state =
                                style;
                          }
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: height * 0.03),
                  SizedBox(
                    width: double.infinity,
                    height: height * 0.065 < 50 ? 50 : height * 0.065,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _showAdAndGenerateReview(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '리뷰 생성하기',
                        style: TextStyle(
                          fontFamily: 'Do Hyeon',
                          fontSize: width * 0.04,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingRow(
    String label,
    double rating,
    Function(double) onRate,
    BuildContext context,
  ) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: width * 0.12,
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Do Hyeon', fontSize: width * 0.04),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onRate((index + 1).toDouble()),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.01),
                    child: Icon(
                      Icons.star,
                      color: index < rating
                          ? Colors.amber
                          : Colors.grey.shade300,
                      size: width * 0.07,
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

  void _generateReviews(BuildContext context) async {
    final foodName = ref.read(foodNameProvider);
    final delivery = ref.read(deliveryRatingProvider);
    final taste = ref.read(tasteRatingProvider);
    final portion = ref.read(portionRatingProvider);
    final price = ref.read(priceRatingProvider);

    ref.read(reviewLoadingProvider.notifier).state = true;

    try {
      final reviews = await GeminiService.generateReviews(
        foodName: foodName,
        deliveryRating: delivery,
        tasteRating: taste,
        portionRating: portion,
        priceRating: price,
        reviewStyle: ref.read(selectedReviewStyleProvider),
      );

      ref.read(generatedReviewsProvider.notifier).state = reviews;
      ref.read(reviewLoadingProvider.notifier).state = false;

      if (!context.mounted) return;
      if (reviews.isNotEmpty && !reviews.first.contains('오류')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReviewSelectionScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '리뷰 생성에 실패했습니다. 다시 시도해주세요.',
              style: TextStyle(fontFamily: 'Do Hyeon'),
            ),
          ),
        );
      }
    } catch (e) {
      ref.read(reviewLoadingProvider.notifier).state = false;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '오류가 발생했습니다: $e',
            style: const TextStyle(fontFamily: 'Do Hyeon'),
          ),
        ),
      );
    }
  }
}
