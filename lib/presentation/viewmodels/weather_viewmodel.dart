import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/services/location_service.dart';
import 'package:review_ai/services/weather_service.dart';

class WeatherInfo {
  final WeatherCondition condition;
  final String message;

  WeatherInfo({required this.condition, required this.message});
}

class WeatherViewModel extends StateNotifier<AsyncValue<WeatherInfo?>> {
  final WeatherService _weatherService;
  final LocationService _locationService;

  WeatherViewModel(this._weatherService, this._locationService) : super(const AsyncValue.loading()) {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    state = const AsyncValue.loading();
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final weather = await _weatherService.getCurrentWeather(
        position.latitude,
        position.longitude,
      );

      final message = _getWeatherMessage(weather);
      state = AsyncValue.data(WeatherInfo(condition: weather, message: message));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherViewModelProvider = StateNotifierProvider<WeatherViewModel, AsyncValue<WeatherInfo?>>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  final locationService = ref.watch(Provider((ref) => LocationService()));
  return WeatherViewModel(weatherService, locationService);
});
