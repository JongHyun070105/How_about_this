import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/presentation/widgets/history/dialogs/recommendation_dialog_widgets.dart';

class FoodRecommendationDialog extends ConsumerStatefulWidget {
  final String category;
  final FoodRecommendation recommended;
  final List<FoodRecommendation> foods;
  final Color color;
  final String reason;

  const FoodRecommendationDialog({
    super.key,
    required this.category,
    required this.recommended,
    required this.foods,
    required this.color,
    required this.reason,
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
    final allFoods = widget.foods.map((f) => f.name).toList()..shuffle();
    final spinnerFoods = allFoods.take(5).toList();
    int spinnerIndex = 0;

    _rouletteController.addListener(() {
      if (_isSpinning && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sw * 0.05),
          ),
          titlePadding: EdgeInsets.only(
            left: sw * 0.05,
            right: sw * 0.02,
            top: sh * 0.0225,
            bottom: sh * 0.01,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: sw * 0.05,
            vertical: sh * 0.0125,
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: sw * 0.06,
            vertical: sh * 0.05,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '🍽️ 오늘의 ${widget.category} 추천!',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontWeight: FontWeight.bold,
                    fontSize: sw * 0.045,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: sw * 0.06,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: sw,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 룰렛 디스플레이
                  RouletteDisplay(
                    color: widget.color,
                    displayText: _displayText,
                    isSpinning: _isSpinning,
                    scaleAnimation: _scaleAnimation,
                  ),
                  SizedBox(height: sh * 0.015),
                  if (!_isSpinning) ...[
                    // 추천 이유
                    RecommendationReason(reason: widget.reason),
                    SizedBox(height: sh * 0.012),
                    // 액션 버튼
                    RecommendationDialogButtons(
                      recommended: widget.recommended,
                      category: widget.category,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: null,
        ),
        // 컨페티
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
                  radius: MediaQuery.of(context).size.width * 0.0175,
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
