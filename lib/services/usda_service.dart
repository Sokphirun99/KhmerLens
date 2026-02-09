import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../screens/product_scan_screen.dart';

class UsdaService {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// Fetches product information from USDA API using UPC/EAN/Barcode.
  /// Returns a [ProductInfo] object if found, otherwise null.
  Future<ProductInfo?> fetchProductByUpc(String upc) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/foods/search?api_key=${AppConfig.usdaApiKey}&query=${Uri.encodeComponent(upc)}');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> foods = data['foods'];

        if (foods.isNotEmpty) {
          final food = foods.first;
          return _mapToProductInfo(food);
        }
      } else {
        debugPrint(
            'USDA API Error: ${response.statusCode} - ${response.reasonPhrase}');
        debugPrint('USDA API Response Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('USDA API Exception: $e');
    }
    return null;
  }

  ProductInfo _mapToProductInfo(Map<String, dynamic> food) {
    // Extract nutrients
    final List<dynamic> nutrients = food['foodNutrients'] ?? [];
    String? getStringNutrient(String name) {
      final n = nutrients.firstWhere(
        (element) => element['nutrientName'] == name,
        orElse: () => null,
      );
      return n != null ? '${n['value']} ${n['unitName']}' : null;
    }

    final details = <String, String>{
      if (food['brandOwner'] != null) 'Brand Owner': food['brandOwner'],
      if (food['marketCountry'] != null)
        'Market Country': food['marketCountry'],
      if (food['foodCategory'] != null) 'Category': food['foodCategory'],
    };

    // Add common nutrients if available
    final protein = getStringNutrient('Protein');
    if (protein != null) details['Protein'] = protein;

    final energy = getStringNutrient('Energy');
    if (energy != null) details['Energy'] = energy;

    final carbs = getStringNutrient('Carbohydrate, by difference');
    if (carbs != null) details['Carbs'] = carbs;

    return ProductInfo(
      title: food['description'] ?? 'Unknown USDA Food',
      subtitle: food['brandOwner'],
      description: food['ingredients'] ?? food['additionalDescriptions'],
      // USDA API doesn't always provide a direct image URL in the simple search response
      // or it varies greatly. We leave it null or could implement a fallback image logic.
      imageUrl: null,
      source: 'USDA FoodData Central',
      details: details,
    );
  }
}
