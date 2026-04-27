import 'package:review_ai/data/models/location_models.dart';

/// 카카오 맛집 검색 결과 필터링 및 정렬 유틸리티
class KakaoApiFilterUtil {
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
        final categoryLower = restaurant.categoryName.toLowerCase();

        switch (targetCategory) {
          case '중식':
            if (!categoryLower.contains('중식') &&
                !categoryLower.contains('중국')) {
              return false;
            }
            break;
          case '한식':
            if (!categoryLower.contains('한식') &&
                !categoryLower.contains('한정식') &&
                !categoryLower.contains('백반') &&
                !categoryLower.contains('고기') &&
                !categoryLower.contains('삼겹살') &&
                !categoryLower.contains('갈비') &&
                !categoryLower.contains('찌개') &&
                !categoryLower.contains('국밥')) {
              return false;
            }
            break;
          case '일식':
            if (!categoryLower.contains('일식') &&
                !categoryLower.contains('일본') &&
                !categoryLower.contains('스시') &&
                !categoryLower.contains('초밥') &&
                !categoryLower.contains('라멘') &&
                !categoryLower.contains('우동')) {
              return false;
            }
            break;
          case '양식':
            if (!categoryLower.contains('양식') &&
                !categoryLower.contains('이탈리안') &&
                !categoryLower.contains('스테이크') &&
                !categoryLower.contains('파스타') &&
                !categoryLower.contains('피자')) {
              return false;
            }
            break;
          case '분식':
            if (!categoryLower.contains('분식')) {
              return false;
            }
            break;
          case '아시안':
            if (!categoryLower.contains('아시아') &&
                !categoryLower.contains('베트남') &&
                !categoryLower.contains('태국') &&
                !categoryLower.contains('인도') &&
                !categoryLower.contains('동남아')) {
              return false;
            }
            break;
        }
      }

      // 카테고리 제외 필터링
      if (excludeCategories != null && excludeCategories.isNotEmpty) {
        for (final category in excludeCategories) {
          if (restaurant.categoryName.contains(category)) {
            return false;
          }
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
