import 'package:flutter_riverpod/flutter_riverpod.dart';

// 현재 위치 텍스트를 관리하는 StateProvider
final currentLocationTextProvider = StateProvider<String>((ref) => '이거 먹자!');
