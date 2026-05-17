import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/config/app_constants.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/presentation/screens/history_screen.dart';
import 'package:review_ai/presentation/screens/review_selection_screen.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:review_ai/presentation/viewmodels/review_viewmodel.dart';
import 'package:review_ai/presentation/widgets/review/image_upload_section.dart';
import 'package:review_ai/presentation/widgets/common/animated_loading_indicator.dart';
import 'package:review_ai/presentation/widgets/review/review_style_section.dart';
import 'package:review_ai/presentation/widgets/review/review_form_widgets.dart';
import 'package:review_ai/presentation/widgets/review/review_generate_button.dart';
import 'package:review_ai/services/image_labeling_service.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final FoodRecommendation food;
  final String category;

  const ReviewScreen({super.key, required this.food, required this.category});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final TextEditingController _foodNameController = TextEditingController();
  bool _hasNavigatedToSelection = false;
  bool _isGeneratingFoodName = false;
  bool _isUpdatingFromProvider = false;
  final ImageLabelingService _imageLabelingService = ImageLabelingService();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedFood = widget.food;
      final isDefaultFood = selectedFood.name == AppConstants.defaultFoodName;
      final foodNameToSet = isDefaultFood ? '' : selectedFood.name;

      _foodNameController.text = foodNameToSet;
      ref.read(reviewProvider.notifier).setFoodName(foodNameToSet);
      ref.read(reviewProvider.notifier).setCategory(widget.category);
      _hasNavigatedToSelection = false;
    });
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _imageLabelingService.dispose();
    super.dispose();
  }

  // AI 음식명 생성
  Future<void> _generateFoodNameWithAI() async {
    final imageFile = ref.read(reviewProvider).image;
    if (imageFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 음식 이미지를 업로드해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isGeneratingFoodName = true);

    try {
      final labels = await _imageLabelingService.getLabels(imageFile);
      if (labels.isNotEmpty && mounted) {
        final suggestedFood = labels.first;
        _isUpdatingFromProvider = true;
        ref.read(reviewProvider.notifier).setFoodName(suggestedFood);
        _foodNameController.text = suggestedFood;
        _isUpdatingFromProvider = false;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('음식 이미지를 인식하지 못했습니다. 직접 입력해주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI 음식명 생성 실패: ${e.toString().contains('서버') ? '서버 오류' : '네트워크 오류'}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingFoodName = false);
    }
  }

  void _navigateToRecommendationScreen() {
    _hasNavigatedToSelection = false;
    Navigator.pop(context);
  }

  void _navigateToHistoryScreen() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HistoryScreen()),
  );

  void _navigateToReviewSelection() {
    if (!_hasNavigatedToSelection && context.mounted) {
      _hasNavigatedToSelection = true;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReviewSelectionScreen()),
      ).then((_) {
        if (mounted) {
          _hasNavigatedToSelection = false;
          ref.read(reviewProvider.notifier).setGeneratedReviews([]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final reviewState = ref.watch(reviewProvider);
    final isLoading = reviewState.isLoading;

    // foodName 변경 → 텍스트 필드 동기화 (순환 방지)
    ref.listen(reviewProvider.select((s) => s.foodName), (_, next) {
      if (_foodNameController.text != next) {
        _isUpdatingFromProvider = true;
        _foodNameController.text = next;
        _isUpdatingFromProvider = false;
      }
    });

    // 리뷰 생성 완료 → 선택 화면으로 이동
    ref.listen(reviewProvider.select((s) => s.generatedReviews), (prev, next) {
      if (prev?.isEmpty == true &&
          next.isNotEmpty &&
          !_hasNavigatedToSelection &&
          context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && !_hasNavigatedToSelection) {
            _navigateToReviewSelection();
          }
        });
      }
    });

    final bool isValid =
        reviewState.foodName.trim().isNotEmpty &&
        reviewState.deliveryRating > 0 &&
        reviewState.tasteRating > 0 &&
        reviewState.portionRating > 0 &&
        reviewState.priceRating > 0;

    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _hasNavigatedToSelection = false;
          ref.read(reviewProvider.notifier).reset();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, responsive),
            body: _buildBody(context, responsive, isLoading, isValid),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Responsive responsive,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      centerTitle: true,
      title: Semantics(
        header: true,
        label: '리뷰 분석 및 생성 화면',
        child: Text(
          '리뷰 AI',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: responsive.appBarFontSize(),
            fontWeight: FontWeight.bold,
            fontFamily: 'SCDream',
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: responsive.iconSize()),
        onPressed: _navigateToRecommendationScreen,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, size: responsive.iconSize()),
          onPressed: _navigateToHistoryScreen,
          tooltip: '히스토리',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    Responsive responsive,
    bool isLoading,
    bool isValid,
  ) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding(),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: responsive.verticalSpacing() * 0.4),
              Container(
                constraints: BoxConstraints(
                  maxHeight:
                      responsive.screenHeight *
                      (responsive.isTablet ? 0.28 : 0.26),
                ),
                child: const ImageUploadSection(),
              ),
              SizedBox(height: responsive.verticalSpacing() * 0.8),
              _sectionLabel(responsive, '음식명'),
              SizedBox(height: responsive.verticalSpacing() * 0.3),
              FoodNameInputField(
                controller: _foodNameController,
                isGenerating: _isGeneratingFoodName,
                isUpdatingFromProvider: _isUpdatingFromProvider,
                onAiTap: _generateFoodNameWithAI,
              ),
              SizedBox(height: responsive.verticalSpacing() * 0.6),
              _sectionLabel(responsive, '평점'),
              SizedBox(height: responsive.verticalSpacing() * 0.4),
              const RatingSection(),
              SizedBox(height: responsive.verticalSpacing() * 0.8),
              const ReviewStyleSection(),
              SizedBox(height: responsive.verticalSpacing() * 1.2),
              ReviewGenerateButton(
                isValid: isValid,
                isLoading: isLoading,
                onPressed: (isLoading || !isValid)
                    ? null
                    : () => ref
                          .read(reviewViewModelProvider.notifier)
                          .generateReviews(context),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(Responsive responsive, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: TextStyle(
            fontSize: responsive.inputFontSize() * 1.1,
            fontWeight: FontWeight.bold,
            fontFamily: 'SCDream',
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return const AnimatedLoadingIndicator(
      messages: [
        '리뷰 생성 중...',
        'AI가 글을 쓰고 있어요...',
        '맛 표현을 다듬는 중...',
        '거의 다 됐어요!',
      ],
    );
  }
}
