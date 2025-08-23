import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_category.g.dart';

@JsonSerializable()
class FoodCategory {
  final String name;
  final String imageUrl;

  @JsonKey(fromJson: _colorFromJson, toJson: _colorToJson)
  final Color color;

  const FoodCategory({
    required this.name,
    required this.imageUrl,
    required this.color,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) =>
      _$FoodCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$FoodCategoryToJson(this);

  static Color _colorFromJson(int json) => Color(json);
  static int _colorToJson(Color color) => color.toARGB32();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodCategory &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          imageUrl == other.imageUrl &&
          color == other.color;

  @override
  int get hashCode => name.hashCode ^ imageUrl.hashCode ^ color.hashCode;

  @override
  String toString() => 'FoodCategory(name: $name, imageUrl: $imageUrl)';
}