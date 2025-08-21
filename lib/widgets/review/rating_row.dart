
import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final String label;
  final double rating;
  final Function(double)? onRate;
  final double? iconSize;

  const RatingRow({
    super.key,
    required this.label,
    required this.rating,
    this.onRate,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.0025),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth * 0.12,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.04,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: onRate != null ? () => onRate!((index + 1).toDouble()) : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                    ),
                    child: Icon(
                      Icons.star,
                      color: index < rating
                          ? Colors.amber
                          : Colors.grey.shade300,
                      size: iconSize ?? screenWidth * 0.07,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
