import 'package:flutter/material.dart';

class Responsive {
  final BuildContext _context;
  late final double _screenWidth;
  late final double _screenHeight;
  late final bool _isTablet;
  late final bool _isSmallScreen;

  Responsive(this._context) {
    final mediaQuery = MediaQuery.of(_context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _isTablet = _screenWidth >= 768;
    _isSmallScreen = _screenWidth < 600;
  }

  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  bool get isTablet => _isTablet;
  bool get isSmallScreen => _isSmallScreen;

  double appBarFontSize() => _calculateFontSize(0.032, 0.05, 16.0, 28.0);
  double titleFontSize() => _calculateFontSize(0.032, 0.045, 16.0, 24.0);
  double subtitleFontSize() => _calculateFontSize(0.025, 0.04, 12.0, 18.0);
  double bodyFontSize() => _calculateFontSize(0.027, 0.038, 13.0, 19.0);
  double captionFontSize() => _calculateFontSize(0.022, 0.035, 11.0, 16.0);
  double buttonFontSize() => _calculateFontSize(0.03, 0.04, 14.0, 22.0);
  double inputFontSize() => _calculateFontSize(0.028, 0.04, 14.0, 20.0);

  double horizontalPadding() => _calculatePadding(0.08, 0.06, 20.0, 60.0);
  double verticalSpacing() => _calculateSpacing(0.025, 0.02, 12.0, 24.0);
  double buttonHeight() => _calculateSpacing(0.065, 0.06, 44.0, 70.0);

  double iconSize() => _calculateIconSize(0.045, 0.06, 20.0, 36.0);

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

  double _calculateFontSize(
    double tabletMultiplier,
    double phoneMultiplier,
    double min,
    double max,
  ) {
    final multiplier = _isTablet ? tabletMultiplier : phoneMultiplier;
    return (_screenWidth * multiplier).clamp(min, max);
  }

  double _calculatePadding(
    double tabletMultiplier,
    double phoneMultiplier,
    double min,
    double max,
  ) {
    final multiplier = _isTablet ? tabletMultiplier : phoneMultiplier;
    return (_screenWidth * multiplier).clamp(min, max);
  }

  double _calculateSpacing(
    double tabletMultiplier,
    double phoneMultiplier,
    double min,
    double max,
  ) {
    final multiplier = _isTablet ? tabletMultiplier : phoneMultiplier;
    return (_screenHeight * multiplier).clamp(min, max);
  }

  double _calculateIconSize(
    double tabletMultiplier,
    double phoneMultiplier,
    double min,
    double max,
  ) {
    final multiplier = _isTablet ? tabletMultiplier : phoneMultiplier;
    return (_screenWidth * multiplier).clamp(min, max);
  }
}
