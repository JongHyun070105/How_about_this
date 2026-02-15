import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final String review;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ReviewCard({
    super.key,
    required this.review,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? screenWidth * 0.005 : screenWidth * 0.0025,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenHeight * 0.02,
        ),
        color: isSelected ? Colors.blue.shade50 : const Color(0xFFF1F1F1),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    review,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      fontFamily: 'Do Hyeon',
                      fontSize: screenWidth * 0.045,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: screenWidth * 0.03,
                right: screenWidth * 0.03,
                child: Container(
                  width: screenWidth * 0.06,
                  height: screenWidth * 0.06,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: screenWidth * 0.04,
                  ),
                ),
              ),
            Positioned(
              top: screenWidth * 0.03,
              left: screenWidth * 0.03,
              child: IconButton(
                icon: Icon(Icons.edit, size: screenWidth * 0.05),
                color: Colors.grey.shade600,
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
