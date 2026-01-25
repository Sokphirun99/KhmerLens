// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KhmerScan';

  @override
  String get scanDocument => 'Scan Document';

  @override
  String get all => 'All';

  @override
  String get birthCertificate => 'Birth Certificate';

  @override
  String get idCard => 'ID Card';

  @override
  String get familyBook => 'Family Book';

  @override
  String get marriageCertificate => 'Marriage Certificate';

  @override
  String get other => 'Other';

  @override
  String get saving => 'Saving...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get emptyStateMessage => 'No documents';

  @override
  String get emptyStateFilteredMessage => 'No documents in this category';

  @override
  String get emptyStateDescription => 'Tap the button below to start scanning';

  @override
  String get emptyStateFilteredDescription =>
      'Please select another category or scan a new document';

  @override
  String get showAll => 'Show All';

  @override
  String get deleteDocument => 'Delete Document';

  @override
  String get deleteDocumentConfirmation =>
      'Are you sure you want to delete this document? This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get shareComingSoon => 'Share feature coming soon';

  @override
  String get deletedSuccess => 'Document deleted';

  @override
  String showCategoryTooltip(Object category) {
    return 'Show $category documents';
  }
}
