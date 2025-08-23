import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const PrimaryActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;

    final buttonFontSize = (screenWidth * (isTablet ? 0.03 : 0.04)).clamp(14.0, 22.0);
    final buttonHeight = (screenHeight * (isTablet ? 0.07 : 0.065)).clamp(48.0, 72.0);

    final bool isButtonEnabled = isEnabled && !isLoading && onPressed != null;

    return Container(
      width: double.infinity,
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
      ),
      child: ElevatedButton(
        onPressed: isButtonEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonEnabled
              ? Theme.of(context).primaryColor
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
          ),
          padding: EdgeInsets.symmetric(
            vertical: (screenHeight * 0.015).clamp(8.0, 16.0),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3.0,
              )
            : Text(
                text,
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
