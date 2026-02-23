import 'package:flutter/material.dart';

/// 배달 앱 옵션 목록을 표시하는 위젯.
///
/// [onSelect] 콜백은 선택된 앱 식별자와 함께 호출됩니다.
/// (예: 'baemin', 'yogiyo', 'coupang_eats', 'kakao_map').
class DeliveryAppOptionList extends StatelessWidget {
  final void Function(String) onSelect;

  const DeliveryAppOptionList({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOption(context, 'baemin', '배민', '🍱'),
        _buildOption(context, 'yogiyo', '요기요', '🍜'),
        _buildOption(context, 'coupang_eats', '쿠팡이츠', '📦'),
        _buildOption(context, 'kakao_map', '카카오맵', '🗺️'),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context,
    String value,
    String name,
    String emoji,
  ) {
    return RepaintBoundary(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(name),
        onTap: () => onSelect(value),
      ),
    );
  }
}
