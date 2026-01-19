import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../models/document.dart';
import '../models/document_category.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DocumentCategory? _selectedCategory;
  List<Document> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    // Simulate network delay for smooth animation
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: Load from database (Week 2)
    setState(() {
      _documents = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
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
                onPressed: () {
                  // TODO: Navigate to search (Week 3)
                },
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

          // Content: Empty / Grid
          if (_isLoading)
            _buildShimmerLoading()
          else if (_documents.isEmpty)
            _buildEmptyState()
          else
            _buildDocumentGrid(),
        ],
      ),

      // Modern FAB with animation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final imagePath = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
          if (imagePath != null) {
            // TODO: Process the captured image
            debugPrint('Captured image: $imagePath');
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
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200 + (index % 2) * 50.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
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
          // TODO: Add ModernDocumentCard widget (Week 2)
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: document.category.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(document.category.nameKhmer),
            ),
          )
              .animate()
              .fadeIn(delay: (100 * index).ms)
              .slideY(begin: 0.2, end: 0);
        },
      ),
    );
  }
}
