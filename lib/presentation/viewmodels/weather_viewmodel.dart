import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:review_ai/presentation/providers/location_providers.dart';
import 'package:review_ai/services/weather_service.dart';

part 'weather_viewmodel.g.dart';

class WeatherInfo {
  final WeatherCondition condition;
  final String message;

  WeatherInfo({required this.condition, required this.message});
}

@riverpod
WeatherService weatherService(Ref ref) {
  return WeatherService();
}

@riverpod
class WeatherViewModel extends _$WeatherViewModel {
  @override
  FutureOr<WeatherInfo?> build() async {
    return _fetchWeather();
  }

  Future<WeatherInfo?> _fetchWeather() async {
    final weatherService = ref.watch(weatherServiceProvider);
    final locationService = ref.watch(locationServiceProvider);

    final position = await locationService.getCurrentLocation();
    if (position == null) {
      return null;
    }

    final weather = await weatherService.getCurrentWeather(
      position.latitude,
      position.longitude,
    );

    final message = _getWeatherMessage(weather);
    return WeatherInfo(condition: weather, message: message);
  }

  Future<void> refreshWeather() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWeather());
  }

  String _getWeatherMessage(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.rain:
      case WeatherCondition.drizzle:
      case WeatherCondition.thunderstorm:
        return '비가 오네요 ☔ 뜨끈한 국물이나 파전 어때요?';
      case WeatherCondition.snow:
        return '눈이 내려요 ❄️ 따뜻한 전골 요리 추천해요!';
      case WeatherCondition.clear:
        return '날씨가 참 좋네요 ☀️ 시원한 냉면이나 아이스 커피?';
      case WeatherCondition.clouds:
        return '구름 낀 날 ☁️ 기분 전환할 맛있는 음식!';
      default:
        return '';
    }
  }
}
