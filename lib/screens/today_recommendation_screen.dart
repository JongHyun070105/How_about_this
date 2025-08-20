import 'package:reviewai_flutter/config/app_constants.dart';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reviewai_flutter/providers/food_providers.dart';
import 'package:reviewai_flutter/screens/review_screen.dart';
import 'package:reviewai_flutter/services/notification_service.dart';

// 로딩 상태를 관리하는 Provider
final isCategoryLoadingProvider = StateProvider<bool>((ref) => false);

class TodayRecommendationScreen extends ConsumerWidget {
  const TodayRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodCategories = ref.watch(foodCategoriesProvider);
    final isCategoryLoading = ref.watch(isCategoryLoadingProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textTheme = Theme.of(context).textTheme;

    FoodRecommendation pickRandomFood(
      List<FoodRecommendation> foods,
      List<String> recentFoods,
    ) {
      if (foods.isEmpty) {
        throw Exception("추천 가능한 음식이 없습니다.");
      }

      List<FoodRecommendation> available = foods
          .where((f) => !recentFoods.contains(f.name))
          .toList();

      if (available.isEmpty) {
        recentFoods.clear();
        available = List.from(foods);
      }

      final chosen = available[Random().nextInt(available.length)];

      recentFoods.add(chosen.name);
      if (recentFoods.length > AppConstants.recentFoodsLimit) {
        recentFoods.removeAt(0);
      }
      return chosen;
    }

    void showRecommendationDialog(
      BuildContext context, {
      required String category,
      required List<FoodRecommendation> foods,
      required Color color,
    }) {
      final recentFoods = <String>[];

      void openDialog() {
        final recommended = pickRandomFood(foods, recentFoods);
        ref.read(selectedFoodProvider.notifier).state = recommended;

        showDialog(
          context: context,
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
              recommended: recommended,
              foods: foods,
              color: color,
              onRecommendAgain: () {
                Navigator.pop(context);
                openDialog();
              },
            ),
          ),
        );
      }

