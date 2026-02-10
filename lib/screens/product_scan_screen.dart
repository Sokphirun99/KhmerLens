import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../services/ad_service.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/arb/app_localizations.dart';
import '../services/usda_service.dart';
import '../services/spoonacular_service.dart';
import '../services/open_fda_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';
import 'product_history_screen.dart';
import 'package:uuid/uuid.dart';

enum ScanMode { barcode, visual }

class ProductInfo {
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String
      source; // 'Google Books', 'OpenFoodFacts', 'UPCitemdb', 'Visual Search'
  final Map<String, String> details;

  ProductInfo({
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.source,
    this.details = const {},
  });
}

class ProductScanScreen extends StatefulWidget {
  const ProductScanScreen({super.key});

  @override
  State<ProductScanScreen> createState() => _ProductScanScreenState();
}

class _ProductScanScreenState extends State<ProductScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );

  ScanMode _scanMode = ScanMode.barcode;
  bool _isLoading = false;

  // AdMob State
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // Visual Search Deps
  final ImagePicker _picker = ImagePicker();
  final UsdaService _usdaService = UsdaService();
  final SpoonacularService _spoonacularService = SpoonacularService();
  final OpenFdaService _openFdaService = OpenFdaService();

  @override
  void initState() {
    super.initState();
    // Start manually since autoStart is disabled to prevent race conditions
    _controller.start();

    // Initialize Banner Ad
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isBannerAdReady = true;
          });
        }
      },
      onAdFailedToLoad: (error) {
        if (mounted) {
          setState(() {
            _isBannerAdReady = false;
          });
        }
      },
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory(ProductInfo product, String barcode) async {
    try {
      final db = DatabaseService();
      await db.insertScannedProduct({
        'id': const Uuid().v4(),
        'barcode': barcode,
        'title': product.title,
        'description': product.description,
        'imageUrl': product.imageUrl,
        'source': product.source,
        'scannedAt': DateTime.now().toIso8601String(),
        'details': json.encode(product.details),
      });
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  // --- Barcode Logic ---

  // Debounce state
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isLoading || _scanMode != ScanMode.barcode) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    // Debounce: Ignore if same code scanned within 2 seconds
    final now = DateTime.now();
    if (code == _lastScannedCode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 2)) {
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    setState(() => _isLoading = true);

    try {
      await _fetchProductInfo(code);
    } catch (e) {
      _showErrorSnackBar('Error fetching data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchProductInfo(String code) async {
    // 0. Check local history (Cache)
    try {
      final db = DatabaseService();
      final existingMap = await db.getScannedProductByBarcode(code);

      if (existingMap != null) {
        // Found in cache! Update timestamp and show details.
        debugPrint('Product found in local history: $code');

        // Update timestamp to now
        final updatedMap = Map<String, dynamic>.from(existingMap);
        updatedMap['scannedAt'] = DateTime.now().toIso8601String();
        await db.insertScannedProduct(updatedMap);

        // Convert to ProductInfo for UI
        final details = existingMap['details'] != null
            ? json.decode(existingMap['details'] as String)
                as Map<String, dynamic>
            : <String,
                dynamic>{}; // Fix: Explicitly case to Map<String, dynamic> or use empty map

        // Ensure Map<String, String> for ProductInfo.details
        final stringDetails = details
            .map((key, value) => MapEntry(key.toString(), value.toString()));

        final cachedProduct = ProductInfo(
          title: existingMap['title'] as String,
          description: existingMap['description'] as String?,
          imageUrl: existingMap['imageUrl'] as String?,
          source: existingMap['source'] as String,
          details: stringDetails,
        );

        if (mounted) {
          await _showProductDetails(cachedProduct);
        }
        return; // Skip API calls
      }
    } catch (e) {
      debugPrint('Error checking local history: $e');
      // Continue to API calls if cache check fails
    }

    // 1. Check if it looks like a Book (ISBN usually starts with 978 or 979)
    if (code.startsWith('978') || code.startsWith('979')) {
      final bookData = await _fetchGoogleBook(code);
      if (mounted && bookData != null) {
        _saveToHistory(bookData, code);
        await _showProductDetails(bookData);
        return;
      }
    }

    // 2. Try OpenFoodFacts (Best for food/cosmetics)
    final foodData = await _fetchOpenFoodFacts(code);
    if (mounted && foodData != null) {
      _saveToHistory(foodData, code);
      await _showProductDetails(foodData);
      return;
    }

    // 3. Try USDA API (Additional food data)
    final usdaData = await _usdaService.fetchProductByUpc(code);
    if (mounted && usdaData != null) {
      _saveToHistory(usdaData, code);
      await _showProductDetails(usdaData);
      return;
    }

    // 4. Try Spoonacular API (Recipes/Food)
    final spoonData = await _spoonacularService.fetchProductByUpc(code);
    if (mounted && spoonData != null) {
      _saveToHistory(spoonData, code);
      await _showProductDetails(spoonData);
      return;
    }

    // 5. Try openFDA (Drugs)
    final drugData = await _openFdaService.fetchProductByUpc(code);
    if (mounted && drugData != null) {
      _saveToHistory(drugData, code);
      await _showProductDetails(drugData);
      return;
    }

    // 6. Fallback to UPCitemdb (General items)
    final generalData = await _fetchUPCItemDB(code);
    if (mounted && generalData != null) {
      _saveToHistory(generalData, code);
      await _showProductDetails(generalData);
      return;
    }

    if (mounted) {
      _showErrorSnackBar('Product not found in any database');
    }
  }

  Future<ProductInfo?> _fetchGoogleBook(String isbn) async {
    try {
      final url =
          Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['totalItems'] > 0) {
          final volumeInfo = data['items'][0]['volumeInfo'];
          return ProductInfo(
            title: volumeInfo['title'] ?? 'Unknown Book',
            subtitle: volumeInfo['authors'] != null
                ? (volumeInfo['authors'] as List).join(', ')
                : null,
            description: volumeInfo['description'],
            imageUrl: volumeInfo['imageLinks']?['thumbnail']
                ?.toString()
                .replaceAll('http://', 'https://'),
            source: 'Google Books',
            details: {
              if (volumeInfo['publisher'] != null)
                'Publisher': volumeInfo['publisher'],
              if (volumeInfo['publishedDate'] != null)
                'Published': volumeInfo['publishedDate'],
              if (volumeInfo['pageCount'] != null)
                'Pages': volumeInfo['pageCount'].toString(),
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Google Books API Error: $e');
    }
    return null;
  }

  Future<ProductInfo?> _fetchOpenFoodFacts(String code) async {
    try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        code,
        version: ProductQueryVersion.v3,
        languages: [OpenFoodFactsLanguage.KHMER, OpenFoodFactsLanguage.ENGLISH],
        fields: [
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.IMAGE_FRONT_URL,
          ProductField.ORIGINS,
          ProductField.INGREDIENTS_TEXT,
        ],
      );

      final ProductResultV3 result =
          await OpenFoodAPIClient.getProductV3(configuration);

      if (result.status == ProductResultV3.statusSuccess &&
          result.product != null) {
        final product = result.product!;
        return ProductInfo(
          title: product.productName ?? 'Unknown Product',
          subtitle: product.brands,
          description: product.ingredientsText,
          imageUrl: product.imageFrontUrl,
          source: 'Open Food Facts',
          details: {
            if (product.origins != null) 'Origin': product.origins!,
          },
        );
      }
    } catch (e) {
      debugPrint('OpenFoodFacts Error: $e');
    }
    return null;
  }

  Future<ProductInfo?> _fetchUPCItemDB(String code) async {
    try {
      final url =
          Uri.parse('https://api.upcitemdb.com/prod/trial/lookup?upc=$code');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['total'] > 0) {
          final item = data['items'][0];
          return ProductInfo(
            title: item['title'] ?? 'Unknown Item',
            subtitle: item['brand'],
            description: item['description'],
            imageUrl: (item['images'] as List?)?.isNotEmpty == true
                ? item['images'][0]
                : null,
            source: 'UPCitemdb',
            details: {
              if (item['category'] != null) 'Category': item['category'],
              if (item['ean'] != null) 'EAN': item['ean'],
            },
          );
        }
      }
    } catch (e) {
      debugPrint('UPCitemdb Error: $e');
    }
    return null;
  }

  // --- Visual Search Logic ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => _isLoading = true);
      await _analyzeImage(pickedFile.path);
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);

    // 1. Image Labeling
    final ImageLabelerOptions labelerOptions =
        ImageLabelerOptions(confidenceThreshold: 0.5);
    final imageLabeler = ImageLabeler(options: labelerOptions);

    // 2. Text Recognition
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      // Run both in parallel
      final List<ImageLabel> labels =
          await imageLabeler.processImage(inputImage);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      if (!mounted) return;

      // Combine results
      final String detectedText =
          recognizedText.text.replaceAll('\n', ' ').trim();

      if (labels.isEmpty && detectedText.isEmpty) {
        _showErrorSnackBar("Couldn't identify any objects or text clearly.");
      } else {
        _showVisualSearchResults(labels, detectedText);
      }
    } catch (e) {
      _showErrorSnackBar('Could not analyze image: $e');
    } finally {
      imageLabeler.close();
      textRecognizer.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchGoogle(String query) async {
    final Uri url = Uri.parse(
        'https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(query)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showErrorSnackBar('Could not launch Google Search');
    }
  }

  // --- UI Helpers ---

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showVisualSearchResults(List<ImageLabel> labels, String detectedText) {
    // Construct simplified text (first 50 chars) to avoid huge queries
    String simpleText = detectedText;
    if (simpleText.length > 50) {
      simpleText = simpleText.substring(0, 50);
    }

    // Primary Query: Label + Text (e.g. "Bottle Evian")
    final String? primaryLabel = labels.isNotEmpty ? labels.first.label : null;
    final String combinedQuery = primaryLabel != null && simpleText.isNotEmpty
        ? '$simpleText $primaryLabel'
        : (simpleText.isNotEmpty ? simpleText : (primaryLabel ?? ''));

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Visual Search Results',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            // 1. Best Match (Combined)
            if (combinedQuery.isNotEmpty) ...[
              Text('Best Match:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ActionChip(
                avatar: const Icon(Icons.saved_search, color: Colors.white),
                label: Text(combinedQuery,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                labelStyle:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () {
                  Navigator.pop(context);
                  _searchGoogle(combinedQuery);
                },
              ),
              const SizedBox(height: 16),
            ],

            Text('Other Detected Items:',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Text only option
                if (simpleText.isNotEmpty && simpleText != combinedQuery)
                  ActionChip(
                    avatar: const Icon(Icons.text_fields, size: 16),
                    label: const Text("Text Only"),
                    onPressed: () {
                      Navigator.pop(context);
                      _searchGoogle(simpleText);
                    },
                  ),

                // Label options
                ...labels.map((label) {
                  return ActionChip(
                    avatar: const Icon(Icons.image_search, size: 16),
                    label: Text(label.label),
                    onPressed: () {
                      Navigator.pop(context);
                      _searchGoogle(label.label);
                    },
                  );
                }),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProductDetails(ProductInfo product) async {
    // Stop scanner to prevent background scans
    if (_scanMode == ScanMode.barcode) {
      await _controller.stop();
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Source Badge
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.source,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Product Image
            if (product.imageUrl != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(product.imageUrl!),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              const Icon(Icons.image_not_supported,
                  size: 80, color: Colors.grey),

            const SizedBox(height: 24),

            // Title and Subtitle
            Text(
              product.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (product.subtitle != null)
              Chip(
                label: Text(product.subtitle!),
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
              ),

            const SizedBox(height: 24),

            // Dynamic Details
            ...product.details.entries.map((e) => Column(
                  children: [
                    _buildDetailRow(e.key, e.value),
                    const Divider(),
                  ],
                )),

            if (product.description != null && product.description!.isNotEmpty)
              _buildDetailRow('Description', product.description!),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('Scan Another'),
              ),
            ),
          ],
        ),
      ),
    );

    // Increment scan count and check for interstitial
    try {
      final newScanCount = await StorageService().incrementScanCount();
      if (newScanCount % AppConfig.scansBeforeInterstitial == 0) {
        if (mounted) {
          await AdService().showInterstitialAd();
        }
      }
    } catch (e) {
      debugPrint('Error handling ad logic: $e');
    }

    // Restart scanner
    if (mounted && _scanMode == ScanMode.barcode) {
      await _controller.start();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _scanMode == ScanMode.barcode ? l10n.scanProduct : 'Visual Search'),
        actions: [
          if (_scanMode == ScanMode.barcode)
            IconButton(
              icon: Icon(
                _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProductHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Render scanner only in Barcode mode to save resources and avoid active camera conflict
          if (_scanMode == ScanMode.barcode)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            )
          else
            // Visual Search Info UI
            Container(
              color: Colors.black,
              width: double.infinity,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search, size: 80, color: Colors.white70),
                  SizedBox(height: 20),
                  Text(
                      'Snap a photo or pick from gallery\nto find similar items on Google',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),

          // Scanner Overlay (Barcode)
          if (_scanMode == ScanMode.barcode)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          // Mode Switcher & Visual Actions
          Positioned(
            bottom: _isBannerAdReady ? 90 : 30, // Adjust for ad
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Visual Search Actions (Only in Visual Mode)
                if (_scanMode == ScanMode.visual)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.white24),
                      ),
                      FilledButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ],
                  ),
                if (_scanMode == ScanMode.visual) const SizedBox(height: 20),

                // Mode Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeButton(l10n.scanModeBarcode, ScanMode.barcode),
                      _buildModeButton(l10n.scanModeVisual, ScanMode.visual),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Banner Ad
          if (_isBannerAdReady && _bannerAd != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, ScanMode mode) {
    final bool isSelected = _scanMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _scanMode = mode);
        // Manage scanner lifecycle based on mode
        if (mode == ScanMode.barcode) {
          _controller.start();
        } else {
          _controller.stop();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
