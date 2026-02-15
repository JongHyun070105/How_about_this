import 'package:flutter_riverpod/flutter_riverpod.dart';

// 현재 위치 텍스트를 관리하는 StateProvider
final currentLocationTextProvider = StateProvider<String>((ref) => '오늘 뭐 먹지?');
