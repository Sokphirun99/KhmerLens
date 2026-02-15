import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../screens/product_scan_screen.dart';

class SpoonacularService {
  static const String _baseUrl = 'https://api.spoonacular.com/food/products';

  /// Fetches product information from Spoonacular API using UPC/EAN/Barcode.
  /// Returns a [ProductInfo] object if found, otherwise null.
  Future<ProductInfo?> fetchProductByUpc(String upc) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/upc/$upc?apiKey=${AppConfig.spoonacularApiKey}');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['status'] != 'failure') {
          return _mapToProductInfo(data);
        }
      } else {
        debugPrint(
            'Spoonacular API Error: ${response.statusCode} - ${response.reasonPhrase}');
        debugPrint('Spoonacular Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Spoonacular API Exception: $e');
    }
    return null;
  }

  ProductInfo _mapToProductInfo(Map<String, dynamic> data) {
    print('Spoonacular Data: $data');
    final details = <String, dynamic>{};

    if (data['brand'] != null) details['Brand'] = data['brand'];
    if (data['aisle'] != null) details['Aisle'] = data['aisle'];

    // Category
    if (data['breadcrumbs'] != null &&
        (data['breadcrumbs'] as List).isNotEmpty) {
      details['Category'] = (data['breadcrumbs'] as List).join(' > ');
    }

    // Ingredients
    if (data['ingredientList'] != null) {
      details['Ingredients'] = data['ingredientList'];
    }

    // Nutrition
    if (data['nutrition'] != null) {
      final nutritionInfo = data['nutrition'];
      final Map<String, dynamic> nutritionMap = {};

      if (nutritionInfo['nutrients'] != null) {
        for (var nutrient in nutritionInfo['nutrients']) {
          nutritionMap[nutrient['name']] =
              '${nutrient['amount']} ${nutrient['unit']}';
        }
      }

      // Caloric Breakdown
      if (nutritionInfo['caloricBreakdown'] != null) {
        final breakdown = nutritionInfo['caloricBreakdown'];
        nutritionMap['Carbs %'] = '${breakdown['percentCarbs']}%';
        nutritionMap['Fat %'] = '${breakdown['percentFat']}%';
        nutritionMap['Protein %'] = '${breakdown['percentProtein']}%';
      }

      if (nutritionMap.isNotEmpty) {
        details['Nutrition Facts'] = nutritionMap;
      }
    }

    // Badges (Health/Diet)
    final List<String> badgeList = [];
    if (data['badges'] != null) {
      badgeList.addAll(List<String>.from(data['badges']));
    }
    if (data['importantBadges'] != null) {
      badgeList.addAll(List<String>.from(data['importantBadges']));
    }
    if (badgeList.isNotEmpty) {
      final Map<String, String> badgeMap = {};
      for (var badge in badgeList) {
        // Simple heuristic: 'free' or 'low' = green (good), others neutral
        String level = 'Feature';
        if (badge.contains('free') ||
            badge.contains('low') ||
            badge.contains('organic') ||
            badge.contains('no_') ||
            badge.contains('gluten_free')) {
          level = 'good';
        }
        badgeMap[badge.replaceAll('_', ' ')] = level;
      }
      details['Nutrient Levels'] = badgeMap;
    }

    // Serving info
    if (data['serving_size'] != null) {
      details['Serving Size'] =
          '${data['serving_size']} ${data['serving_size_unit'] ?? ''}';
    }
    if (data['servings'] != null && data['servings']['number'] != null) {
      details['Servings per container'] = data['servings']['number'].toString();
    }

    return ProductInfo(
      title: data['title'] ?? 'Unknown Spoonacular Item',
      subtitle: data['brand'],
      description: data['description'] ?? data['generatedText'],
      imageUrl: data['image'] ??
          (data['images'] != null && (data['images'] as List).isNotEmpty
              ? data['images'].first
              : null),
      source: 'Spoonacular',
      details: details,
    );
  }
}
