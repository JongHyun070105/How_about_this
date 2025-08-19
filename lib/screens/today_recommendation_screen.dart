import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reviewai_flutter/providers/food_providers.dart';
import 'package:reviewai_flutter/screens/review_screen.dart';

class TodayRecommendationScreen extends ConsumerWidget {
  const TodayRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodCategories = ref.watch(foodCategoriesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textTheme = Theme.of(context).textTheme;

    // 최근 3개 중복 방지용 선택 기록은 다이얼로그 생명주기 동안만 유지
    FoodRecommendation pickRandomFood(
      List<FoodRecommendation> foods,
      List<String> recentFoods,
    ) {
      if (foods.isEmpty) {
        throw Exception("추천 가능한 음식이 없습니다.");
      }

      // 최근 음식과 겹치지 않게 필터링
      List<FoodRecommendation> available = foods
          .where((f) => !recentFoods.contains(f.name))
          .toList();

      if (available.isEmpty) {
        // 모두 겹치면 기록 초기화 후 전체에서 다시 랜덤
        recentFoods.clear();
        available = List.from(foods);
      }

      final chosen = available[Random().nextInt(available.length)];
      // 최근 3개 관리
      recentFoods.add(chosen.name);
      if (recentFoods.length > 3) {
        recentFoods.removeAt(0);
      }
      return chosen;
    }

    void showRecommendationDialog(
      BuildContext context, {
      required String category,
      required List<FoodRecommendation> foods,
    }) {
      final recentFoods = <String>[]; // 다이얼로그 세션 동안만 유지

      void open() {
        final recommended = pickRandomFood(foods, recentFoods);
        ref.read(selectedFoodProvider.notifier).state = recommended;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('오늘의 $category 추천 음식'),
            content: Text('${recommended.name}!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 현재 다이얼로그 닫기
                  open(); // 재추천: 같은 리스트에서 중복 최소화 로직으로 다시 추천
                },
                child: const Text('재추천'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewScreen(food: recommended),
                    ),
                  );
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }

      open();
    }

    return Scaffold(
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

            // 카테고리 카드 리스트
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: screenWidth * 0.04,
                  mainAxisSpacing: screenHeight * 0.02,
                  childAspectRatio: 0.9,
                ),
                itemCount: foodCategories.length,
                itemBuilder: (context, index) {
                  final category = foodCategories[index];

                  return GestureDetector(
                    onTap: () async {
                      // 1) 새 카테고리 상태 반영
                      ref.read(selectedCategoryProvider.notifier).state =
                          category.name;
                      ref.read(selectedFoodProvider.notifier).state = null;

                      // 2) ***중요***: 새 카테고리로 직접 Future를 읽어서 신선한 결과 사용
                      try {
                        final foods = await ref.read(
                          recommendationProvider(category.name).future,
                        );

                        if (foods.isNotEmpty) {
                          showRecommendationDialog(
                            context,
                            category: category.name,
                            foods: foods,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('추천을 불러오지 못했어요.')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('오류: $e')));
                      }
                    },
                    child: Card(
                      color: category.color,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
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
                              placeholderBuilder: (context) => Container(
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
                  );
                },
              ),
            ),

            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}
