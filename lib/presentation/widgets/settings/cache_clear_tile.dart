import 'package:flutter/material.dart';

/// 캐시 용량 표시 및 삭제 버튼을 제공하는 타일 위젯
class CacheClearTile extends StatelessWidget {
  final String cacheSize;
  final VoidCallback onClearPressed;

  const CacheClearTile({
    super.key,
    required this.cacheSize,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cleaning_services_outlined,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '캐시 지우기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SCDream',
                  ),
                ),
                Text(
                  '현재 사용량: $cacheSize',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey[600],
                    fontFamily: 'SCDream',
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClearPressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              '지우기',
              style: TextStyle(
                fontFamily: 'SCDream',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
