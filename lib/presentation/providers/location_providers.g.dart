// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationServiceHash() => r'347d171ff0e8ffe39618ec7b7608be7bd7c86f0a';

/// 위치 서비스 프로바이더
///
/// Copied from [locationService].
@ProviderFor(locationService)
final locationServiceProvider = Provider<LocationService>.internal(
  locationService,
  name: r'locationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServiceRef = ProviderRef<LocationService>;
String _$kakaoApiServiceHash() => r'aa41127a4cd02a0ad7984134ebf2c06a7f870d23';

/// 카카오 API 서비스 프로바이더
///
/// Copied from [kakaoApiService].
@ProviderFor(kakaoApiService)
final kakaoApiServiceProvider = Provider<KakaoApiService>.internal(
  kakaoApiService,
  name: r'kakaoApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$kakaoApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KakaoApiServiceRef = ProviderRef<KakaoApiService>;
String _$locationPermissionHash() =>
    r'07291ca7452c05ffacf8283230141f5a4e243620';

/// 위치 권한 상태 프로바이더
///
/// Copied from [locationPermission].
@ProviderFor(locationPermission)
final locationPermissionProvider =
    FutureProvider<LocationPermissionStatus>.internal(
      locationPermission,
      name: r'locationPermissionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationPermissionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationPermissionRef = FutureProviderRef<LocationPermissionStatus>;
String _$locationServiceStatusHash() =>
    r'4a34029738225b6d6a3dc2786e1b9a543c05af2a';

/// 위치 서비스 상태 프로바이더
///
/// Copied from [locationServiceStatus].
@ProviderFor(locationServiceStatus)
final locationServiceStatusProvider =
    FutureProvider<LocationServiceStatus>.internal(
      locationServiceStatus,
      name: r'locationServiceStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationServiceStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServiceStatusRef = FutureProviderRef<LocationServiceStatus>;
String _$currentLocationHash() => r'763d269e8d77da403b03b59406ad43780d73bdb5';

/// 현재 위치 프로바이더
///
/// Copied from [currentLocation].
@ProviderFor(currentLocation)
final currentLocationProvider = FutureProvider<UserLocation?>.internal(
  currentLocation,
  name: r'currentLocationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLocationRef = FutureProviderRef<UserLocation?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
