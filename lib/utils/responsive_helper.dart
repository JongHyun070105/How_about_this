import 'package:flutter/material.dart';
import 'package:review_ai/config/ui_constants.dart';

/// 반응형 UI 헬퍼
///
/// 기존 `Responsive` 클래스와 `ResponsiveHelper`를 하나로 통합합니다.
/// `context.responsive`로 간편하게 접근하거나 `ResponsiveHelper(context)` 형태로 사용합니다.
class ResponsiveHelper {
  final BuildContext context;
  late final double _screenWidth;
  late final double _screenHeight;
  late final bool _isTablet;
  late final bool _isSmallScreen;

  ResponsiveHelper(this.context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _isTablet = _screenWidth >= UiConstants.tabletMinWidth;
    _isSmallScreen = _screenWidth < 600;
  }

  // ── 기본 속성 ──

  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  bool get isTablet => _isTablet;
  bool get isSmallScreen => _isSmallScreen;

  // ── 폰트 크기 ──

  double appBarFontSize() => _calcFont(0.032, 0.05, 16.0, 28.0);
  double titleFontSize() => _calcFont(0.032, 0.045, 16.0, 24.0);
  double subtitleFontSize() => _calcFont(0.025, 0.04, 12.0, 18.0);
  double bodyFontSize() => _calcFont(0.027, 0.038, 13.0, 19.0);
  double captionFontSize() => _calcFont(0.022, 0.035, 11.0, 16.0);
  double buttonFontSize() => _calcFont(0.03, 0.04, 14.0, 22.0);
  double inputFontSize() => _calcFont(0.028, 0.04, 14.0, 20.0);

  /// 범용 폰트 크기 계산 (비율 기반)
  double fontSize({
    required double mobileRatio,
    required double tabletRatio,
    double min = UiConstants.minFontSize,
    double max = UiConstants.maxFontSize,
  }) {
    final ratio = _isTablet ? tabletRatio : mobileRatio;
    return (_screenWidth * ratio).clamp(min, max);
  }

  // ── 레이아웃 ──

  double horizontalPadding() => _calcPadding(0.08, 0.06, 20.0, 60.0);
  double verticalSpacing() => _calcSpacing(0.025, 0.02, 12.0, 24.0);
  double buttonHeight() => _calcSpacing(0.065, 0.06, 44.0, 70.0);

  double iconSize() => _calcIcon(0.045, 0.06, 20.0, 36.0);

  /// 범용 아이콘 크기 계산
  double iconSizeCustom({
    double mobileRatio = 0.05,
    double tabletRatio = 0.032,
    double min = UiConstants.iconSizeSmall,
    double max = UiConstants.iconSizeLarge,
  }) {
    final ratio = _isTablet ? tabletRatio : mobileRatio;
    return (_screenWidth * ratio).clamp(min, max);
  }

  // ── 그리드 ──

  int crossAxisCount() {
    if (_isTablet) {
      return _screenWidth > 1024 ? 4 : 3;
    }
    return 2;
  }

  double childAspectRatio() {
    if (_isTablet) return 0.95;
    if (_isSmallScreen) return 0.88;
    return 0.92;
  }

  // ── 비율 계산 ──

  double widthRatio(double ratio) => _screenWidth * ratio;
  double heightRatio(double ratio) => _screenHeight * ratio;

  // ── 내부 헬퍼 ──

  double _calcFont(double tabletMul, double phoneMul, double min, double max) {
    return (_screenWidth * (_isTablet ? tabletMul : phoneMul)).clamp(min, max);
  }

  double _calcPadding(
    double tabletMul,
    double phoneMul,
    double min,
    double max,
  ) {
    return (_screenWidth * (_isTablet ? tabletMul : phoneMul)).clamp(min, max);
  }

  double _calcSpacing(
    double tabletMul,
    double phoneMul,
    double min,
    double max,
  ) {
    return (_screenHeight * (_isTablet ? tabletMul : phoneMul)).clamp(min, max);
  }

  double _calcIcon(double tabletMul, double phoneMul, double min, double max) {
    return (_screenWidth * (_isTablet ? tabletMul : phoneMul)).clamp(min, max);
  }
}

/// 하위 호환용 타입 별칭
typedef Responsive = ResponsiveHelper;

/// BuildContext 확장 메서드
extension ResponsiveExtension on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);

  bool get isTablet =>
      MediaQuery.of(this).size.width >= UiConstants.tabletMinWidth;

  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;
}
