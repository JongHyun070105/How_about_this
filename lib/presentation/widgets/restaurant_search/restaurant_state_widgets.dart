import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/presentation/providers/location_providers.dart';

/// 위치 권한 오류 위젯
class RestaurantPermissionErrorWidget extends ConsumerWidget {
  const RestaurantPermissionErrorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_disabled,
              size: screenWidth * 0.16,
              color: Colors.orange[300],
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              '위치 권한이 필요합니다',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              '내 주변 맛집을 찾기 위해 위치 권한이 필요합니다.\n설정에서 위치 권한을 허용해주세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.04),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(restaurantSearchProvider.notifier)
                    .requestLocationPermission();
              },
              icon: const Icon(Icons.check),
              label: const Text('권한 허용하기'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.015,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Semantics(
              button: true,
              label: '휴대폰 설정으로 이동하여 직접 권한 허용',
              child: TextButton(
                onPressed: () {
                  ref.read(restaurantSearchProvider.notifier).openAppSettings();
                },
                child: const Text('설정으로 이동'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 위치 수신 실패 오류 위젯
class RestaurantLocationErrorWidget extends ConsumerWidget {
  final String message;
  final VoidCallback onRetry;

  const RestaurantLocationErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: screenWidth * 0.16,
              color: Colors.grey,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              '위치를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(restaurantSearchProvider.notifier)
                    .clearLocationCache();
                onRetry();
              },
              child: const Text('다시 시도'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref
                    .read(restaurantSearchProvider.notifier)
                    .openLocationSettings();
              },
              child: const Text('위치 설정 열기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 검색 결과 없음 위젯
class RestaurantNoResultsWidget extends StatelessWidget {
  const RestaurantNoResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: screenWidth * 0.16,
              color: Colors.grey,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              '근처에 맛집이 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              '다른 음식으로 검색해보세요',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
