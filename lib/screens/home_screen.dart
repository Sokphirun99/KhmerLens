import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import '../models/document.dart';
import '../models/document_category.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';
import '../widgets/document_grid_card.dart';
import '../widgets/modern_document_card.dart';
import 'camera_screen.dart';
import 'document_detail_screen.dart';
import 'document_search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  DocumentCategory? _selectedCategory;
  List<Document> _documents = [];
  bool _isLoading = true;
  int _scansCount = 0;
  String? _deletingDocumentId;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final docs = await _dbService.getAllDocuments(
        category: _selectedCategory,
      );

      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading documents: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processNewDocument(String imagePath) async {
    try {
      // Show category dialog
      final category = await _showCategoryDialog();
      if (category == null) return;

      // Show loading
      _showLoadingDialog();

      final documentId = const Uuid().v4();

      // Save image to storage
      final savedPath = await _storageService.saveImage(File(imagePath));

      // Create document
      final document = Document(
        id: documentId,
        title: '${category.nameKhmer} - ${Helpers.formatDate(DateTime.now())}',
        category: category,
        imagePath: savedPath,
        createdAt: DateTime.now(),
      );

      // Save to database
      await _dbService.insertDocument(document);

      // Close loading
      if (mounted) Navigator.pop(context);

      // Reload documents
      await _loadDocuments();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បានរក្សាទុកឯកសារដោយជោគជ័យ'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Track scans for ad display (Week 5)
      _scansCount++;
      // if (_scansCount % 3 == 0) {
      //   AdService().showInterstitialAd();
      // }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('កំហុស: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<DocumentCategory?> _showCategoryDialog() async {
    return await showDialog<DocumentCategory>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ជ្រើសរើសប្រភេទឯកសារ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: DocumentCategory.values.map((category) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: category.color.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                    ),
                  ),
                  title: Text(
                    category.nameKhmer,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    category.nameEnglish,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, category),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('បោះបង់'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('កំពុងរក្សាទុក...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('លុបឯកសារ'),
        content: const Text('តើអ្នកពិតជាចង់លុបឯកសារនេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('បោះបង់'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('លុប'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Trigger card delete animation
        setState(() => _deletingDocumentId = document.id);

        // Show Lottie delete animation dialog
        _showDeleteAnimationDialog();

        // Wait for card animation
        await Future.delayed(const Duration(milliseconds: 300));

        // Actually delete
        await _storageService.deleteImage(document.imagePath);
        await _dbService.deleteDocument(document.id);

        // Remove from local list
        setState(() {
          _documents.removeWhere((d) => d.id == document.id);
          _deletingDocumentId = null;
        });

        // Close animation dialog and show success
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('បានលុបឯកសារ'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() => _deletingDocumentId = null);
        if (mounted) {
          Navigator.pop(context); // Close animation dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('កំហុស: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showDeleteAnimationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/delete.json',
                  width: 120,
                  height: 120,
                  repeat: false,
                ),
                const SizedBox(height: 16),
                const Text(
                  'កំពុងលុប...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDocumentDetail(Document document) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(document: document),
      ),
    );

    // Reload if document was deleted or modified
    if (deleted == true || mounted) {
      _loadDocuments();
    }
  }

  Future<void> _shareDocument(Document document) async {
    try {
      final file = XFile(document.imagePath);
      await Share.shareXFiles(
        [file],
        text: document.title,
        subject: document.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: CustomScrollView(
          slivers: [
            // Modern large app bar
            SliverAppBar.large(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'KhmerScan',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final result = await showSearch<Document?>(
                      context: context,
                      delegate: DocumentSearchDelegate(),
                    );
                    if (result != null) {
                      _loadDocuments();
                    }
                  },
                ),
                // Grid/List toggle
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      key: ValueKey(_isGridView),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _isGridView = !_isGridView);
                  },
                  tooltip: _isGridView ? 'List view' : 'Grid view',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // TODO: Navigate to settings (Week 4)
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Category filter chips
            SliverToBoxAdapter(
              child: Container(
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip('ទាំងអស់', null, Icons.apps),
                    ...DocumentCategory.values.map(
                      (cat) => _buildCategoryChip(
                        cat.nameKhmer,
                        cat,
                        cat.icon,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Document count header
            if (!_isLoading && _documents.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ឯកសារ (${_documents.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            // Content: Loading / Empty / Grid or List
            if (_isLoading)
              _buildShimmerLoading()
            else if (_documents.isEmpty)
              _buildEmptyState()
            else if (_isGridView)
              _buildDocumentGrid()
            else
              _buildDocumentList(),

            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),

      // Modern FAB with animation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final imagePath = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
          if (imagePath != null) {
            await _processNewDocument(imagePath);
          }
        },
        icon: const Icon(Icons.document_scanner),
        label: const Text('ស្កេនឯកសារ'),
        elevation: 2,
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildCategoryChip(
      String label, DocumentCategory? category, IconData icon) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _loadDocuments();
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.primary,
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ).animate(target: isSelected ? 1 : 0).scaleXY(end: 1.05, duration: 200.ms),
    );
  }

  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty_documents.json',
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 24),
            Text(
              'គ្មានឯកសារ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'ចុចប៊ូតុងខាងក្រោមដើម្បីចាប់ផ្តើមស្កេនឯកសាររបស់អ្នក',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildDocumentGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childCount: _documents.length,
        itemBuilder: (context, index) {
          final document = _documents[index];
          final isDeleting = _deletingDocumentId == document.id;

          return DocumentGridCard(
            document: document,
            index: index,
            isDeleting: isDeleting,
            onTap: () => _openDocumentDetail(document),
            onLongPress: () => _deleteDocument(document),
          );
        },
      ),
    );
  }

  Widget _buildDocumentList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final document = _documents[index];
          final isDeleting = _deletingDocumentId == document.id;

          return ModernDocumentCard(
            document: document,
            index: index,
            isDeleting: isDeleting,
            onTap: () => _openDocumentDetail(document),
            onDelete: () => _deleteDocument(document),
            onShare: () => _shareDocument(document),
          );
        },
        childCount: _documents.length,
      ),
    );
  }
}
