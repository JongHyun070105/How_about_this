import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/data/models/location_models.dart';
import 'package:review_ai/presentation/viewmodels/weather_viewmodel.dart';
import 'package:review_ai/services/location_service.dart';
import 'package:review_ai/services/weather_service.dart';

class FakeLocationService implements LocationService {
  UserLocation? mockLocation;
  bool shouldThrow = false;

  @override
  Future<UserLocation?> getCurrentLocation() async {
    if (shouldThrow) throw UserPermissionDeniedException('Denied');
    return mockLocation;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWeatherService implements WeatherService {
  WeatherCondition mockCondition = WeatherCondition.clear;
  bool shouldThrow = false;

  @override
  Future<WeatherCondition> getCurrentWeather(double lat, double lng) async {
    if (shouldThrow) throw Exception('Weather API failed');
    return mockCondition;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeLocationService fakeLocationService;
  late FakeWeatherService fakeWeatherService;

  setUp(() {
    fakeLocationService = FakeLocationService();
    fakeWeatherService = FakeWeatherService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        weatherServiceProvider.overrideWithValue(fakeWeatherService),
        // we can override the inner Provider inside weatherViewModelProvider but let's just test ViewModel directly
      ],
    );
    return container;
  }

  test('fetchWeather succeeds and returns WeatherInfo', () async {
    fakeLocationService.mockLocation = UserLocation(
      latitude: 37.5,
      longitude: 127.0,
      timestamp: DateTime.now(),
      accuracy: 1.0,
    );
    fakeWeatherService.mockCondition = WeatherCondition.clouds;

    final viewModel = WeatherViewModel(fakeWeatherService, fakeLocationService);

    // Initial state in constructor is loading, then it calls fetchWeather
    expect(viewModel.state, isA<AsyncLoading>());

    // Wait for fetchWeather to complete
    await Future.delayed(Duration.zero);

    expect(viewModel.state, isA<AsyncData>());
    final data = viewModel.state.value!;
    expect(data.condition, WeatherCondition.clouds);
    expect(data.message, '구름 낀 날 ☁️ 기분 전환할 맛있는 음식!');
  });

  test('fetchWeather handles location permission denied', () async {
    fakeLocationService.shouldThrow = true;

    final viewModel = WeatherViewModel(fakeWeatherService, fakeLocationService);

    await Future.delayed(Duration.zero);

    // If location throws, it should emit AsyncError
    expect(viewModel.state, isA<AsyncError>());
  });

  test('fetchWeather handles weather API error', () async {
    fakeLocationService.mockLocation = UserLocation(
      latitude: 37.5,
      longitude: 127.0,
      timestamp: DateTime.now(),
      accuracy: 1.0,
    );
    fakeWeatherService.shouldThrow = true;

    final viewModel = WeatherViewModel(fakeWeatherService, fakeLocationService);

    await Future.delayed(Duration.zero);

    expect(viewModel.state, isA<AsyncError>());
  });

  test('fetchWeather handles null location (e.g. timeout fallback)', () async {
    fakeLocationService.mockLocation = null;

    final viewModel = WeatherViewModel(fakeWeatherService, fakeLocationService);

    await Future.delayed(Duration.zero);

    expect(viewModel.state, isA<AsyncData>());
    expect(viewModel.state.value, isNull);
  });
}
