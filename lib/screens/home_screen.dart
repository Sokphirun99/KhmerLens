import 'dart:io';
import 'package:flutter/services.dart'; // Added for Clipboard

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khmerscan/l10n/arb/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import '../bloc/document/document_bloc.dart';
import '../bloc/document/document_event.dart';
import '../bloc/document/document_state.dart';
import '../hooks/use_banner_ad.dart';
import '../hooks/use_scroll_control.dart';
import '../models/document.dart';
import '../router/app_router.dart';
import '../services/ad_service.dart';
import '../services/rating_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../widgets/destructive_action_sheet.dart';
import '../widgets/document_grid_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Removed local scan count state in favor of persistent storage
    // final scansCount = useState(0);

    // BLoC State for pagination
    final documentState = context.watch<DocumentBloc>().state;
    final canLoadMore = documentState is DocumentLoaded &&
        documentState.hasMore &&
        !documentState.isLoadingMore;

    // Use custom scroll hook
    final (scrollController, isFabExtended) = useScrollControl(
      onLoadMore: () {
        context.read<DocumentBloc>().add(const LoadMoreDocuments());
      },
      canLoadMore: canLoadMore,
    );

    // Initialize Banner Ad
    final (bannerAd, isBannerAdReady) = useBannerAd();

    // Define methods that need access to hooks/context
    Future<void> processNewDocument(List<String> imagePaths) async {
      try {
        debugPrint('HomeScreen: Processing ${imagePaths.length} images');
        if (imagePaths.isEmpty) return;

        if (context.mounted) {
          _showLoadingDialog(context);
        }

        final documentId = const Uuid().v4();
        final document = Document(
          id: documentId,
          title: '${l10n.documentPrefix} - ${_formatDate(DateTime.now())}',
          imagePaths: [],
          createdAt: DateTime.now(),
        );

        if (!context.mounted) return;

        context.read<DocumentBloc>().add(
              CreateDocument(
                document: document,
                imagePaths: imagePaths,
              ),
            );

        final newScanCount = await StorageService().incrementScanCount();
        if (newScanCount % AppConstants.scansBeforeInterstitial == 0) {
          AdService().showInterstitialAd();
        }

        await RatingService().trackEvent(isScan: true);
      } catch (e) {
        debugPrint('HomeScreen: Error in processNewDocument: $e');
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    Future<void> scanDocument() async {
      try {
        if (Platform.isIOS) {
          final status = await Permission.camera.request();
          if (status.isPermanentlyDenied) {
            if (context.mounted) _showPermissionDeniedDialog(context);
            return;
          }
          if (!status.isGranted) return;
        }

        final imagePaths =
            await CunningDocumentScanner.getPictures(noOfPages: 24) ?? [];
        if (imagePaths.isNotEmpty) {
          await processNewDocument(imagePaths);
        }
      } catch (e) {
        debugPrint('Error scanning document: $e');
        if (context.mounted) {
          ErrorSnackBar.show(context, error: e, locale: 'km');
        }
      }
    }

    Future<void> chooseFromGallery() async {
      try {
        final picker = ImagePicker();
        final List<XFile> images =
            await picker.pickMultiImage(imageQuality: 85);

        if (images.isNotEmpty) {
          final imagePaths = images.map((img) => img.path).toList();
          await processNewDocument(imagePaths);
        }
      } catch (e) {
        debugPrint('Error picking images: $e');
        if (context.mounted) {
          ErrorSnackBar.show(context, error: e, locale: 'km');
        }
      }
    }

    Future<void> copyToClipboard(Document document) async {
      if (document.extractedText == null || document.extractedText!.isEmpty) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: document.extractedText!));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.copiedToClipboard),
            behavior: SnackBarBehavior.floating,
            width: 200, // Compact snackbar
          ),
        );
      }
    }

    void onFabPressed() {
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
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.chooseImageSource,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
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
                    scanDocument();
                  },
                ),
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
                    chooseFromGallery();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: scrollController,
            slivers: [
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
                    icon: const Iconify(Mdi.magnify, color: Colors.black54),
                    onPressed: () => context.pushSearch(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              BlocConsumer<DocumentBloc, DocumentState>(
                listener: (context, state) {
                  if (state is DocumentCreated) {
                    try {
                      final navigator =
                          Navigator.of(context, rootNavigator: true);
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                    } catch (e) {
                      debugPrint('HomeScreen: Failed to close dialog: $e');
                    }
                    context.pushDocumentDetail(state.document);
                  } else if (state is DocumentError) {
                    try {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      debugPrint('HomeScreen: Failed to close dialog: $e');
                    }
                    ErrorSnackBar.show(context,
                        error: state.error, locale: 'km');
                  } else if (state is DocumentDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.deletedSuccess)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is DocumentLoading) {
                    return _buildShimmerLoading(context);
                  }
                  if (state is DocumentLoaded) {
                    if (state.documents.isEmpty) {
                      return SliverFillRemaining(
                        child: EmptyState.documents(
                          context,
                          onScan: onFabPressed,
                        ),
                      );
                    }
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount:
                                MediaQuery.of(context).size.width > 900
                                    ? 4
                                    : MediaQuery.of(context).size.width > 600
                                        ? 3
                                        : 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childCount: state.documents.length,
                            itemBuilder: (context, index) {
                              final document = state.documents[index];
                              // Limit animations to first 6 items for better performance on old phones
                              final shouldAnimate = index < 6;
                              final card = DocumentGridCard(
                                key: ValueKey(document.id),
                                document: document,
                                index: index,
                                onTap: () async {
                                  await context.push(
                                    AppRoutes.documentDetail
                                        .replaceFirst(':id', document.id),
                                    extra: document,
                                  );
                                },
                                onDelete: () async {
                                  final confirmed =
                                      await DestructiveActionSheet.show(
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
                                onCopy: () => copyToClipboard(document),
                                onShare: () async {
                                  // Share implementation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(l10n.shareComingSoon)),
                                  );
                                },
                              );

                              return shouldAnimate
                                  ? card.animate().fadeIn(
                                      delay: (20 * index).ms, duration: 150.ms)
                                  : card;
                            },
                          ),
                        ),
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (state.hasMore && !state.isLoadingMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Text(
                                  l10n.scrollForMore,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  if (state is DocumentError) {
                    // Refactoring _buildErrorState to be inline or helper
                    return _buildErrorState(context, state.error, l10n);
                  }
                  return _buildShimmerLoading(context);
                },
              ),
              if (bannerAd != null)
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: 300.ms,
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      height: isBannerAdReady
                          ? bannerAd.size.height.toDouble() + 8
                          : 0,
                    ),
                  ),
                ),
            ],
          ),
          if (isBannerAdReady && bannerAd != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                width: bannerAd.size.width.toDouble(),
                height: bannerAd.size.height.toDouble(),
                color: Theme.of(context).colorScheme.surface,
                child: AdWidget(ad: bannerAd),
              ).animate().fadeIn(duration: 300.ms),
            ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: isFabExtended
            ? FloatingActionButton.extended(
                key: const ValueKey('extended'),
                onPressed: onFabPressed,
                icon: const Iconify(Mdi.scanner, color: Colors.white),
                label: Text(l10n.scanDocument),
                elevation: 2,
              )
            : FloatingActionButton(
                key: const ValueKey('collapsed'),
                onPressed: onFabPressed,
                elevation: 2,
                tooltip: l10n.scanDocument,
                child: const Iconify(Mdi.scanner),
              ),
      ),
    );
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

  Widget _buildShimmerLoading(BuildContext context) {
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

  Widget _buildErrorState(
      BuildContext context, dynamic error, AppLocalizations l10n) {
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
              icon: const Iconify(Mdi.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
