import 'package:flutter/material.dart';

/// 사용량 인디케이터 위젯
class UsageIndicator extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final Color color;
  final IconData icon;

  const UsageIndicator({
    super.key,
    required this.label,
    required this.used,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final fontSize = (screenWidth * (isTablet ? 0.018 : 0.032)).clamp(
      12.0,
      18.0,
    );

    final percentage = total > 0 ? (used / total) : 0.0;
    final remaining = total - used;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: fontSize, color: color),
            SizedBox(width: screenWidth * 0.01),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: fontSize,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.015),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        SizedBox(height: screenWidth * 0.01),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$used / $total',
              style: TextStyle(
                fontFamily: 'SCDream',
                fontSize: fontSize * 0.85,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              remaining >= 0 ? '남은 횟수: $remaining' : '한도 초과',
              style: TextStyle(
                fontFamily: 'SCDream',
                fontSize: fontSize * 0.85,
                color: remaining >= 0
                    ? color
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
