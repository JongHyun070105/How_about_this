import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final inputFontSize = (screenWidth * (isTablet ? 0.028 : 0.04)).clamp(
      14.0,
      20.0,
    );
    final verticalSpacing =
        (MediaQuery.of(context).size.height * (isTablet ? 0.025 : 0.02)).clamp(
          12.0,
          24.0,
        );

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: isTablet ? 4.0 : 3.0,
              ),
              SizedBox(height: verticalSpacing),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Do Hyeon',
                  fontSize: inputFontSize,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
