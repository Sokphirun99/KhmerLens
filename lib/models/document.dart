import 'dart:convert';
import 'document_category.dart';

class Document {
  final String id;
  final String title;
  final DocumentCategory category;
  final String imagePath;
  final String? extractedText;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final Map<String, dynamic>? metadata;

  Document({
    required this.id,
    required this.title,
    required this.category,
    required this.imagePath,
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
      'imagePath': imagePath,
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
      imagePath: map['imagePath'],
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
    String? extractedText,
    DateTime? expiryDate,
    Map<String, dynamic>? metadata,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      category: category,
      imagePath: imagePath,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
      metadata: metadata ?? this.metadata,
    );
  }
}
