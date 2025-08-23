// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodCategory _$FoodCategoryFromJson(Map<String, dynamic> json) => FoodCategory(
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
  color: FoodCategory._colorFromJson((json['color'] as num).toInt()),
);

Map<String, dynamic> _$FoodCategoryToJson(FoodCategory instance) =>
    <String, dynamic>{
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'color': FoodCategory._colorToJson(instance.color),
    };
