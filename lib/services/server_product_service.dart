import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../screens/product_scan_screen.dart';
import 'spoonacular_service.dart';
import 'usda_service.dart';
import 'open_fda_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for checking global product cache and fetching from APIs
/// Implements "Client-side Cache" pattern:
/// 1. Check Firestore (Global Cache)
/// 2. If miss, fetch from external APIs (Spoonacular, USDA, etc.)
/// 3. If found, save to Firestore for future users
class ServerProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // existing services
  final SpoonacularService _spoonacularService = SpoonacularService();
  final UsdaService _usdaService = UsdaService();
  final OpenFdaService _openFdaService = OpenFdaService();

  /// Fetch product by barcode
  Future<ProductInfo?> fetchProductByBarcode(String barcode) async {
    try {
      // 1. Check Firestore Cache
      final docRef = _firestore.collection('products').doc(barcode);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        debugPrint('ServerProductService: CACHE HIT for $barcode');

        // Update analytics (fire-and-forget)
        try {
          // Lazy Sign-in for stats
          if (FirebaseAuth.instance.currentUser == null) {
            await FirebaseAuth.instance.signInAnonymously();
          }

          if (FirebaseAuth.instance.currentUser != null) {
            docRef.update({
              'scanCount': FieldValue.increment(1),
              'lastScannedAt': FieldValue.serverTimestamp(),
            }).catchError((e) => debugPrint('Error updating stats: $e'));
          }
        } catch (e) {
          debugPrint('Error ensuring auth for stats: $e');
        }

        final data = docSnap.data()!;
        return _mapFirestoreDataToProduct(data, 'Firestore Cache');
      }

      // 2. Cache Miss - Query External APIs
      debugPrint(
          'ServerProductService: CACHE MISS for $barcode - Querying APIs...');

      ProductInfo? product = await _queryExternalAPIs(barcode);

      if (product != null) {
        // 3. Save to Firestore
        await saveProductToFirestore(barcode, product);
        return product;
      }

      return null;
    } catch (e) {
      debugPrint('ServerProductService Error: $e');
      return null;
    }
  }

  /// Waterfall API queries
  Future<ProductInfo?> _queryExternalAPIs(String barcode) async {
    // Try Spoonacular
    try {
      final spoonData = await _spoonacularService.fetchProductByUpc(barcode);
      if (spoonData != null) {
        return spoonData;
      }
    } catch (e) {
      debugPrint('Spoonacular error: $e');
    }

    // Try USDA
    try {
      final usdaData = await _usdaService.fetchProductByUpc(barcode);
      if (usdaData != null) {
        return usdaData;
      }
    } catch (e) {
      debugPrint('USDA error: $e');
    }

    // Try OpenFDA
    try {
      final fdaData = await _openFdaService.fetchProductByUpc(barcode);
      if (fdaData != null) {
        return fdaData;
      }
    } catch (e) {
      debugPrint('OpenFDA error: $e');
    }

    // Try UPCitemdb (Trial)
    try {
      final upcUrl =
          Uri.parse('https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode');
      final response = await http.get(upcUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['total'] > 0) {
          final item = data['items'][0];
          return ProductInfo(
            title: item['title'] ?? 'Unknown Product',
            subtitle: item['brand'],
            description: item['description'],
            imageUrl:
                (item['images'] as List).isNotEmpty ? item['images'][0] : null,
            source: 'UPCitemdb',
            details: {
              'category': item['category'] ?? '',
              'ean': item['ean'] ?? '',
            },
          );
        }
      }
    } catch (e) {
      debugPrint('UPCitemdb error: $e');
    }

    return null;
  }

  Future<void> saveProductToFirestore(
      String barcode, ProductInfo product) async {
    try {
      // Lazy Sign-in: Ensure we have a user before writing
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint(
            'ServerProductService: User unauthenticated. Attempting anonymous sign-in...');
        try {
          await FirebaseAuth.instance.signInAnonymously();
          debugPrint(
              'ServerProductService: Signed in anonymously for write operation.');
        } catch (e) {
          debugPrint('ServerProductService: Failed to sign in anonymously: $e');
          return;
        }
      }

      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint(
            'ServerProductService: Still unauthenticated after attempt. Skipping write.');
        return;
      }

      await _firestore.collection('products').doc(barcode).set({
        'barcode': barcode,
        'title': product.title,
        'subtitle': product.subtitle,
        'description': product.description,
        'imageUrl': product.imageUrl,
        'source': product.source,
        'details': product.details,
        'scanCount': 1,
        'firstScannedAt': FieldValue.serverTimestamp(),
        'lastScannedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Saved $barcode to Firestore');
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
  }

  ProductInfo _mapFirestoreDataToProduct(
      Map<String, dynamic> data, String sourceOverride) {
    return ProductInfo(
      title: data['title'] ?? 'Unknown Product',
      subtitle: data['subtitle'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      source: sourceOverride, // 'Firestore Cache'
      details: _convertDetails(data['details']),
    );
  }

  Map<String, String> _convertDetails(dynamic details) {
    if (details == null) return {};
    if (details is Map<String, String>) return details;
    if (details is Map) {
      return details.map((key, value) => MapEntry(
            key.toString(),
            value?.toString() ?? '',
          ));
    }
    return {};
  }
}
