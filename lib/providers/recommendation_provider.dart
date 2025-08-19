import 'package:flutter_riverpod/flutter_riverpod.dart';

final recommendationListProvider =
    StateNotifierProvider<RecommendationNotifier, List<String>>((ref) {
      return RecommendationNotifier();
    });

class RecommendationNotifier extends StateNotifier<List<String>> {
  RecommendationNotifier() : super([]);

  void setRecommendations(List<String> recommendations) {
    state = recommendations;
  }

  void clear() => state = [];
}