      openDialog();
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              '오늘 뭐 먹지?',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
                fontFamily: 'Do Hyeon',
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.rate_review),
                onPressed: () =>
                    _navigateToReviewScreen(context, _createDefaultFood()),
                tooltip: '리뷰 작성',
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.02),
                Text(
                  '카테고리를 선택해주세요',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                    fontSize: screenWidth * 0.05,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenHeight * 0.02,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: foodCategories.length,
                    itemBuilder: (context, index) {
                      final category = foodCategories[index];

                      return Hero(
                        tag: 'category_${category.name}_$index',
                        child: GestureDetector(
                          onTap: () => _handleCategoryTap(
                            context,
                            ref,
                            category,
                            showRecommendationDialog,
                          ),
                          child: AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Card(
                              color: category.color,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: screenHeight * 0.17,
                                    child: SvgPicture.asset(
                                      category.imageUrl,
                                      fit: BoxFit.contain,
                                      width: screenWidth * 0.22,
                                      height: screenWidth * 0.22,
                                      placeholderBuilder: (context) =>
                                          Container(
                                            color: Colors.grey.shade200,
                                            child: Center(
                                              child: Icon(
                                                Icons.image,
                                                size: screenWidth * 0.17,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.0005,
                                      horizontal: screenWidth * 0.02,
                                    ),
                                    child: Text(
                                      category.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Do Hyeon',
                                        fontSize: screenWidth * 0.045,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
        if (isCategoryLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  FoodRecommendation _createDefaultFood() {
    return FoodRecommendation(
      name: AppConstants.defaultFoodName,
      imageUrl: AppConstants.defaultFoodImage,
    );
  }

  void _navigateToReviewScreen(BuildContext context, FoodRecommendation food) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReviewScreen(food: food),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _handleCategoryTap(
    BuildContext context,
    WidgetRef ref,
    FoodCategory category,
    Function(
      BuildContext, {
      required String category,
      required List<FoodRecommendation> foods,
      required Color color,
    })
    showDialogFn,
  ) async {
    if (ref.read(isCategoryLoadingProvider)) return;

    ref.read(isCategoryLoadingProvider.notifier).state = true;
    try {
      ref.read(selectedCategoryProvider.notifier).state = category.name;
      ref.read(selectedFoodProvider.notifier).state = null;

      final foods = await ref.read(
        recommendationProvider(category.name).future,
      );

      if (foods.isNotEmpty) {
        showDialogFn(
          context,
          category: category.name,
          foods: foods,
          color: category.color,
        );
      } else {
        _showErrorSnackBar(context, '추천을 불러오지 못했습니다.');
      }
    } catch (e) {
      _showErrorSnackBar(context, '오류가 발생했습니다: $e');
    } finally {
      ref.read(isCategoryLoadingProvider.notifier).state = false;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class FoodRecommendationDialog extends StatefulWidget {
  final String category;
  final FoodRecommendation recommended;
  final List<FoodRecommendation> foods;
  final Color color;
  final VoidCallback onRecommendAgain;

  const FoodRecommendationDialog({
    super.key,
    required this.category,
    required this.recommended,
    required this.foods,
    required this.color,
    required this.onRecommendAgain,
  });

  @override
  State<FoodRecommendationDialog> createState() =>
      _FoodRecommendationDialogState();
}

class _FoodRecommendationDialogState extends State<FoodRecommendationDialog>
    with TickerProviderStateMixin {
  late AnimationController _rouletteController;
  late AnimationController _scaleController;
  late ConfettiController _confettiController;
  late Animation<double> _rouletteAnimation;
  late Animation<double> _scaleAnimation;

  String _displayText = '?';
  bool _isSpinning = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _initializeAnimations();
    _startRouletteAnimation();
  }

  void _initializeAnimations() {
    _rouletteController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rouletteAnimation = CurvedAnimation(
      parent: _rouletteController,
      curve: Curves.easeOutQuart,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  void _startRouletteAnimation() {
    final allFoods = widget.foods.map((f) => f.name).toList();
    allFoods.shuffle();
    final spinnerFoods = allFoods.take(5).toList();

    int spinnerIndex = 0;
    _rouletteController.addListener(() {
      if (_isSpinning) {
        if (!mounted) return;
        setState(() {
          _displayText = spinnerFoods[spinnerIndex % spinnerFoods.length];
          spinnerIndex++;
        });
      }
    });

    _rouletteController.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _isSpinning = false;
        _displayText = widget.recommended.name;
      });
      _scaleController.forward();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _rouletteController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _showPostRecommendationInfo(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('팁!', style: TextStyle(fontFamily: 'Do Hyeon')),
        content: const Text(
          '좋아요! 맛있게 드시고, 나중에 상단의 리뷰 작성 아이콘을 눌러 AI에게 리뷰를 맡겨보세요!',
          style: TextStyle(fontFamily: 'Do Hyeon'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인', style: TextStyle(fontFamily: 'Do Hyeon')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = HSLColor.fromColor(
      widget.color,
    ).withLightness(0.25).toColor();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.only(
            left: 20,
            right: 8,
            top: 18,
            bottom: 8,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '🍽️ 오늘의 ${widget.category} 추천!',
                  style: const TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.color, widget.color.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isSpinning ? 1.0 : _scaleAnimation.value,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 1500),
                                child: Transform.scale(
                                  scale: _isSpinning
                                      ? 1.0
                                      : _scaleAnimation.value,
                                  child: Text(
                                    _displayText,
                                    style: TextStyle(
                                      fontFamily: 'Do Hyeon',
                                      fontSize: _isSpinning ? 24 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: _isSpinning
                                          ? Colors.grey.shade600
                                          : textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: TextButton.icon(
                        onPressed: _isSpinning ? null : widget.onRecommendAgain,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text(
                          '재추천',
                          style: TextStyle(fontFamily: 'Do Hyeon'),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!_isSpinning) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            '어떠세요? 🤤',
                            style: TextStyle(
                              fontFamily: 'Do Hyeon',
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showPostRecommendationInfo(context);

                              final scheduledTime = DateTime.now().add(
                                const Duration(minutes: 90),
                              );
                              NotificationService.scheduleNotification(
                                id: 0,
                                title: '리뷰 작성 알림',
                                body:
                                    '오늘 드신 ${widget.recommended.name} 어떠셨나요? AI에게 리뷰를 맡겨보세요!',
                                scheduledDate: scheduledTime,
                                payload: 'review_notification',
                              );
                            },
                            icon: const Icon(Icons.thumb_up, size: 18),
                            label: const Text(
                              '좋아요!',
                              style: TextStyle(fontFamily: 'Do Hyeon'),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: null,
        ),
        Align(
          alignment: const Alignment(0.0, -0.6),
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            emissionFrequency: 0.03,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
            createParticlePath: (size) {
              final path = Path();
              path.addOval(Rect.fromCircle(center: Offset.zero, radius: 7));
              return path;
            },
          ),
        ),
      ],
    );
  }
}
