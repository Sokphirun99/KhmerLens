// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'KhmerScan';

  @override
  String get scanDocument => 'ស្កេនឯកសារ';

  @override
  String get all => 'ទាំងអស់';

  @override
  String get birthCertificate => 'សំបុត្រកំណើត';

  @override
  String get idCard => 'អត្តសញ្ញាណប័ណ្ណ';

  @override
  String get familyBook => 'សៀវភៅគ្រួសារ';

  @override
  String get marriageCertificate => 'សំបុត្រអាពាហ៍ពិពាហ៍';

  @override
  String get other => 'ផ្សេងៗ';

  @override
  String get saving => 'កំពុងរក្សាទុក...';

  @override
  String get error => 'មានបញ្ហា';

  @override
  String get retry => 'ព្យាយាមម្តងទៀត';

  @override
  String get emptyStateMessage => 'គ្មានឯកសារ';

  @override
  String get emptyStateFilteredMessage => 'គ្មានឯកសារក្នុងប្រភេទនេះ';

  @override
  String get emptyStateDescription =>
      'ចុចប៊ូតុងខាងក្រោមដើម្បីចាប់ផ្តើមស្កេនឯកសាររបស់អ្នក';

  @override
  String get emptyStateFilteredDescription =>
      'សូមជ្រើសរើសប្រភេទផ្សេង ឬស្កេនឯកសារថ្មី';

  @override
  String get showAll => 'បង្ហាញទាំងអស់';

  @override
  String get deleteDocument => 'លុបឯកសារ';

  @override
  String get deleteDocumentConfirmation =>
      'តើអ្នកពិតជាចង់លុបឯកសារនេះមែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get delete => 'លុប';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get shareComingSoon => 'មុខងារចែករំលែកនឹងមកដល់ឆាប់ៗនេះ';

  @override
  String get deletedSuccess => 'បានលុបឯកសារ';

  @override
  String showCategoryTooltip(Object category) {
    return 'បង្ហាញឯកសារប្រភេទ $category';
  }
}
