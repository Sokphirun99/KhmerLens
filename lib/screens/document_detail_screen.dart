import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:share_plus/share_plus.dart';

import '../bloc/document/document_bloc.dart';
import '../bloc/document/document_event.dart';
import '../bloc/document/document_state.dart';
import '../models/document.dart';
import '../services/export_service.dart';
import '../utils/error_handler.dart';
import '../utils/helpers.dart';
import '../widgets/error_dialog.dart';
import '../widgets/destructive_action_sheet.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import 'package:khmerscan/l10n/arb/app_localizations.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final ExportService _exportService = ExportService();
  late PageController _pageController;
  final GlobalKey _menuKey = GlobalKey();
  int _currentImageIndex = 0;

  // Track current document state (can be updated when images are added/removed)
  late Document _currentDocument;

  // Use current document
  Document get _document => _currentDocument;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// Check if document has actually changed (paths added, removed, or reordered)
  bool _hasDocumentChanged(Document updatedDoc) {
    if (updatedDoc.imagePaths.length != _currentDocument.imagePaths.length) {
      return true;
    }
    // Check if paths are in different order or different content
    for (int i = 0; i < updatedDoc.imagePaths.length; i++) {
      if (updatedDoc.imagePaths[i] != _currentDocument.imagePaths[i]) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _currentDocument = widget.document;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteDocument(AppLocalizations l10n) async {
    final confirmed = await DestructiveActionSheet.show(
      context,
      title: l10n.deleteDocument,
      message: l10n.deleteDocumentConfirmation,
      confirmLabel: l10n.deleteDocument,
      icon: Icons.delete_forever,
    );

    if (confirmed && mounted) {
      context.read<DocumentBloc>().add(DeleteDocument(_document));
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<int> _calculateTotalSize() async {
    int totalSize = 0;
    for (final imagePath in _document.imagePaths) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      } catch (e) {
        // Skip file if error
        continue;
      }
    }
    return totalSize;
  }

  Future<void> _shareDocument(AppLocalizations l10n) async {
    try {
      _showSnackBar(l10n.preparingToShare);

      // Calculate share origin for iPad
      Rect? shareOrigin;
      final box = _menuKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        shareOrigin = position & box.size;
      }

      await _exportService.shareDocument(
        _document.id,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(l10n.unableToShare);
      }
    }
  }

  Future<void> _exportPdf(AppLocalizations l10n) async {
    try {
      // Use printDocument to allow full PDF customization (Paper size, Layout, etc.)
      await _exportService.printDocument(_document.id);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(l10n.unableToExportPdf);
      }
    }
  }

  Future<void> _addMoreImages() async {
    // Show options: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Iconify(Mdi.camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Iconify(Mdi.image_multiple),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (!mounted) return;

    try {
      final ImagePicker picker = ImagePicker();
      List<String> newImagePaths = [];

      if (source == ImageSource.camera) {
        // Use document scanner for capture
        if (!mounted) return;
        final paths = await CunningDocumentScanner.getPictures(noOfPages: 24);
        if (paths != null && paths.isNotEmpty) {
          newImagePaths = paths;
        }
      } else {
        // Gallery multi-select
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          newImagePaths = images.map((img) => img.path).toList();
        }
      }

      if (newImagePaths.isNotEmpty && mounted) {
        _showSnackBar(l10n.addingImages);
        context.read<DocumentBloc>().add(
              AddImagesToDocument(
                documentId: _document.id,
                imagePaths: newImagePaths,
              ),
            );
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(l10n.unableToAddImages);
      }
    }
  }

  Future<void> _reorderImages(List<String> newOrder) async {
    try {
      final updatedDocument = _document.copyWith(imagePaths: newOrder);
      context.read<DocumentBloc>().add(UpdateDocument(updatedDocument));
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar(l10n.unableToReorderImages);
      }
    }
  }

  /// Delete image directly without confirmation (used by image manager which already confirmed)
  void _deleteImageDirect(String imagePath) {
    // Don't allow deleting the last image
    if (_document.imagePaths.length <= 1) {
      _showSnackBar(l10n.cannotDeleteLastImage);
      return;
    }

    context.read<DocumentBloc>().add(
          RemoveImageFromDocument(
            documentId: _document.id,
            imagePath: imagePath,
          ),
        );
  }

  void _showImageManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _ImageManagerSheet(
          document: _document,
          onDelete: _deleteImageDirect,
          onReorder: _reorderImages,
          onAddMore: _addMoreImages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentBloc, DocumentState>(
      listener: (context, state) {
        if (!mounted) return; // Prevent operations after dispose

        if (state is DocumentDeleted) {
          _showSnackBar(l10n.deletedSuccess);
          if (mounted) {
            context.pop(true);
          }
        } else if (state is DocumentLoaded) {
          if (!mounted) return;
          // When documents list is refreshed after image add/remove, update current document
          final updatedDoc = state.documents.firstWhere(
            (doc) => doc.id == _document.id,
            orElse: () => _document,
          );

          // Only update if document actually changed (different paths or different order)
          final hasChanged = _hasDocumentChanged(updatedDoc);
          if (hasChanged && mounted) {
            setState(() {
              _currentDocument = updatedDoc;
              // Reset page controller if current index is out of bounds
              if (_currentImageIndex >= updatedDoc.imagePaths.length) {
                _currentImageIndex = updatedDoc.imagePaths.isNotEmpty
                    ? updatedDoc.imagePaths.length - 1
                    : 0;
                if (_pageController.hasClients) {
                  try {
                    _pageController.jumpToPage(_currentImageIndex);
                  } catch (e) {
                    // Silently handle page controller errors
                  }
                }
              }
            });
          }
        } else if (state is DocumentError) {
          if (!mounted) return;
          ErrorSnackBar.show(
            context,
            error: state.error,
            locale: 'km',
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          title: Text(_document.title),
          actions: [
            // Add images button
            IconButton(
              icon: const Iconify(Mdi.image_plus, color: Colors.black54),
              onPressed: _addMoreImages,
              tooltip: l10n.addImages,
            ),
            // Manage images button
            if (_document.imagePaths.length > 1)
              IconButton(
                icon: const Iconify(Mdi.view_carousel, color: Colors.black54),
                onPressed: _showImageManager,
                tooltip: l10n.manageImages,
              ),
            PopupMenuButton<String>(
              key: _menuKey,
              icon: const Iconify(Mdi.dots_vertical, color: Colors.black54),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: const Iconify(Mdi.share_variant),
                    title: Text(l10n.share),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'export_pdf',
                  child: ListTile(
                    leading: const Iconify(Mdi.file_pdf_box),
                    title: Text(l10n.exportPdf),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Iconify(
                      Mdi.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l10n.delete,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'share':
                    await _shareDocument(l10n);
                    break;
                  case 'export_pdf':
                    await _exportPdf(l10n);
                    break;
                  case 'delete':
                    _deleteDocument(l10n);
                    break;
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Image viewer with PageView for multiple images (Takes full height but leaves space for bottom sheet)
            Positioned.fill(
              bottom: 80, // Keep some space visible for the sheet header
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: _document.imagePaths.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Iconify(
                              Mdi.image_off_outline,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noImagesInDocument,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.pleaseAddImages,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _addMoreImages,
                              icon: const Iconify(Mdi.image_plus,
                                  color: Colors.white),
                              label: Text(l10n.addImages),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          // PageView for images
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _document.imagePaths.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Center(
                                  child: Image.file(
                                    File(_document.imagePaths[index]),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Iconify(
                                            Mdi.image_broken_variant,
                                            size: 64,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            l10n.unableToLoadImage,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _document.imagePaths[index],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.5),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                          // Image counter badge (top right)
                          if (_document.imagePaths.length > 1)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1}/${_document.imagePaths.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ).animate().fadeIn(),
                            ),

                          // Page indicator dots (bottom)
                          if (_document.imagePaths.length > 1)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      _document.imagePaths.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentImageIndex == index
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(),
                            ),
                        ],
                      ),
              ),
            ),

            // Draggable Bottom Sheet
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.15,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Section header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Iconify(
                              Mdi.information_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.documentInfo,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Info content
                      Expanded(
                        child: _buildInfoContent(scrollController),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          l10n.generalInfo,
          [
            _buildInfoRow(
              Mdi.calendar,
              l10n.created,
              Helpers.formatDateTime(_document.createdAt),
            ),
            if (_document.expiryDate != null)
              _buildInfoRow(
                Mdi.calendar_alert,
                l10n.expires,
                Helpers.formatDate(_document.expiryDate!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_document.extractedText != null &&
            _document.extractedText!.isNotEmpty) ...[
          _buildExtractedTextCard(),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        _buildInfoCard(
          l10n.technicalInfo,
          [
            _buildInfoRow(
              Mdi.id_card,
              l10n.id,
              _document.id.substring(0, 8),
            ),
            _buildInfoRow(
              Mdi.image,
              l10n.images,
              l10n.imageCount(_document.imagePaths.length),
            ),
            FutureBuilder<int>(
              future: _calculateTotalSize(),
              builder: (context, snapshot) {
                String sizeText;
                if (snapshot.hasError) {
                  sizeText = l10n.unableToLoad;
                } else if (snapshot.hasData) {
                  sizeText = Helpers.formatFileSize(snapshot.data!);
                } else {
                  sizeText = l10n.loading;
                }
                return _buildInfoRow(
                  Mdi.database,
                  l10n.size,
                  sizeText,
                );
              },
            ),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Iconify(icon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extracted Text',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Iconify(Mdi.content_copy, size: 20),
                      onPressed: () {
                        if (_document.extractedText != null) {
                          Clipboard.setData(
                              ClipboardData(text: _document.extractedText!));
                          _showSnackBar('Copied to clipboard');
                        }
                      },
                      tooltip: 'Copy',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Iconify(Mdi.share_variant, size: 20),
                      onPressed: () {
                        if (_document.extractedText != null) {
                          Share.share(_document.extractedText!);
                        }
                      },
                      tooltip: l10n.share,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              _document.extractedText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'GoogleFonts.kantumruyPro().fontFamily',
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Image Manager Sheet Widget
class _ImageManagerSheet extends StatefulWidget {
  final Document document;
  final Function(String) onDelete;
  final Function(List<String>) onReorder;
  final VoidCallback onAddMore;

  const _ImageManagerSheet({
    required this.document,
    required this.onDelete,
    required this.onReorder,
    required this.onAddMore,
  });

  @override
  State<_ImageManagerSheet> createState() => _ImageManagerSheetState();
}

class _ImageManagerSheetState extends State<_ImageManagerSheet> {
  late List<String> _imagePaths;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _imagePaths = List.from(widget.document.imagePaths);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.manageImages,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onAddMore();
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(l10n.add),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Instruction text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            l10n.dragToReorder,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        // Grid of images with drag to reorder using Flutter's ReorderableListView
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            buildDefaultDragHandles: false,
            itemCount: _imagePaths.length,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final animValue = Curves.easeInOut.transform(animation.value);
                  final elevation = lerpDouble(0, 8, animValue)!;
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _imagePaths.removeAt(oldIndex);
                _imagePaths.insert(newIndex, item);
              });
              widget.onReorder(_imagePaths);
            },
            itemBuilder: (context, index) {
              final imagePath = _imagePaths[index];
              // Use indexOf to get the actual current position in the list
              // This ensures the index badge updates correctly after reordering
              final actualIndex = _imagePaths.indexOf(imagePath);
              return _buildDraggableImageCard(imagePath, actualIndex,
                  key: ValueKey(imagePath));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(String imagePath) async {
    final confirmed = await DestructiveActionSheet.show(
      context,
      title: l10n.deleteImage,
      message: l10n.deleteImageConfirmation,
      confirmLabel: l10n.delete,
      icon: Icons.delete_forever,
    );

    if (confirmed && mounted) {
      // Optimistically remove from local state
      setState(() {
        _imagePaths.remove(imagePath);
      });

      // Call parent handler
      widget.onDelete(imagePath);
    }
  }

  /// Build a draggable image card for ReorderableListView
  Widget _buildDraggableImageCard(String imagePath, int index, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Drag handle on the left
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 40,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Image card
          Expanded(
            child: SizedBox(
              height: 120,
              child: _buildImageCardContent(imagePath, index),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the image card content (used by draggable card)
  Widget _buildImageCardContent(String imagePath, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),

          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Index Badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Delete button
          if (_imagePaths.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _confirmAndDelete(imagePath),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
