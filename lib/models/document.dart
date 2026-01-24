import 'dart:convert';
import 'document_category.dart';

class Document {
  final String id;
  final String title;
  final DocumentCategory category;
  final List<String> imagePaths;
  final String? extractedText;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final Map<String, dynamic>? metadata;

  Document({
    required this.id,
    required this.title,
    required this.category,
    required this.imagePaths,
    this.extractedText,
    required this.createdAt,
    this.expiryDate,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'imagePaths': jsonEncode(imagePaths),
      'extractedText': extractedText,
      'createdAt': createdAt.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      category: DocumentCategory.values.byName(map['category']),
      imagePaths: map['imagePaths'] != null
          ? List<String>.from(jsonDecode(map['imagePaths']))
          : [],
      extractedText: map['extractedText'],
      createdAt: DateTime.parse(map['createdAt']),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'])
          : null,
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'])
          : null,
    );
  }

  Document copyWith({
    String? title,
    List<String>? imagePaths,
    String? extractedText,
    DateTime? expiryDate,
    Map<String, dynamic>? metadata,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      category: category,
      imagePaths: imagePaths ?? this.imagePaths,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
      metadata: metadata ?? this.metadata,
    );
  }
}
