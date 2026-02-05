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
    final details = <String, String>{
      if (data['brand'] != null) 'Brand': data['brand'],
      if (data['aisle'] != null) 'Aisle': data['aisle'],
    };

    // Extract bad ingredients if any
    if (data['badges'] != null) {
      final badges = (data['badges'] as List).join(', ');
      if (badges.isNotEmpty) {
        details['Badges'] = badges;
      }
    }

    if (data['importantBadges'] != null) {
      final impBadges = (data['importantBadges'] as List).join(', ');
      if (impBadges.isNotEmpty) {
        details['Important'] = impBadges;
      }
    }

    // Serving info
    if (data['serving_size'] != null) {
      details['Serving Size'] =
          '${data['serving_size']} ${data['serving_size_unit'] ?? ''}';
    }

    return ProductInfo(
      title: data['title'] ?? 'Unknown Spoonacular Item',
      subtitle: data['brand'],
      description: data['description'] ?? data['generatedText'],
      imageUrl: data['image'] ?? data['images']?.first,
      source: 'Spoonacular',
      details: details,
    );
  }
}
