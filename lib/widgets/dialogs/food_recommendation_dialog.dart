


import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eat_this_app/providers/food_providers.dart';
import 'package:eat_this_app/services/user_preference_service.dart';

class FoodRecommendationDialog extends ConsumerStatefulWidget {
  final String category;
  final FoodRecommendation recommended;
  final List<FoodRecommendation> foods;
  final Color color;

  const FoodRecommendationDialog({
    super.key,
    required this.category,
    required this.recommended,
    required this.foods,
    required this.color,
  });

  @override
  ConsumerState<FoodRecommendationDialog> createState() =>
      _FoodRecommendationDialogState();
}

class _FoodRecommendationDialogState
    extends ConsumerState<FoodRecommendationDialog>
    with TickerProviderStateMixin {
  late AnimationController _rouletteController;
  late AnimationController _scaleController;
  late ConfettiController _confettiController;
  
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

  void _showPostRecommendationInfo(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          '팁!',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: screenWidth * 0.045,
          ),
        ),
        content: Text(
          '좋아요! 맛있게 드시고, 나중에 상단의 리뷰 작성 아이콘을 눌러 AI에게 리뷰 작성을 맡겨보세요!',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: screenWidth * 0.04,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인', style: TextStyle(fontFamily: 'Do Hyeon')),
            onPressed: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textColor = HSLColor.fromColor(
      widget.color,
    ).withLightness(0.25).toColor();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          titlePadding: EdgeInsets.only(
            left: screenWidth * 0.05,
            right: screenWidth * 0.02,
            top: screenHeight * 0.0225,
            bottom: screenHeight * 0.01,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.0125,
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.05,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '🍽️ 오늘의 ${widget.category} 추천!',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: screenWidth * 0.05,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Roulette display (without "재추천" button)
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.1875,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color, widget.color.withAlpha((255 * 0.5).round())],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withAlpha((255 * 0.3).round()),
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
                              scale: _isSpinning ? 1.0 : _scaleAnimation.value,
                              child: Text(
                                _displayText,
                                style: TextStyle(
                                  fontFamily: 'Do Hyeon',
                                  fontSize: _isSpinning
                                      ? screenWidth * 0.06
                                      : screenWidth * 0.08,
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
                SizedBox(height: screenHeight * 0.03),
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
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.0225),
                        // 좋아요/싫어요 버튼을 나란히 배치
                        Row(
                          children: [
                            // 좋아요 버튼
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // 선택 기록 저장 (좋아요)
                                  await UserPreferenceService.recordFoodSelection(
                                    foodName: widget.recommended.name,
                                    category: widget.category,
                                    liked: true,
                                  );
                                  // 다이얼로그 닫기
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  // 안내 다이얼로그 표시
                                  _showPostRecommendationInfo(
                                    context,
                                    screenWidth,
                                    screenHeight,
                                  );
                                },
                                icon: Icon(
                                  Icons.thumb_up,
                                  size: screenWidth * 0.04,
                                ),
                                label: const Text(
                                  '좋아요!',
                                  style: TextStyle(fontFamily: 'Do Hyeon'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02,
                                    vertical: screenHeight * 0.015,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.025,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            // 싫어요 버튼
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // 선택 기록 저장 (싫어요)
                                  await UserPreferenceService.recordFoodSelection(
                                    foodName: widget.recommended.name,
                                    category: widget.category,
                                    liked: false,
                                  );
                                  // 다이얼로그 닫기하고 재추천
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop(true);
                                },
                                icon: Icon(
                                  Icons.thumb_down,
                                  size: screenWidth * 0.04,
                                ),
                                label: const Text(
                                  '다른 걸로',
                                  style: TextStyle(fontFamily: 'Do Hyeon'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02,
                                    vertical: screenHeight * 0.015,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.025,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        // 단순히 닫기만 하는 버튼
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            '나중에 정하기',
                            style: TextStyle(
                              fontFamily: 'Do Hyeon',
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey.shade600,
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
              path.addOval(
                Rect.fromCircle(
                  center: Offset.zero,
                  radius: screenWidth * 0.0175,
                ),
              );
              return path;
            },
          ),
        ),
      ],
    );
  }
}
