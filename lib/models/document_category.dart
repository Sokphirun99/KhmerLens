import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum DocumentCategory {
  birthCertificate,
  nationalID,
  familyBook,
  marriageCertificate,
  other;

  String get nameKhmer {
    switch (this) {
      case DocumentCategory.birthCertificate:
        return 'សំបុត្រកំណើត';
      case DocumentCategory.nationalID:
        return 'អត្តសញ្ញាណប័ណ្ណ';
      case DocumentCategory.familyBook:
        return 'សៀវភៅគ្រួសារ';
      case DocumentCategory.marriageCertificate:
        return 'សំបុត្ររៀបការ';
      case DocumentCategory.other:
        return 'ផ្សេងៗ';
    }
  }

  String get nameEnglish {
    switch (this) {
      case DocumentCategory.birthCertificate:
        return 'Birth Certificate';
      case DocumentCategory.nationalID:
        return 'National ID';
      case DocumentCategory.familyBook:
        return 'Family Book';
      case DocumentCategory.marriageCertificate:
        return 'Marriage Certificate';
      case DocumentCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentCategory.birthCertificate:
        return Icons.child_care;
      case DocumentCategory.nationalID:
        return Icons.badge;
      case DocumentCategory.familyBook:
        return Icons.family_restroom;
      case DocumentCategory.marriageCertificate:
        return Icons.favorite;
      case DocumentCategory.other:
        return Icons.description;
    }
  }

  Color get color {
    switch (this) {
      case DocumentCategory.birthCertificate:
        return AppConstants.categoryColors['birthCertificate']!;
      case DocumentCategory.nationalID:
        return AppConstants.categoryColors['nationalID']!;
      case DocumentCategory.familyBook:
        return AppConstants.categoryColors['familyBook']!;
      case DocumentCategory.marriageCertificate:
        return AppConstants.categoryColors['marriageCertificate']!;
      case DocumentCategory.other:
        return AppConstants.categoryColors['other']!;
    }
  }
}
