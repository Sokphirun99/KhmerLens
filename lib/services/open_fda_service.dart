import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../screens/product_scan_screen.dart';

class OpenFdaService {
  static const String _baseUrl = 'https://api.fda.gov/drug';

  /// Fetches drug information from openFDA API using NDC (National Drug Code) or UPC.
  /// Note: openFDA primarily searches by NDC. We will try to map UPC to NDC-like queries
  /// or search in the 'openfda.upc' field if available (it's part of the UDI dataset sometimes).
  /// For simplicity, we search the `openfda.upc` field in the drug labeling endpoint.
  Future<ProductInfo?> fetchProductByUpc(String upc) async {
    try {
      // Search in drug labels endpoint locally for UPC
      // The openFDA often stores UPCs inside the `openfda.upc` array.
      // Query syntax: search=openfda.upc:"<UPC>"
      final query = 'openfda.upc:"$upc"';
      String url =
          '$_baseUrl/label.json?search=${Uri.encodeComponent(query)}&limit=1';
      if (AppConfig.openFdaApiKey.isNotEmpty) {
        url += '&api_key=${AppConfig.openFdaApiKey}';
      }
      final uri = Uri.parse(url);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          return _mapToProductInfo(result);
        }
      } else if (response.statusCode != 404) {
        // 404 just means not found, other errors we log
        debugPrint(
            'openFDA API Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('openFDA API Exception: $e');
    }
    return null;
  }

  ProductInfo _mapToProductInfo(Map<String, dynamic> data) {
    final openfda = data['openfda'] ?? {};

    final details = <String, String>{
      if (openfda['manufacturer_name'] != null)
        'Manufacturer': (openfda['manufacturer_name'] as List).join(', '),
      if (openfda['product_type'] != null)
        'Type': (openfda['product_type'] as List).join(', '),
      if (openfda['route'] != null)
        'Route': (openfda['route'] as List).join(', '),
    };

    // Warnings and Usage
    String? description;
    if (data['indications_and_usage'] != null) {
      description = (data['indications_and_usage'] as List)
          .join('\n')
          .replaceAll(RegExp(r'\[.*?\]'), ''); // Clean simpler brackets
    }

    if (data['warnings'] != null) {
      final warnings = (data['warnings'] as List).join('\n');
      if (warnings.isNotEmpty) {
        details['Warnings'] = warnings.length > 200
            ? '${warnings.substring(0, 200)}...'
            : warnings;
      }
    }

    if (data['do_not_use'] != null) {
      final dnu = (data['do_not_use'] as List).join('\n');
      if (dnu.isNotEmpty) {
        details['Do Not Use'] = dnu;
      }
    }

    final brandName = openfda['brand_name'] != null
        ? (openfda['brand_name'] as List).first
        : 'Unknown Drug';
    final genericName = openfda['generic_name'] != null
        ? (openfda['generic_name'] as List).first
        : null;

    return ProductInfo(
      title: brandName,
      subtitle: genericName,
      description: description,
      imageUrl: null, // openFDA does not provide images generally
      source: 'openFDA (Drug Label)',
      details: details,
    );
  }
}
