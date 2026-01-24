// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uuid/uuid.dart';
import '../bloc/document/document_bloc.dart';
import '../bloc/document/document_event.dart';
import '../bloc/document/document_state.dart';
import '../models/document.dart';
import '../models/document_category.dart';
import '../router/app_router.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../widgets/category_picker.dart';
import '../widgets/document_grid_card.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';

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
  DocumentCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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
    _bannerAd?.dispose();
    _bannerAd = null;
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
    return await CategoryPicker.show(context);
  }

  void _showLoadingDialog() {
    LoadingDialog.show(
      context,
      message: 'កំពុងរក្សាទុក...',
      animationAsset: 'assets/animations/scanning.json',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed: () => context.pushSearch(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.pushSettings(),
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
                  ...DocumentCategory.values.map((cat) => _buildCategoryChip(
                        cat.nameKhmer,
                        cat,
                        cat.icon,
                      )),
                ],
              ),
            ),
          ),

          // Documents grid - BLoC Consumer
          BlocConsumer<DocumentBloc, DocumentState>(
            listener: (context, state) {
              if (!mounted) return;

              // Handle document created
              if (state is DocumentCreated) {
                // Safely close loading dialog if open
                final navigator = Navigator.of(context, rootNavigator: true);
                if (navigator.canPop()) {
                  navigator.pop();
                }
                context.pushDocumentDetail(state.document);
              }

              // Handle errors
              if (state is DocumentError) {
                // Try to close loading dialog if open
                if (Navigator.of(context).canPop()) {
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
                return _buildErrorState(state.error);
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
          final imagePath = await context.pushCamera<String>();
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Shimmer.fromColors(
            baseColor: isDark ? (Colors.grey[800] ?? Colors.grey) : (Colors.grey[300] ?? Colors.grey),
            highlightColor: isDark ? (Colors.grey[700] ?? Colors.grey) : (Colors.grey[100] ?? Colors.white),
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

  Widget _buildEmptyState() {
    final isFiltered = _selectedCategory != null;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty_documents.json',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.folder_open_outlined,
                  size: 120,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              isFiltered ? 'គ្មានឯកសារក្នុងប្រភេទនេះ' : 'គ្មានឯកសារ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                isFiltered
                    ? 'សូមជ្រើសរើសប្រភេទផ្សេង ឬស្កេនឯកសារថ្មី'
                    : 'ចុចប៊ូតុងខាងក្រោមដើម្បីចាប់ផ្តើមស្កេនឯកសាររបស់អ្នក',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                  context.read<DocumentBloc>().add(
                        const FilterDocumentsByCategory(null),
                      );
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('បង្ហាញទាំងអស់'),
              ),
            ],
          ],
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
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
              'មានបញ្ហា',
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
              label: const Text('ព្យាយាមម្តងទៀត'),
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
