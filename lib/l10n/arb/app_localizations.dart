import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km')
  ];

  /// No description provided for @appTitle.
  ///
  /// In km, this message translates to:
  /// **'KhmerScan'**
  String get appTitle;

  /// No description provided for @scanDocument.
  ///
  /// In km, this message translates to:
  /// **'ស្កេនឯកសារ'**
  String get scanDocument;

  /// No description provided for @all.
  ///
  /// In km, this message translates to:
  /// **'ទាំងអស់'**
  String get all;

  /// No description provided for @birthCertificate.
  ///
  /// In km, this message translates to:
  /// **'សំបុត្រកំណើត'**
  String get birthCertificate;

  /// No description provided for @idCard.
  ///
  /// In km, this message translates to:
  /// **'អត្តសញ្ញាណប័ណ្ណ'**
  String get idCard;

  /// No description provided for @familyBook.
  ///
  /// In km, this message translates to:
  /// **'សៀវភៅគ្រួសារ'**
  String get familyBook;

  /// No description provided for @marriageCertificate.
  ///
  /// In km, this message translates to:
  /// **'សំបុត្រអាពាហ៍ពិពាហ៍'**
  String get marriageCertificate;

  /// No description provided for @other.
  ///
  /// In km, this message translates to:
  /// **'ផ្សេងៗ'**
  String get other;

  /// No description provided for @saving.
  ///
  /// In km, this message translates to:
  /// **'កំពុងរក្សាទុក...'**
  String get saving;

  /// No description provided for @error.
  ///
  /// In km, this message translates to:
  /// **'មានបញ្ហា'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In km, this message translates to:
  /// **'ព្យាយាមម្តងទៀត'**
  String get retry;

  /// No description provided for @emptyStateMessage.
  ///
  /// In km, this message translates to:
  /// **'គ្មានឯកសារ'**
  String get emptyStateMessage;

  /// No description provided for @emptyStateFilteredMessage.
  ///
  /// In km, this message translates to:
  /// **'គ្មានឯកសារក្នុងប្រភេទនេះ'**
  String get emptyStateFilteredMessage;

  /// No description provided for @emptyStateDescription.
  ///
  /// In km, this message translates to:
  /// **'ចុចប៊ូតុងខាងក្រោមដើម្បីចាប់ផ្តើមស្កេនឯកសាររបស់អ្នក'**
  String get emptyStateDescription;

  /// No description provided for @emptyStateFilteredDescription.
  ///
  /// In km, this message translates to:
  /// **'សូមជ្រើសរើសប្រភេទផ្សេង ឬស្កេនឯកសារថ្មី'**
  String get emptyStateFilteredDescription;

  /// No description provided for @showAll.
  ///
  /// In km, this message translates to:
  /// **'បង្ហាញទាំងអស់'**
  String get showAll;

  /// No description provided for @deleteDocument.
  ///
  /// In km, this message translates to:
  /// **'លុបឯកសារ'**
  String get deleteDocument;

  /// No description provided for @deleteDocumentConfirmation.
  ///
  /// In km, this message translates to:
  /// **'តើអ្នកពិតជាចង់លុបឯកសារនេះមែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។'**
  String get deleteDocumentConfirmation;

  /// No description provided for @delete.
  ///
  /// In km, this message translates to:
  /// **'លុប'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In km, this message translates to:
  /// **'បោះបង់'**
  String get cancel;

  /// No description provided for @shareComingSoon.
  ///
  /// In km, this message translates to:
  /// **'មុខងារចែករំលែកនឹងមកដល់ឆាប់ៗនេះ'**
  String get shareComingSoon;

  /// No description provided for @deletedSuccess.
  ///
  /// In km, this message translates to:
  /// **'បានលុបឯកសារ'**
  String get deletedSuccess;

  /// No description provided for @showCategoryTooltip.
  ///
  /// In km, this message translates to:
  /// **'បង្ហាញឯកសារប្រភេទ {category}'**
  String showCategoryTooltip(Object category);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
