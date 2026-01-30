import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
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

  // Scroll controller for FAB animation
  final ScrollController _scrollController = ScrollController();
  bool _isFabExtended = true;
  double _lastScrollOffset = 0;

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
        // Silently handle ad load errors
        debugPrint('Banner ad failed to load: $e');
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
          locale: 'km', // Or use current locale
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
                final navigator = Navigator.of(context, rootNavigator: true);
                if (navigator.canPop()) {
                  debugPrint('HomeScreen: Closing loading dialog');
                  navigator.pop();
                }

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
                if (Navigator.of(context).canPop()) {
                  debugPrint('HomeScreen: Closing loading dialog after error');
                  Navigator.of(context).pop();
                }

                ErrorSnackBar.show(
                  context,
                  error: state.error,
                  locale: 'km',
                );
              }

              // Handle document deleted
              if (state is DocumentDeleted) {
                debugPrint('HomeScreen: Document deleted: ${state.documentId}');
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
                return _buildDocumentGrid(state.documents, l10n);
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
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
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

  Widget _buildDocumentGrid(List<Document> documents, AppLocalizations l10n) {
    // Responsive grid
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width > 900
        ? 4
        : width > 600
            ? 3
            : 2;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          // Limit animations to first 10 items for better performance
          final shouldAnimate = index < 10;
          final card = DocumentGridCard(
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

          // Only animate first 10 items for performance
          return shouldAnimate
              ? card.animate().fadeIn(delay: (30 * index).ms, duration: 200.ms)
              : card;
        },
      ),
    );
  }
}
