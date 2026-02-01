import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uuid/uuid.dart';
import 'package:khmerscan/l10n/arb/app_localizations.dart';

import '../bloc/document/document_bloc.dart';
import '../bloc/document/document_event.dart';
import '../bloc/document/document_state.dart';
import '../models/document.dart';
import '../router/app_router.dart';
import '../services/ad_service.dart';
import '../services/rating_service.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../widgets/document_grid_card.dart';
import '../widgets/destructive_action_sheet.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  bool _isDisposed = false;
  int _scansCount = 0;

  // Scroll controller for FAB animation and pagination
  final ScrollController _scrollController = ScrollController();
  bool _isFabExtended = true;
  double _lastScrollOffset = 0;

  // Pagination threshold - load more when 200px from bottom
  static const double _loadMoreThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final scrollDelta = currentOffset - _lastScrollOffset;

    // Only trigger state change if scroll delta is significant (avoid jitter)
    if (scrollDelta.abs() > 5) {
      final shouldExtend = scrollDelta < 0 || currentOffset <= 0;
      if (_isFabExtended != shouldExtend) {
        setState(() {
          _isFabExtended = shouldExtend;
        });
      }
      _lastScrollOffset = currentOffset;
    }

    // Check for pagination - load more when near bottom
    _checkAndLoadMore();
  }

  void _checkAndLoadMore() {
    if (!_scrollController.hasClients) return;
    if (!mounted) return; // Prevent accessing context after dispose

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Load more when within threshold of bottom
    if (maxScroll - currentScroll <= _loadMoreThreshold) {
      final state = context.read<DocumentBloc>().state;
      if (state is DocumentLoaded && state.hasMore && !state.isLoadingMore) {
        context.read<DocumentBloc>().add(const LoadMoreDocuments());
      }
    }
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd()
      ..load().then((_) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isBannerAdReady = true;
          });
        }
      }).catchError((e) {
        // Dispose ad on error to prevent memory leak
        debugPrint('Banner ad failed to load: $e');
        _bannerAd?.dispose();
        _bannerAd = null;
      });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  Future<void> _processNewDocument(List<String> imagePaths) async {
    try {
      debugPrint('HomeScreen: Processing ${imagePaths.length} images');
      debugPrint('HomeScreen: Image paths: $imagePaths');

      if (imagePaths.isEmpty) {
        debugPrint('HomeScreen: No images to process');
        return;
      }

      // Show loading
      if (mounted) {
        _showLoadingDialog(context);
      }

      final documentId = const Uuid().v4();

      // Create document
      final document = Document(
        id: documentId,
        title:
            '${AppLocalizations.of(context)!.documentPrefix} - ${_formatDate(DateTime.now())}',
        imagePaths: [], // Will be updated by repository
        createdAt: DateTime.now(),
      );

      debugPrint('HomeScreen: Created document with ID: $documentId');

      if (!mounted) return;

      // Create document using BLoC
      debugPrint('HomeScreen: Dispatching CreateDocument event');
      context.read<DocumentBloc>().add(
            CreateDocument(
              document: document,
              imagePaths: imagePaths,
            ),
          );

      // Show interstitial ad every 3 scans
      _scansCount++;
      if (_scansCount % AppConstants.scansBeforeInterstitial == 0) {
        AdService().showInterstitialAd();
      }

      // Track scan event for rating prompt
      await RatingService().trackEvent(isScan: true);
    } catch (e) {
      debugPrint('HomeScreen: Error in _processNewDocument: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    LoadingDialog.show(
      context,
      message: AppLocalizations.of(context)!.saving,
      animationAsset: 'assets/animations/scanning.json',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _onFabPressed() async {
    final l10n = AppLocalizations.of(context)!;

    // Show bottom sheet with options
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.chooseImageSource,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Scan Document option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.document_scanner,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(l10n.scanDocumentOption),
                subtitle: Text(l10n.scanDocumentOptionDescription),
                onTap: () {
                  Navigator.pop(context);
                  _scanDocument();
                },
              ),
              // Choose from Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _chooseFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanDocument() async {
    try {
      // Explicitly request camera permission on iOS to ensure the prompt appears
      if (Platform.isIOS) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          if (mounted) {
            _showPermissionDeniedDialog(context);
          }
          return;
        }
        if (!status.isGranted) {
          return; // User denied
        }
      }

      final imagePaths = await CunningDocumentScanner.getPictures() ?? [];
      if (imagePaths.isNotEmpty) {
        await _processNewDocument(imagePaths);
      }
    } catch (e) {
      debugPrint('Error scanning document: $e');
      if (mounted) {
        ErrorSnackBar.show(
          context,
          error: e,
          locale: 'km',
        );
      }
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final imagePaths = images.map((img) => img.path).toList();
        await _processNewDocument(imagePaths);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ErrorSnackBar.show(
          context,
          error: e,
          locale: 'km',
        );
      }
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
            'Please enable camera access in Settings to scan documents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
          // Modern app bar
          SliverAppBar.large(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.myDocuments,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.pushSearch(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Documents grid - BLoC Consumer
          BlocConsumer<DocumentBloc, DocumentState>(
            listener: (context, state) {
              debugPrint(
                  'HomeScreen BlocConsumer: Received state: ${state.runtimeType}');

              if (!mounted) {
                debugPrint('HomeScreen: Widget not mounted, ignoring state');
                return;
              }

              // Handle document created
              if (state is DocumentCreated) {
                debugPrint('HomeScreen: DocumentCreated state received');
                debugPrint('HomeScreen: Document ID: ${state.document.id}');
                debugPrint(
                    'HomeScreen: Document has ${state.document.imagePaths.length} images');
                debugPrint(
                    'HomeScreen: Image paths: ${state.document.imagePaths}');

                // Safely close loading dialog if open
                try {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  if (navigator.canPop()) {
                    debugPrint('HomeScreen: Closing loading dialog');
                    navigator.pop();
                  }
                } catch (e) {
                  debugPrint('HomeScreen: Failed to close dialog: $e');
                }

                if (!mounted) return;

                // Reload documents list and navigate to created document
                debugPrint('HomeScreen: Reloading documents list');
                context.read<DocumentBloc>().add(const LoadDocuments());

                debugPrint('HomeScreen: Navigating to document detail');
                context.pushDocumentDetail(state.document);
              }

              // Handle errors
              if (state is DocumentError) {
                debugPrint(
                    'HomeScreen: DocumentError state received: ${state.error}');

                // Try to close loading dialog if open
                try {
                  if (Navigator.of(context).canPop()) {
                    debugPrint('HomeScreen: Closing loading dialog after error');
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  debugPrint('HomeScreen: Failed to close dialog: $e');
                }

                if (!mounted) return;

                ErrorSnackBar.show(
                  context,
                  error: state.error,
                  locale: 'km',
                );
              }

              // Handle document deleted
              if (state is DocumentDeleted) {
                debugPrint('HomeScreen: Document deleted: ${state.documentId}');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deletedSuccess)),
                );
              }
            },
            builder: (context, state) {
              if (state is DocumentLoading) {
                return _buildShimmerLoading();
              }

              if (state is DocumentLoaded) {
                if (state.documents.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState.documents(
                      context,
                      onScan: _onFabPressed,
                    ),
                  );
                }
                return _buildDocumentGrid(state, l10n);
              }

              if (state is DocumentError) {
                return _buildErrorState(state.error, l10n);
              }

              return _buildShimmerLoading();
            },
          ),

          // Add bottom padding to accommodate banner ad
          if (_isBannerAdReady)
            SliverToBoxAdapter(
              child: SizedBox(height: _bannerAd!.size.height.toDouble() + 8),
            ),
        ],
          ),

          // Banner ad positioned at bottom
          if (_isBannerAdReady)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                color: Theme.of(context).colorScheme.surface,
                child: AdWidget(ad: _bannerAd!),
              ).animate().fadeIn(duration: 300.ms),
            ),
        ],
      ),

      // FAB - shrinks on scroll down, extends on scroll up
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: _isFabExtended
            ? FloatingActionButton.extended(
                key: const ValueKey('extended'),
                onPressed: _onFabPressed,
                icon: const Icon(Icons.document_scanner),
                label: Text(l10n.scanDocument),
                elevation: 2,
              )
            : FloatingActionButton(
                key: const ValueKey('collapsed'),
                onPressed: _onFabPressed,
                elevation: 2,
                tooltip: l10n.scanDocument,
                child: const Icon(Icons.document_scanner),
              ),
      ), // Removed heavy FAB animation for better performance
    );
  }

  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childCount: 6,
        itemBuilder: (context, index) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Shimmer.fromColors(
            baseColor: isDark
                ? (Colors.grey[800] ?? Colors.grey)
                : (Colors.grey[300] ?? Colors.grey),
            highlightColor: isDark
                ? (Colors.grey[700] ?? Colors.grey)
                : (Colors.grey[100] ?? Colors.white),
            child: Container(
              height: 200 + (index % 2) * 50.0,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(dynamic error, AppLocalizations l10n) {
    final errorMessage = ErrorHandler.getMessage(error, locale: 'km');
    final recoverySuggestion =
        ErrorHandler.getRecoverySuggestion(error, locale: 'km');

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.error,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (recoverySuggestion != null) const SizedBox(height: 12),
            if (recoverySuggestion != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  recoverySuggestion,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DocumentBloc>().add(const RefreshDocuments());
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentGrid(DocumentLoaded state, AppLocalizations l10n) {
    final documents = state.documents;

    // Responsive grid
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width > 900
        ? 4
        : width > 600
            ? 3
            : 2;

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              // Limit animations to first 6 items for better performance on old phones
              final shouldAnimate = index < 6;
              final card = DocumentGridCard(
                key: ValueKey(document.id), // Add key for better list performance
                document: document,
                index: index,
                onTap: () async {
                  await context.push(
                    AppRoutes.documentDetail.replaceFirst(':id', document.id),
                    extra: document,
                  );
                  if (context.mounted) {
                    context.read<DocumentBloc>().add(const RefreshDocuments());
                  }
                },
                onDelete: () async {
                  final confirmed = await DestructiveActionSheet.show(
                    context,
                    title: l10n.deleteDocument,
                    message: l10n.deleteDocumentConfirmation,
                    confirmLabel: l10n.deleteDocument,
                    icon: Icons.delete_forever,
                  );

                  if (confirmed && context.mounted) {
                    context.read<DocumentBloc>().add(
                          DeleteDocument(document),
                        );
                  }
                },
                onShare: () async {
                  // Share implementation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.shareComingSoon)),
                  );
                },
              );

              // Reduced animation for better performance - only first 6 items with shorter delay
              return shouldAnimate
                  ? card.animate().fadeIn(delay: (20 * index).ms, duration: 150.ms)
                  : card;
            },
          ),
        ),
        // Loading indicator for pagination
        if (state.isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        // "Load more" hint when there are more documents
        if (state.hasMore && !state.isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  l10n.scrollForMore,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
