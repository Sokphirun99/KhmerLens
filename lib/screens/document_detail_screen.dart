import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

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
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
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
        final paths = await CunningDocumentScanner.getPictures();
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

  Future<void> _deleteImage(String imagePath) async {
    // Don't allow deleting the last image
    if (_document.imagePaths.length <= 1) {
      _showSnackBar(l10n.cannotDeleteLastImage);
      return;
    }

    final confirmed = await DestructiveActionSheet.show(
      context,
      title: l10n.deleteImage,
      message: l10n.deleteImageConfirmation,
      confirmLabel: l10n.deleteImage,
      icon: Icons.image_not_supported,
    );

    if (confirmed && mounted) {
      context.read<DocumentBloc>().add(
            RemoveImageFromDocument(
              documentId: _document.id,
              imagePath: imagePath,
            ),
          );
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

  void _showImageManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _ImageManagerSheet(
            document: _document,
            onDelete: _deleteImage,
            onReorder: _reorderImages,
            onAddMore: _addMoreImages,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentBloc, DocumentState>(
      listener: (context, state) {
        if (state is DocumentDeleted) {
          _showSnackBar(l10n.deletedSuccess);
          context.pop(true);
        } else if (state is DocumentLoaded) {
          // When documents list is refreshed after image add/remove, update current document
          final updatedDoc = state.documents.firstWhere(
            (doc) => doc.id == _document.id,
            orElse: () => _document,
          );
          if (updatedDoc.imagePaths.length !=
              _currentDocument.imagePaths.length) {
            setState(() {
              _currentDocument = updatedDoc;
              // Reset page controller if current index is out of bounds
              if (_currentImageIndex >= updatedDoc.imagePaths.length) {
                _currentImageIndex = updatedDoc.imagePaths.length - 1;
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(_currentImageIndex);
                }
              }
            });
          }
        } else if (state is DocumentError) {
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
              icon: const Icon(Icons.add_photo_alternate),
              onPressed: _addMoreImages,
              tooltip: l10n.addImages,
            ),
            // Manage images button
            if (_document.imagePaths.length > 1)
              IconButton(
                icon: const Icon(Icons.view_carousel),
                onPressed: _showImageManager,
                tooltip: l10n.manageImages,
              ),
            PopupMenuButton<String>(
              key: _menuKey,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: const Icon(Icons.share),
                    title: Text(l10n.share),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'export_pdf',
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(l10n.exportPdf),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete,
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
        body: Column(
          children: [
            // Image viewer with PageView for multiple images
            Expanded(
              flex: 2,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: _document.imagePaths.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
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
                              icon: const Icon(Icons.add_photo_alternate),
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
                              debugPrint(
                                  'DocumentDetail: Displaying image ${index + 1}/${_document.imagePaths.length}: ${_document.imagePaths[index]}');

                              return InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Center(
                                  child: Image.file(
                                    File(_document.imagePaths[index]),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                          'DocumentDetail: Error loading image: $error');
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
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

            // Bottom section with document info
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                          Icon(
                            Icons.info_outline,
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
                      child: _buildInfoContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          l10n.generalInfo,
          [
            _buildInfoRow(
              Icons.calendar_today,
              l10n.created,
              Helpers.formatDateTime(_document.createdAt),
            ),
            if (_document.expiryDate != null)
              _buildInfoRow(
                Icons.event_busy,
                l10n.expires,
                Helpers.formatDate(_document.expiryDate!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          l10n.technicalInfo,
          [
            _buildInfoRow(
              Icons.badge,
              l10n.id,
              _document.id.substring(0, 8),
            ),
            _buildInfoRow(
              Icons.image,
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
                  Icons.storage,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  icon:
                      const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(l10n.add),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid of images
          Expanded(
            child: ReorderableGridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _imagePaths.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final item = _imagePaths.removeAt(oldIndex);
                  _imagePaths.insert(newIndex, item);
                });
                widget.onReorder(_imagePaths);
              },
              itemBuilder: (context, index) {
                final imagePath = _imagePaths[index];
                return _buildImageCard(imagePath, index);
              },
            ),
          ),
        ],
      ),
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

  Widget _buildImageCard(String imagePath, int index) {
    return Container(
      key: ValueKey(imagePath),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
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

          // Gradient Overlay for visibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Delete button
          if (_imagePaths.length > 1)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _confirmAndDelete(imagePath),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // Drag handle icon
          Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              Icons.drag_indicator,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
