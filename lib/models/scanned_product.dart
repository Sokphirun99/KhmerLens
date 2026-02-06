import 'dart:convert';

class ScannedProduct {
  final String id;
  final String barcode;
  final String title;
  final String? description;
  final String? imageUrl;
  final String source;
  final DateTime scannedAt;
  final Map<String, dynamic>? details;

  ScannedProduct({
    required this.id,
    required this.barcode,
    required this.title,
    this.description,
    this.imageUrl,
    required this.source,
    required this.scannedAt,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'source': source,
      'scannedAt': scannedAt.toIso8601String(),
      'details': details != null ? json.encode(details) : null,
    };
  }

  factory ScannedProduct.fromMap(Map<String, dynamic> map) {
    return ScannedProduct(
      id: map['id'],
      barcode: map['barcode'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      source: map['source'],
      scannedAt: DateTime.parse(map['scannedAt']),
      details: map['details'] != null
          ? json.decode(map['details']) as Map<String, dynamic>
          : null,
    );
  }
}
