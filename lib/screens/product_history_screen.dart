import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scanned_product.dart';
import '../services/database_service.dart';
import '../widgets/product_details_sheet.dart';

class ProductHistoryScreen extends StatefulWidget {
  const ProductHistoryScreen({super.key});

  @override
  State<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends State<ProductHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<ScannedProduct> _products = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _databaseService.getAllScannedProducts();
      final products = data.map((e) => ScannedProduct.fromMap(e)).toList();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteScannedProduct(String id) async {
    try {
      await _databaseService.deleteScannedProduct(id);
      await _loadHistory();
      if (_selectedIds.contains(id)) {
        setState(() {
          _selectedIds.remove(id);
          if (_selectedIds.isEmpty) {
            _isSelectionMode = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
        );
      }
    }
  }

  Future<void> _deleteSelectedProducts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text(
            'Are you sure you want to delete ${_selectedIds.length} items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteScannedProducts(_selectedIds.toList());
        setState(() {
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        await _loadHistory();
      } catch (e) {
        debugPrint('Error deleting selected products: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete selected products')),
          );
        }
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'Are you sure you want to delete all scan history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteAllScannedProducts();
        await _loadHistory();
      } catch (e) {
        debugPrint('Error clearing history: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear history')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group products by date
    final groupedProducts = <String, List<ScannedProduct>>{};
    for (var product in _products) {
      final date = DateFormat.yMMMd().format(product.scannedAt);
      if (!groupedProducts.containsKey(date)) {
        groupedProducts[date] = [];
      }
      groupedProducts[date]!.add(product);
    }

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        title: Text(_isSelectionMode
            ? '${_selectedIds.length} Selected'
            : 'Scan History'),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedProducts,
              tooltip: 'Delete Selected',
            )
          else if (_products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No scan history yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: groupedProducts.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final date = groupedProducts.keys.elementAt(index);
                    final products = groupedProducts[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            date,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        ...products.map((product) {
                          final isSelected = _selectedIds.contains(product.id);
                          return Dismissible(
                            key: Key(product.id),
                            direction: _isSelectionMode
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) =>
                                _deleteScannedProduct(product.id),
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.2),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    backgroundImage: product.imageUrl != null
                                        ? NetworkImage(product.imageUrl!)
                                        : null,
                                    child: product.imageUrl == null
                                        ? const Icon(Icons.qr_code_2)
                                        : null,
                                  ),
                                  if (_isSelectionMode)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: isSelected
                                            ? Icon(
                                                Icons.check_circle,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 20,
                                              )
                                            : Icon(
                                                Icons.radio_button_unchecked,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.description != null &&
                                      product.description!.isNotEmpty)
                                    Text(
                                      product.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).hintColor),
                                    ),
                                  Text(
                                    '${product.source} • ${DateFormat.jm().format(product.scannedAt)}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).disabledColor),
                                  ),
                                ],
                              ),
                              onLongPress: () =>
                                  _enterSelectionMode(product.id),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(product.id);
                                } else {
                                  // Existing tap logic (show details)
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (context) =>
                                        ProductDetailsSheet(product: product),
                                  );
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
    );
  }
}
