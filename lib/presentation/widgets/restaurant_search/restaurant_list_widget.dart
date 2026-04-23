import 'package:flutter/material.dart';
import 'package:review_ai/data/models/location_models.dart';

/// 맛집 리스트 위젯
class RestaurantListWidget extends StatelessWidget {
  final List<KakaoPlace> restaurants;
  final String foodName;
  final String category;
  final void Function(KakaoPlace) onTapRestaurant;

  const RestaurantListWidget({
    super.key,
    required this.restaurants,
    required this.foodName,
    required this.category,
    required this.onTapRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) => _RestaurantCard(
              restaurant: restaurants[index],
              onTap: () => onTapRestaurant(restaurants[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '${restaurants.length}개의 음식점을 찾았습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: '검색 필터: $foodName 및 $category',
            child: Text(
              '$foodName • $category',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final KakaoPlace restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            restaurant.placeName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: _buildSubtitle(context),
          trailing: Semantics(
            label: '배달 앱 열기',
            button: true,
            child: const IconButton(
              icon: Icon(Icons.delivery_dining),
              onPressed: null,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          restaurant.roadAddressName ?? restaurant.addressName,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        if (restaurant.phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            restaurant.phone,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            if (restaurant.distanceFormatted.isNotEmpty) ...[
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                restaurant.distanceFormatted,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  restaurant.categoryName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
