import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/services/recommendation_service.dart'; // Make sure this is imported
import 'package:flutter/material.dart'; // Added for Color

// 1. 음식 카테고리 모델
class FoodCategory {
  final String name;
  final String imageUrl;
  final Color color; // Added color property

  FoodCategory({required this.name, required this.imageUrl, required this.color});
}

// 2. 음식 카테고리 Provider
final foodCategoriesProvider = Provider<List<FoodCategory>>((ref) {
  return [
    FoodCategory(name: '한식', imageUrl: 'assets/images/categories/korean.svg', color: Colors.red.shade100),
    FoodCategory(name: '중식', imageUrl: 'assets/images/categories/china.svg', color: Colors.orange.shade100),
    FoodCategory(name: '일식', imageUrl: 'assets/images/categories/japan.svg', color: Colors.blue.shade100),
    FoodCategory(name: '양식', imageUrl: 'assets/images/categories/yangsick.svg', color: Colors.green.shade100),
    FoodCategory(name: '분식', imageUrl: 'assets/images/categories/boonsick.svg', color: Colors.purple.shade100),
    FoodCategory(name: '아시안', imageUrl: 'assets/images/categories/asiafood.svg', color: Colors.teal.shade100),
    FoodCategory(name: '패스트푸드', imageUrl: 'assets/images/categories/fastfood.svg', color: Colors.yellow.shade100),
    FoodCategory(name: '상관없음', imageUrl: 'assets/images/categories/good.svg', color: Colors.grey.shade100),
  ];
});

// 3. 사용자가 선택한 카테고리 Provider (카테고리 이름만 저장)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// 4. 추천받은 음식을 나타내는 모델 클래스 (FoodRecommendation)
class FoodRecommendation {
  final String name;
  final String? imageUrl; // Made nullable

  FoodRecommendation({required this.name, this.imageUrl}); // imageUrl is now optional

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?, // Handle nullable
    );
  }
}

// 5. 음식 추천 목록 Provider (실제 로직은 Service에서)
final recommendationProvider =
    FutureProvider.autoDispose.family<List<FoodRecommendation>, String>((ref, category) async {
  final foodHistory = ref.watch(foodHistoryProvider);
  return RecommendationService.getFoodRecommendations(
    category: category,
    history: foodHistory,
  );
});

// 6. 사용자가 최종 선택한 추천 음식 Provider
final selectedFoodProvider = StateProvider<FoodRecommendation?>((ref) => null);

// 7. 리뷰 작성 기록 Provider (다음 추천에 활용)
final foodHistoryProvider = StateNotifierProvider<FoodHistoryNotifier, List<String>>((ref) {
  return FoodHistoryNotifier();
});

class FoodHistoryNotifier extends StateNotifier<List<String>> {
  FoodHistoryNotifier() : super([]);

  void addFood(String foodName) {
    if (!state.contains(foodName)) {
      state = [...state, foodName];
    }
  }
}
