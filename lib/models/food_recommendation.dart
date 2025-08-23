import 'package:json_annotation/json_annotation.dart';

part 'food_recommendation.g.dart';

@JsonSerializable()
class FoodRecommendation {
  final String name;
  final String? imageUrl;

  const FoodRecommendation({required this.name, this.imageUrl});

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) =>
      _$FoodRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$FoodRecommendationToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodRecommendation &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => name.hashCode ^ imageUrl.hashCode;

  @override
  String toString() => 'FoodRecommendation(name: $name, imageUrl: $imageUrl)';
}