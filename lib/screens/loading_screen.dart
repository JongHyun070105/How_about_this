import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // Added this line
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:eat_this_app/providers/food_providers.dart';
import 'package:eat_this_app/screens/today_recommendation_screen.dart';
import 'package:eat_this_app/widgets/dialogs/review_dialogs.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeLoading();
  }

  Future<void> _initializeLoading() async {
    // 1. Check Network Connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      if (!mounted) return;
      showAlertDialog(
        context,
        '네트워크 연결 오류',
        '인터넷 연결을 확인해주세요. 앱을 종료합니다.',
        onConfirm: () => Navigator.of(context).pop(), // Simple pop, app might exit naturally
      );
      return; // Stop further loading
    }

    // 2. Precache Category Images
    final foodCategories = ref.read(foodCategoriesProvider);
    for (final category in foodCategories) {
      try {
        final loader = SvgAssetLoader(category.imageUrl);
        await precachePicture(loader, context);
      } catch (e) {
        debugPrint('Failed to precache SVG image: ${category.imageUrl}, Error: $e');
        // Optionally show an error to the user or log it more robustly
      }
    }

    // 3. Navigate to TodayRecommendationScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TodayRecommendationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app icon here if you want it to fade in
            // Image.asset('icon/app_icon.png', width: 150, height: 150),
            // SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(fontFamily: 'Do Hyeon', fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}