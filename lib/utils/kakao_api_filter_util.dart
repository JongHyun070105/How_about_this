import 'package:review_ai/data/models/location_models.dart';

/// 카카오 맛집 검색 결과 필터링 및 정렬 유틸리티
class KakaoApiFilterUtil {
  static const Map<String, List<String>> _categoryKeywords = {
    '중식': ['중식', '중국'],
    '한식': ['한식', '한정식', '백반', '고기', '삼겹살', '갈비', '찌개', '국밥'],
    '일식': ['일식', '일본', '스시', '초밥', '라멘', '우동'],
    '양식': ['양식', '이탈리안', '스테이크', '파스타', '피자'],
    '분식': ['분식'],
    '아시안': ['아시아', '베트남', '태국', '인도', '동남아'],
  };

  /// 카테고리에 맞는 카카오 카테고리 코드를 반환합니다.
  static String? getCategoryCode(String? category) {
    if (category == null) return 'FD6'; // 기본값: 음식점

    switch (category) {
      case '카페':
        return 'CE7';
      case '편의점':
        return 'CS2';
      case '한식':
      case '중식':
      case '일식':
      case '양식':
      case '분식':
      case '아시안':
      case '패스트푸드':
        return 'FD6'; // 모두 음식점
      default:
        return 'FD6';
    }
  }

  /// 카테고리별 검색어를 생성합니다.
  static String getCategorySearchQuery(String category, String foodName) {
    switch (category) {
      case '편의점':
        return '편의점';
      case '한식':
      case '중식':
      case '일식':
      case '양식':
      case '분식':
      case '아시안':
      case '패스트푸드':
      case '카페':
      default:
        return foodName;
    }
  }

  /// 검색 결과를 필터링합니다. (카테고리 정확도 향상)
  static List<KakaoPlace> filterRestaurants(
    List<KakaoPlace> restaurants, {
    String? targetCategory,
    String? foodName,
    double? minRating,
    int? maxDistance,
    List<String>? excludeCategories,
  }) {
    return restaurants.where((restaurant) {
      // 거리 필터링
      if (maxDistance != null && restaurant.distanceInMeters != null) {
        if (restaurant.distanceInMeters! > maxDistance) {
          return false;
        }
      }

      // 음식명 필터링: 음식점 이름이나 카테고리에 음식명이 포함되어야 함
      if (foodName != null && foodName.isNotEmpty) {
        final nameLower = restaurant.placeName.toLowerCase();
        final categoryLower = restaurant.categoryName.toLowerCase();
        final foodLower = foodName.toLowerCase();

        final hasRelevance =
            nameLower.contains(foodLower) || categoryLower.contains(foodLower);

        // 관련성이 전혀 없으면 제외
        if (!hasRelevance && targetCategory != null) {
          // 단, 카테고리만 맞는 경우는 허용
        }
      }

      // 카테고리 정확도 필터링 강화
      if (targetCategory != null) {
        final keywords = _categoryKeywords[targetCategory];
        if (keywords != null) {
          final categoryLower = restaurant.categoryName.toLowerCase();
          final hasKeyword = keywords.any((kw) => categoryLower.contains(kw));
          if (!hasKeyword) {
            return false;
          }
        }
      }

      // 카테고리 제외 필터링
      if (excludeCategories != null && excludeCategories.isNotEmpty) {
        final hasExclude = excludeCategories.any(
          (cat) => restaurant.categoryName.contains(cat),
        );
        if (hasExclude) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 검색 결과를 정렬합니다.
  static List<KakaoPlace> sortRestaurants(
    List<KakaoPlace> restaurants, {
    RestaurantSortType sortType = RestaurantSortType.distance,
  }) {
    switch (sortType) {
      case RestaurantSortType.distance:
        return restaurants..sort((a, b) {
          final distanceA = a.distanceInMeters ?? double.infinity;
          final distanceB = b.distanceInMeters ?? double.infinity;
          return distanceA.compareTo(distanceB);
        });
      case RestaurantSortType.name:
        return restaurants..sort((a, b) => a.placeName.compareTo(b.placeName));
      case RestaurantSortType.category:
        return restaurants
          ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
    }
  }
}

/// 맛집 정렬 타입
enum RestaurantSortType {
  distance, // 거리순
  name, // 이름순
  category, // 카테고리순
}
