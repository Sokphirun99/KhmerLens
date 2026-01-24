import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../bloc/document/document_bloc.dart';
import '../bloc/document/document_event.dart';
import '../bloc/search/search_bloc.dart';
import '../bloc/search/search_event.dart';
import '../bloc/search/search_state.dart';
import '../models/document.dart';
import '../router/app_router.dart';
import '../services/export_service.dart';
import '../utils/error_handler.dart';
import '../widgets/empty_state.dart';
import '../widgets/modern_document_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ExportService _exportService = ExportService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<SearchBloc>().add(SearchDocuments(query));
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    context.read<SearchBloc>().add(const ClearSearch());
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

  Future<void> _deleteDocument(Document document, int index) async {
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

    if (confirmed == true && mounted) {
      try {
        // Use DocumentBloc for deletion to maintain consistency
        context.read<DocumentBloc>().add(DeleteDocument(document));
        _showSnackBar('បានលុបឯកសារដោយជោគជ័យ');
        // Re-run the search to update results
        _onSearchChanged(_searchController.text);
      } catch (e, stackTrace) {
        ErrorHandler.logError(e, stackTrace: stackTrace);
        if (mounted) {
          _showSnackBar('មិនអាចលុបឯកសារ');
        }
      }
    }
  }

  Future<void> _shareDocument(Document document) async {
    try {
      _showSnackBar('កំពុងរៀបចំឯកសារសម្រាប់ចែករំលែក...');
      await _exportService.shareDocument(document.id);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace: stackTrace);
      if (mounted) {
        _showSnackBar('មិនអាចចែករំលែកឯកសារ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'ស្វែងរកឯកសារ...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (_searchController.text.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return _buildLoadingState();
          }

          if (state is SearchInitial) {
            return _buildInitialState();
          }

          if (state is SearchEmpty) {
            return _buildNoResults();
          }

          if (state is SearchError) {
            return _buildErrorState(state.message);
          }

          if (state is SearchLoaded) {
            return _buildResults(state.results);
          }

          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('កំពុងស្វែងរក...'),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildInitialState() {
    return EmptyState.searchInitial();
  }

  Widget _buildNoResults() {
    return EmptyState.noSearchResults();
  }

  Widget _buildErrorState(String message) {
    return Center(
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
            'កំហុស',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _onSearchChanged(_searchController.text),
            icon: const Icon(Icons.refresh),
            label: const Text('ព្យាយាមម្តងទៀត'),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildResults(List<Document> results) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'រកឃើញ ${results.length} លទ្ធផល',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: results.length,
            itemBuilder: (context, index) {
              final document = results[index];
              return ModernDocumentCard(
                document: document,
                index: index,
                onTap: () {
                  context.pushDocumentDetail(document);
                },
                onDelete: () => _deleteDocument(document, index),
                onShare: () => _shareDocument(document),
              )
                  .animate()
                  .fadeIn(delay: (50 * index).ms)
                  .slideY(begin: 0.1, end: 0);
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }
}
