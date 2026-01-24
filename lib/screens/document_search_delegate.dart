import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/document.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';
import 'document_detail_screen.dart';

class DocumentSearchDelegate extends SearchDelegate<Document?> {
  final DatabaseService _dbService = DatabaseService();
  List<Document> _results = [];
  List<String> _recentSearches = [];

  DocumentSearchDelegate() {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    // In a real app, load from shared preferences
    _recentSearches = [];
  }

  @override
  String get searchFieldLabel => 'ស្វែងរកឯកសារ...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Document>>(
      future: _dbService.searchDocuments(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
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
                  'កំហុសក្នុងការស្វែងរក',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        _results = snapshot.data ?? [];

        if (_results.isEmpty) {
          return _buildEmptyResults(context);
        }

        return _buildResultsList(context);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSuggestionsEmpty(context);
    }

    return FutureBuilder<List<Document>>(
      future: _dbService.searchDocuments(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        _results = snapshot.data ?? [];

        if (_results.isEmpty) {
          return _buildEmptyResults(context);
        }

        return _buildResultsList(context);
      },
    );
  }

  Widget _buildSuggestionsEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ការណែនាំស្វែងរក',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ស្វែងរកតាមប្រភេទឯកសារ ឬអត្ថបទដែលបានស្កេន',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Quick search categories
          Text(
            'ស្វែងរកតាមប្រភេទ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickSearchChip(context, 'អត្តសញ្ញាណប័ណ្ណ', Icons.badge),
              _buildQuickSearchChip(context, 'លិខិតឆ្លងដែន', Icons.flight),
              _buildQuickSearchChip(context, 'ប័ណ្ណបើកបរ', Icons.directions_car),
              _buildQuickSearchChip(context, 'វិក្កយបត្រ', Icons.receipt),
              _buildQuickSearchChip(context, 'កិច្ចសន្យា', Icons.description),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          if (_recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ស្វែងរកថ្មីៗ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    _recentSearches.clear();
                  },
                  child: const Text('សម្អាត'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._recentSearches.map(
              (search) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                onTap: () {
                  query = search;
                  showResults(context);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.north_west, size: 18),
                  onPressed: () {
                    query = search;
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSearchChip(BuildContext context, String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        query = label;
        showResults(context);
      },
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'រកមិនឃើញឯកសារ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'សូមព្យាយាមស្វែងរកពាក្យផ្សេងទៀត',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final document = _results[index];

        return ListTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: document.category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              document.category.icon,
              color: document.category.color,
            ),
          ),
          title: Text(
            document.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.category.nameKhmer,
                style: TextStyle(
                  color: document.category.color,
                  fontSize: 12,
                ),
              ),
              Text(
                Helpers.formatDateTime(document.createdAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Save to recent searches
            if (!_recentSearches.contains(query) && query.isNotEmpty) {
              _recentSearches.insert(0, query);
              if (_recentSearches.length > 5) {
                _recentSearches.removeLast();
              }
            }

            // Navigate to document detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DocumentDetailScreen(document: document),
              ),
            );
          },
        ).animate().fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: 300.ms,
            );
      },
    );
  }
}
