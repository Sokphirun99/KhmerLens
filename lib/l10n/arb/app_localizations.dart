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
  /// **'KhmerLens'**
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

  /// No description provided for @emptyStateDescription.
  ///
  /// In km, this message translates to:
  /// **'ចុចប៊ូតុងខាងក្រោមដើម្បីចាប់ផ្តើមស្កេនឯកសាររបស់អ្នក'**
  String get emptyStateDescription;

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

  /// No description provided for @settings.
  ///
  /// In km, this message translates to:
  /// **'ការកំណត់'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In km, this message translates to:
  /// **'ត្រឡប់ក្រោយ'**
  String get back;

  /// No description provided for @appearance.
  ///
  /// In km, this message translates to:
  /// **'រូបរាង'**
  String get appearance;

  /// No description provided for @displayMode.
  ///
  /// In km, this message translates to:
  /// **'របៀបបង្ហាញ'**
  String get displayMode;

  /// No description provided for @light.
  ///
  /// In km, this message translates to:
  /// **'ភ្លឺ'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In km, this message translates to:
  /// **'ងងឹត'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In km, this message translates to:
  /// **'ប្រព័ន្ធ'**
  String get system;

  /// No description provided for @chooseDisplayMode.
  ///
  /// In km, this message translates to:
  /// **'ជ្រើសរើសរបៀបបង្ហាញ'**
  String get chooseDisplayMode;

  /// No description provided for @useDeviceSettings.
  ///
  /// In km, this message translates to:
  /// **'ប្រើការកំណត់ពីឧបករណ៍'**
  String get useDeviceSettings;

  /// No description provided for @language.
  ///
  /// In km, this message translates to:
  /// **'ភាសា'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In km, this message translates to:
  /// **'ជ្រើសរើសភាសា'**
  String get chooseLanguage;

  /// No description provided for @khmer.
  ///
  /// In km, this message translates to:
  /// **'ខ្មែរ'**
  String get khmer;

  /// No description provided for @english.
  ///
  /// In km, this message translates to:
  /// **'អង់គ្លេស'**
  String get english;

  /// No description provided for @storage.
  ///
  /// In km, this message translates to:
  /// **'ទំហំផ្ទុក'**
  String get storage;

  /// No description provided for @documentCount.
  ///
  /// In km, this message translates to:
  /// **'ចំនួនឯកសារ'**
  String get documentCount;

  /// No description provided for @documents.
  ///
  /// In km, this message translates to:
  /// **'ឯកសារ'**
  String get documents;

  /// No description provided for @counting.
  ///
  /// In km, this message translates to:
  /// **'កំពុងរាប់...'**
  String get counting;

  /// No description provided for @storageUsed.
  ///
  /// In km, this message translates to:
  /// **'ទំហំផ្ទុកដែលប្រើ'**
  String get storageUsed;

  /// No description provided for @clearCache.
  ///
  /// In km, this message translates to:
  /// **'សម្អាតឃ្លាំង'**
  String get clearCache;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In km, this message translates to:
  /// **'លុបទិន្នន័យបណ្ដោះអាសន្ន'**
  String get clearCacheSubtitle;

  /// No description provided for @clearCacheTitle.
  ///
  /// In km, this message translates to:
  /// **'សម្អាតឃ្លាំង'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheMessage.
  ///
  /// In km, this message translates to:
  /// **'តើអ្នកពិតជាចង់លុបទិន្នន័យបណ្ដោះអាសន្នទាំងអស់មែនទេ? សកម្មភាពនេះនឹងមិនលុបឯកសាររបស់អ្នកទេ។'**
  String get clearCacheMessage;

  /// No description provided for @deleteAllDocuments.
  ///
  /// In km, this message translates to:
  /// **'លុបឯកសារទាំងអស់'**
  String get deleteAllDocuments;

  /// No description provided for @deleteAllDocumentsSubtitle.
  ///
  /// In km, this message translates to:
  /// **'លុបឯកសារដែលបានស្កែនទាំងអស់'**
  String get deleteAllDocumentsSubtitle;

  /// No description provided for @deleteAllDocumentsTitle.
  ///
  /// In km, this message translates to:
  /// **'លុបឯកសារទាំងអស់'**
  String get deleteAllDocumentsTitle;

  /// No description provided for @deleteAllDocumentsMessage.
  ///
  /// In km, this message translates to:
  /// **'តើអ្នកពិតជាចង់លុបឯកសារទាំងអស់មែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ ហើយអ្នកនឹងបាត់បង់ឯកសារទាំងអស់។'**
  String get deleteAllDocumentsMessage;

  /// No description provided for @documentsDeleted.
  ///
  /// In km, this message translates to:
  /// **'ឯកសារទាំងអស់ត្រូវបានលុប'**
  String get documentsDeleted;

  /// No description provided for @clear.
  ///
  /// In km, this message translates to:
  /// **'សម្អាត'**
  String get clear;

  /// No description provided for @cacheCleared.
  ///
  /// In km, this message translates to:
  /// **'បានសម្អាតឃ្លាំង'**
  String get cacheCleared;

  /// No description provided for @unableToCalculate.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចគណនាបាន'**
  String get unableToCalculate;

  /// No description provided for @aboutApp.
  ///
  /// In km, this message translates to:
  /// **'អំពីកម្មវិធី'**
  String get aboutApp;

  /// No description provided for @app.
  ///
  /// In km, this message translates to:
  /// **'កម្មវិធី'**
  String get app;

  /// No description provided for @version.
  ///
  /// In km, this message translates to:
  /// **'កំណែ'**
  String get version;

  /// No description provided for @license.
  ///
  /// In km, this message translates to:
  /// **'អាជ្ញាប័ណ្ណ'**
  String get license;

  /// No description provided for @tapToViewLicense.
  ///
  /// In km, this message translates to:
  /// **'ចុចដើម្បីមើលអាជ្ញាប័ណ្ណ'**
  String get tapToViewLicense;

  /// No description provided for @support.
  ///
  /// In km, this message translates to:
  /// **'ជំនួយ'**
  String get support;

  /// No description provided for @rateApp.
  ///
  /// In km, this message translates to:
  /// **'វាយតម្លៃកម្មវិធី'**
  String get rateApp;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In km, this message translates to:
  /// **'ជួយយើងកែលម្អដោយការវាយតម្លៃ'**
  String get rateAppSubtitle;

  /// No description provided for @shareApp.
  ///
  /// In km, this message translates to:
  /// **'ចែករំលែកកម្មវិធី'**
  String get shareApp;

  /// No description provided for @shareAppSubtitle.
  ///
  /// In km, this message translates to:
  /// **'ប្រាប់មិត្តភក្តិអំពីកម្មវិធីនេះ'**
  String get shareAppSubtitle;

  /// No description provided for @reportBug.
  ///
  /// In km, this message translates to:
  /// **'រាយការណ៍បញ្ហា'**
  String get reportBug;

  /// No description provided for @reportBugSubtitle.
  ///
  /// In km, this message translates to:
  /// **'ប្រាប់យើងប្រសិនបើអ្នកជួបបញ្ហា'**
  String get reportBugSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In km, this message translates to:
  /// **'គោលការណ៍ភាពឯកជន'**
  String get privacyPolicy;

  /// No description provided for @featureComingSoon.
  ///
  /// In km, this message translates to:
  /// **'មុខងារនេះនឹងមានក្នុងពេលឆាប់ៗ'**
  String get featureComingSoon;

  /// No description provided for @preparingToShare.
  ///
  /// In km, this message translates to:
  /// **'កំពុងរៀបចំឯកសារសម្រាប់ចែករំលែក...'**
  String get preparingToShare;

  /// No description provided for @unableToShare.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចចែករំលែកឯកសារ'**
  String get unableToShare;

  /// No description provided for @exportingPdf.
  ///
  /// In km, this message translates to:
  /// **'កំពុងនាំចេញជា PDF...'**
  String get exportingPdf;

  /// No description provided for @unableToExportPdf.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចនាំចេញជា PDF'**
  String get unableToExportPdf;

  /// No description provided for @takePhoto.
  ///
  /// In km, this message translates to:
  /// **'ថតរូប'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In km, this message translates to:
  /// **'ជ្រើសរូបពីវិចិត្រសាល'**
  String get chooseFromGallery;

  /// No description provided for @addingImages.
  ///
  /// In km, this message translates to:
  /// **'កំពុងបន្ថែមរូបភាព...'**
  String get addingImages;

  /// No description provided for @unableToAddImages.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចបន្ថែមរូបភាព'**
  String get unableToAddImages;

  /// No description provided for @cannotDeleteLastImage.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចលុបរូបភាពចុងក្រោយបានទេ'**
  String get cannotDeleteLastImage;

  /// No description provided for @deleteImage.
  ///
  /// In km, this message translates to:
  /// **'លុបរូបភាព'**
  String get deleteImage;

  /// No description provided for @deleteImageConfirmation.
  ///
  /// In km, this message translates to:
  /// **'តើអ្នកពិតជាចង់លុបរូបភាពនេះមែនទេ?'**
  String get deleteImageConfirmation;

  /// No description provided for @unableToReorderImages.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចរៀបចំរូបភាពឡើងវិញ'**
  String get unableToReorderImages;

  /// No description provided for @addImages.
  ///
  /// In km, this message translates to:
  /// **'បន្ថែមរូបភាព'**
  String get addImages;

  /// No description provided for @manageImages.
  ///
  /// In km, this message translates to:
  /// **'គ្រប់គ្រងរូបភាព'**
  String get manageImages;

  /// No description provided for @share.
  ///
  /// In km, this message translates to:
  /// **'ចែករំលែក'**
  String get share;

  /// No description provided for @exportPdf.
  ///
  /// In km, this message translates to:
  /// **'នាំចេញជា PDF'**
  String get exportPdf;

  /// No description provided for @noImagesInDocument.
  ///
  /// In km, this message translates to:
  /// **'គ្មានរូបភាពក្នុងឯកសារ'**
  String get noImagesInDocument;

  /// No description provided for @pleaseAddImages.
  ///
  /// In km, this message translates to:
  /// **'សូមថែមរូបភាពថ្មី'**
  String get pleaseAddImages;

  /// No description provided for @unableToLoadImage.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចផ្ទុករូបភាព'**
  String get unableToLoadImage;

  /// No description provided for @documentInfo.
  ///
  /// In km, this message translates to:
  /// **'ព័ត៌មានឯកសារ'**
  String get documentInfo;

  /// No description provided for @generalInfo.
  ///
  /// In km, this message translates to:
  /// **'ព័ត៌មានទូទៅ'**
  String get generalInfo;

  /// No description provided for @created.
  ///
  /// In km, this message translates to:
  /// **'បង្កើត'**
  String get created;

  /// No description provided for @expires.
  ///
  /// In km, this message translates to:
  /// **'ផុតកំណត់'**
  String get expires;

  /// No description provided for @technicalInfo.
  ///
  /// In km, this message translates to:
  /// **'ព័ត៌មានបច្ចេកទេស'**
  String get technicalInfo;

  /// No description provided for @id.
  ///
  /// In km, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @images.
  ///
  /// In km, this message translates to:
  /// **'រូបភាព'**
  String get images;

  /// No description provided for @imageCount.
  ///
  /// In km, this message translates to:
  /// **'{count} រូប'**
  String imageCount(int count);

  /// No description provided for @unableToLoad.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចផ្ទុក'**
  String get unableToLoad;

  /// No description provided for @loading.
  ///
  /// In km, this message translates to:
  /// **'កំពុងផ្ទុក...'**
  String get loading;

  /// No description provided for @size.
  ///
  /// In km, this message translates to:
  /// **'ទំហំ'**
  String get size;

  /// No description provided for @add.
  ///
  /// In km, this message translates to:
  /// **'បន្ថែម'**
  String get add;

  /// No description provided for @noCameraFound.
  ///
  /// In km, this message translates to:
  /// **'រកមិនឃើញកាមេរ៉ា'**
  String get noCameraFound;

  /// No description provided for @cameraInitError.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចចាប់ផ្តើមកាមេរ៉ាបានទេ'**
  String get cameraInitError;

  /// No description provided for @imageCaptured.
  ///
  /// In km, this message translates to:
  /// **'រូបភាពទី {count} ត្រូវបានថតរួច'**
  String imageCaptured(int count);

  /// No description provided for @finish.
  ///
  /// In km, this message translates to:
  /// **'បញ្ចប់'**
  String get finish;

  /// No description provided for @captureError.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចថតរូបភាពបានទេ'**
  String get captureError;

  /// No description provided for @flashOn.
  ///
  /// In km, this message translates to:
  /// **'បើកភ្លើង'**
  String get flashOn;

  /// No description provided for @flashOff.
  ///
  /// In km, this message translates to:
  /// **'បិទភ្លើង'**
  String get flashOff;

  /// No description provided for @singlePageMode.
  ///
  /// In km, this message translates to:
  /// **'ម៉ូដទំព័រតែមួយ (រហ័ស)'**
  String get singlePageMode;

  /// No description provided for @multiPageMode.
  ///
  /// In km, this message translates to:
  /// **'ម៉ូដច្រើនទំព័រ'**
  String get multiPageMode;

  /// No description provided for @pickImageError.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចជ្រើសរូបភាពបានទេ'**
  String get pickImageError;

  /// No description provided for @startingCamera.
  ///
  /// In km, this message translates to:
  /// **'កំពុងចាប់ផ្តើមកាមេរ៉ា...'**
  String get startingCamera;

  /// No description provided for @alignDocument.
  ///
  /// In km, this message translates to:
  /// **'រៀបចំឯកសារក្នុងក្របនេះ'**
  String get alignDocument;

  /// No description provided for @close.
  ///
  /// In km, this message translates to:
  /// **'បិទ'**
  String get close;

  /// No description provided for @modeSingle.
  ///
  /// In km, this message translates to:
  /// **'១រូប'**
  String get modeSingle;

  /// No description provided for @modeMulti.
  ///
  /// In km, this message translates to:
  /// **'ច្រើន'**
  String get modeMulti;

  /// No description provided for @imageDeleted.
  ///
  /// In km, this message translates to:
  /// **'រូបភាពត្រូវបានលុបចេញ'**
  String get imageDeleted;

  /// No description provided for @documentPrefix.
  ///
  /// In km, this message translates to:
  /// **'ឯកសារ'**
  String get documentPrefix;

  /// No description provided for @searchDocumentsHint.
  ///
  /// In km, this message translates to:
  /// **'ស្វែងរកឯកសារ...'**
  String get searchDocumentsHint;

  /// No description provided for @searching.
  ///
  /// In km, this message translates to:
  /// **'កំពុងស្វែងរក...'**
  String get searching;

  /// No description provided for @searchError.
  ///
  /// In km, this message translates to:
  /// **'កំហុសក្នុងការស្វែងរក'**
  String get searchError;

  /// No description provided for @foundResults.
  ///
  /// In km, this message translates to:
  /// **'រកឃើញ {count} លទ្ធផល'**
  String foundResults(int count);

  /// No description provided for @cannotDeleteDocument.
  ///
  /// In km, this message translates to:
  /// **'មិនអាចលុបឯកសារ'**
  String get cannotDeleteDocument;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In km, this message translates to:
  /// **'បានលុបឯកសារដោយជោគជ័យ'**
  String get deletedSuccessfully;

  /// No description provided for @expired.
  ///
  /// In km, this message translates to:
  /// **'ផុតកំណត់'**
  String get expired;

  /// No description provided for @expiresOn.
  ///
  /// In km, this message translates to:
  /// **'ផុតកំណត់ {date}'**
  String expiresOn(String date);

  /// No description provided for @searchTips.
  ///
  /// In km, this message translates to:
  /// **'ការណែនាំស្វែងរក'**
  String get searchTips;

  /// No description provided for @searchByTypeOrText.
  ///
  /// In km, this message translates to:
  /// **'ស្វែងរកតាមប្រភេទឯកសារ ឬអត្ថបទដែលបានស្កេន'**
  String get searchByTypeOrText;

  /// No description provided for @searchByType.
  ///
  /// In km, this message translates to:
  /// **'ស្វែងរកតាមប្រភេទ'**
  String get searchByType;

  /// No description provided for @recentSearches.
  ///
  /// In km, this message translates to:
  /// **'ស្វែងរកថ្មីៗ'**
  String get recentSearches;

  /// No description provided for @typeToSearch.
  ///
  /// In km, this message translates to:
  /// **'វាយបញ្ចូលដើម្បីស្វែងរក'**
  String get typeToSearch;

  /// No description provided for @searchByNameOrText.
  ///
  /// In km, this message translates to:
  /// **'ស្វែងរកតាមឈ្មោះឯកសារ ឬអត្ថបទដែលបានស្កេន'**
  String get searchByNameOrText;

  /// No description provided for @noResultsFound.
  ///
  /// In km, this message translates to:
  /// **'រកមិនឃើញឯកសារ'**
  String get noResultsFound;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In km, this message translates to:
  /// **'សូមព្យាយាមស្វែងរកពាក្យផ្សេងទៀត'**
  String get tryDifferentKeywords;

  /// No description provided for @categoryIdCard.
  ///
  /// In km, this message translates to:
  /// **'អត្តសញ្ញាណប័ណ្ណ'**
  String get categoryIdCard;

  /// No description provided for @categoryPassport.
  ///
  /// In km, this message translates to:
  /// **'លិខិតឆ្លងដែន'**
  String get categoryPassport;

  /// No description provided for @categoryDriverLicense.
  ///
  /// In km, this message translates to:
  /// **'ប័ណ្ណបើកបរ'**
  String get categoryDriverLicense;

  /// No description provided for @categoryInvoice.
  ///
  /// In km, this message translates to:
  /// **'វិក្កយបត្រ'**
  String get categoryInvoice;

  /// No description provided for @categoryContract.
  ///
  /// In km, this message translates to:
  /// **'កិច្ចសន្យា'**
  String get categoryContract;

  /// No description provided for @print.
  ///
  /// In km, this message translates to:
  /// **'បោះពុម្ព'**
  String get print;

  /// No description provided for @textSize.
  ///
  /// In km, this message translates to:
  /// **'ទំហំអក្សរ'**
  String get textSize;

  /// No description provided for @textSizeSmall.
  ///
  /// In km, this message translates to:
  /// **'តូច'**
  String get textSizeSmall;

  /// No description provided for @textSizeMedium.
  ///
  /// In km, this message translates to:
  /// **'មធ្យម'**
  String get textSizeMedium;

  /// No description provided for @textSizeLarge.
  ///
  /// In km, this message translates to:
  /// **'ធំ'**
  String get textSizeLarge;

  /// No description provided for @dashboardWelcome.
  ///
  /// In km, this message translates to:
  /// **'តើអ្នកចង់ធ្វើអ្វី?'**
  String get dashboardWelcome;

  /// No description provided for @myDocuments.
  ///
  /// In km, this message translates to:
  /// **'ឯកសារខ្ញុំ'**
  String get myDocuments;

  /// No description provided for @myDocumentsDescription.
  ///
  /// In km, this message translates to:
  /// **'មើល និងគ្រប់គ្រងឯកសារដែលបានស្កេន'**
  String get myDocumentsDescription;

  /// No description provided for @scanDocumentDescription.
  ///
  /// In km, this message translates to:
  /// **'ស្កេនក្រដាស និងបង្កាន់ដៃ'**
  String get scanDocumentDescription;

  /// No description provided for @scanProduct.
  ///
  /// In km, this message translates to:
  /// **'ស្កេនផលិតផល'**
  String get scanProduct;

  /// No description provided for @scanProductDescription.
  ///
  /// In km, this message translates to:
  /// **'អានកូដ Barcode និង QR'**
  String get scanProductDescription;

  /// No description provided for @moreFeatures.
  ///
  /// In km, this message translates to:
  /// **'មុខងារបន្ថែម'**
  String get moreFeatures;

  /// No description provided for @moreFeaturesDescription.
  ///
  /// In km, this message translates to:
  /// **'មុខងារថ្មីៗនឹងមកដល់ឆាប់ៗ'**
  String get moreFeaturesDescription;

  /// No description provided for @productScanComingSoonDescription.
  ///
  /// In km, this message translates to:
  /// **'មុខងារស្កេន Barcode និង QR នឹងមានក្នុងការអាប់ដេតនាពេលអនាគត។'**
  String get productScanComingSoonDescription;

  /// No description provided for @greetingMorning.
  ///
  /// In km, this message translates to:
  /// **'អរុណសួស្តី!'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In km, this message translates to:
  /// **'ទិវាសួស្តី!'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In km, this message translates to:
  /// **'សាយ័ណសួស្តី!'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In km, this message translates to:
  /// **'រាត្រីសួស្តី!'**
  String get greetingNight;

  /// No description provided for @dashboardFeatures.
  ///
  /// In km, this message translates to:
  /// **'មុខងារ'**
  String get dashboardFeatures;

  /// No description provided for @scrollForMore.
  ///
  /// In km, this message translates to:
  /// **'រំកិលដើម្បីមើលបន្ថែម'**
  String get scrollForMore;

  /// No description provided for @dragToReorder.
  ///
  /// In km, this message translates to:
  /// **'ចុចឱ្យជាប់ រួចអូសដើម្បីរៀបចំលំដាប់រូបភាព'**
  String get dragToReorder;

  /// No description provided for @chooseImageSource.
  ///
  /// In km, this message translates to:
  /// **'បន្ថែមឯកសារ'**
  String get chooseImageSource;

  /// No description provided for @scanDocumentOption.
  ///
  /// In km, this message translates to:
  /// **'ស្កេនឯកសារ'**
  String get scanDocumentOption;

  /// No description provided for @scanDocumentOptionDescription.
  ///
  /// In km, this message translates to:
  /// **'ប្រើកាមេរ៉ាដើម្បីស្កេនច្រើនទំព័រ'**
  String get scanDocumentOptionDescription;

  /// No description provided for @scanModeBarcode.
  ///
  /// In km, this message translates to:
  /// **'បាកូដ'**
  String get scanModeBarcode;

  /// No description provided for @scanModeVisual.
  ///
  /// In km, this message translates to:
  /// **'រូបភាព'**
  String get scanModeVisual;

  /// No description provided for @copyText.
  ///
  /// In km, this message translates to:
  /// **'ចម្លងអត្ថបទ'**
  String get copyText;

  /// No description provided for @khmerOCR.
  ///
  /// In km, this message translates to:
  /// **'ស្កេនអក្សរខ្មែរ'**
  String get khmerOCR;

  /// No description provided for @extractTextFromImages.
  ///
  /// In km, this message translates to:
  /// **'ទាញយកអត្ថបទពីរូបភាព'**
  String get extractTextFromImages;

  /// No description provided for @comingSoon.
  ///
  /// In km, this message translates to:
  /// **'ឆាប់ៗនេះ'**
  String get comingSoon;

  /// No description provided for @comingSoonDescription.
  ///
  /// In km, this message translates to:
  /// **'មុខងារថ្មីៗជាច្រើនទៀត'**
  String get comingSoonDescription;

  /// No description provided for @copiedToClipboard.
  ///
  /// In km, this message translates to:
  /// **'បានចម្លងទៅក្ដារតម្បៀតខ្ទាស់'**
  String get copiedToClipboard;

  /// No description provided for @save.
  ///
  /// In km, this message translates to:
  /// **'រក្សាទុក'**
  String get save;

  /// No description provided for @scanNew.
  ///
  /// In km, this message translates to:
  /// **'ស្កេនថ្មី'**
  String get scanNew;

  /// No description provided for @extractedText.
  ///
  /// In km, this message translates to:
  /// **'អត្ថបទដែលបានទាញយក'**
  String get extractedText;

  /// No description provided for @processing.
  ///
  /// In km, this message translates to:
  /// **'កំពុងដំណើរការ...'**
  String get processing;

  /// No description provided for @noTextExtracted.
  ///
  /// In km, this message translates to:
  /// **'មិនទាន់មានអត្ថបទនៅឡើយទេ'**
  String get noTextExtracted;

  /// No description provided for @copy.
  ///
  /// In km, this message translates to:
  /// **'ចម្លង'**
  String get copy;

  /// No description provided for @documentTitle.
  ///
  /// In km, this message translates to:
  /// **'ចំណងជើងឯកសារ'**
  String get documentTitle;

  /// No description provided for @enterDocumentTitle.
  ///
  /// In km, this message translates to:
  /// **'បញ្ចូលចំណងជើងសម្រាប់ការស្កេននេះ'**
  String get enterDocumentTitle;

  /// No description provided for @documentSaved.
  ///
  /// In km, this message translates to:
  /// **'ឯកសារត្រូវបានរក្សាទុកដោយជោគជ័យ'**
  String get documentSaved;

  /// No description provided for @failedToExtractText.
  ///
  /// In km, this message translates to:
  /// **'បរាជ័យក្នុងការទាញយកអត្ថបទ៖ {error}'**
  String failedToExtractText(Object error);
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
