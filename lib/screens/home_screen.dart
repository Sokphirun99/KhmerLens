// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uuid/uuid.dart';
import '../bloc/document/document_bloc.dart';
import '../bloc/document/document_event.dart';
import '../bloc/document/document_state.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../widgets/document_grid_card.dart';
import 'camera_screen.dart';
import 'document_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  int _scansCount = 0;
  DocumentCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd()
      ..load().then((_) {
        if (mounted) {
          setState(() {
            _isBannerAdReady = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _processNewDocument(String imagePath) async {
    try {
      // Show category dialog
      final category = await _showCategoryDialog();
      if (category == null) return;

      // Show loading
      _showLoadingDialog();

      final documentId = const Uuid().v4();

      // Create document
      final document = Document(
        id: documentId,
        title: '${category.nameKhmer} - ${_formatDate(DateTime.now())}',
        category: category,
        imagePath: imagePath, // Will be updated by repository
        createdAt: DateTime.now(),
      );

      if (!mounted) return;

      // Create document using BLoC
      context.read<DocumentBloc>().add(
            CreateDocument(
              document: document,
              imagePath: imagePath,
            ),
          );

      // Show interstitial ad every 3 scans
      _scansCount++;
      if (_scansCount % AppConstants.scansBeforeInterstitial == 0) {
        AdService().showInterstitialAd();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('កំពុងរក្សាទុក...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern app bar
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Category chips
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

          // Documents grid - BLoC Consumer
          BlocConsumer<DocumentBloc, DocumentState>(
            listener: (context, state) {
              // Handle document created
              if (state is DocumentCreated) {
                Navigator.pop(context); // Close loading

                // Navigate to detail for OCR
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentDetailScreen(
                      document: state.document,
                    ),
                  ),
                );
              }

              // Handle errors
              if (state is DocumentError) {
                Navigator.pop(context); // Close loading if open

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              // Handle document deleted
              if (state is DocumentDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('បានលុបឯកសារ')),
                );
              }
            },
            builder: (context, state) {
              if (state is DocumentLoading) {
                return _buildShimmerLoading();
              }

              if (state is DocumentLoaded) {
                if (state.documents.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildDocumentGrid(state.documents);
              }

              if (state is DocumentError) {
                return _buildErrorState(state.message);
              }

              return _buildShimmerLoading();
            },
          ),

          // Banner ad
          if (_isBannerAdReady)
            SliverToBoxAdapter(
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                margin: const EdgeInsets.only(top: 8),
                child: AdWidget(ad: _bannerAd!),
              ).animate().fadeIn(duration: 300.ms),
            ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final imagePath = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
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
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });

          // Trigger BLoC event
          context.read<DocumentBloc>().add(
                FilterDocumentsByCategory(_selectedCategory),
              );
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.primary,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      )
          .animate(target: isSelected ? 1 : 0)
          .scaleXY(end: 1.05, duration: 200.ms),
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

  Widget _buildErrorState(String message) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DocumentBloc>().add(const RefreshDocuments());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentGrid(List<Document> documents) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          return DocumentGridCard(
            document: document,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentDetailScreen(
                    document: document,
                  ),
                ),
              ).then((_) {
                if (context.mounted) {
                  // Refresh after returning
                  context.read<DocumentBloc>().add(const RefreshDocuments());
                }
              });
            },
            onDelete: () async {
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

              if (confirmed == true && context.mounted) {
                context.read<DocumentBloc>().add(
                      DeleteDocument(document),
                    );
              }
            },
            onShare: () async {
              // Share implementation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon')),
              );
            },
          ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}
