import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../bloc/document/document_bloc.dart';
import '../bloc/document/document_event.dart';
import '../bloc/document/document_state.dart';
import '../bloc/ocr/ocr_bloc.dart';
import '../bloc/ocr/ocr_event.dart';
import '../bloc/ocr/ocr_state.dart';
import '../models/document.dart';
import '../services/export_service.dart';
import '../utils/helpers.dart';
import '../widgets/error_dialog.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  late Document _document;
  final ExportService _exportService = ExportService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _tabController = TabController(length: 2, vsync: this);

    // Auto-run OCR via BLoC if no text
    if (_document.extractedText == null || _document.extractedText!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OCRBloc>().add(ExtractText(_document));
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteDocument() async {
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
      context.read<DocumentBloc>().add(DeleteDocument(_document));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareDocument() async {
    try {
      _showSnackBar('កំពុងរៀបចំឯកសារសម្រាប់ចែករំលែក...');
      await _exportService.shareDocument(_document.id);
    } catch (e) {
      _showSnackBar('មិនអាចចែករំលែកឯកសារ: $e');
    }
  }

  Future<void> _exportPdf() async {
    try {
      _showSnackBar('កំពុងនាំចេញជា PDF...');
      await _exportService.exportToPdf([_document.id]);
    } catch (e) {
      _showSnackBar('មិនអាចនាំចេញជា PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentBloc, DocumentState>(
      listener: (context, state) {
        if (state is DocumentDeleted) {
          _showSnackBar('បានលុបឯកសារ');
          context.pop(true);
        } else if (state is DocumentError) {
          ErrorSnackBar.show(
            context,
            error: state.error,
            locale: 'km',
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        title: Text(_document.category.nameKhmer),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('ចែករំលែក'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('នាំចេញជា PDF'),
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
                    'លុប',
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
                  await _shareDocument();
                  break;
                case 'export_pdf':
                  await _exportPdf();
                  break;
                case 'delete':
                  _deleteDocument();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Image viewer
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    File(_document.imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'មិនអាចផ្ទុករូបភាព',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Bottom section with tabs
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
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.text_fields),
                        text: 'អត្ថបទ',
                      ),
                      Tab(
                        icon: Icon(Icons.info_outline),
                        text: 'ព័ត៌មាន',
                      ),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTextTab(),
                        _buildInfoTab(),
                      ],
                    ),
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

  Widget _buildTextTab() {
    return BlocConsumer<OCRBloc, OCRState>(
      listener: (context, state) {
        if (state is OCRSuccess) {
          _showSnackBar('ស្កេនអត្ថបទបានជោគជ័យ');

          // Update local document state
          setState(() {
            _document = _document.copyWith(
              extractedText: state.extractedText,
            );
          });
        } else if (state is OCREmpty) {
          _showSnackBar('រកមិនឃើញអត្ថបទក្នុងរូបភាព');
        } else if (state is OCRError) {
          _showSnackBar('Error: ${state.message}');
        }
      },
      builder: (context, state) {
        if (state is OCRProcessing) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/scanning.json',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  const Text('កំពុងស្កេនអត្ថបទ...'),
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          );
        }

        // Handle error state
        if (state is OCRError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: ${state.message}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // Reset and re-run OCR using BLoC
                      context.read<OCRBloc>().add(const ResetOCR());
                      context.read<OCRBloc>().add(ExtractText(_document));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('ព្យាយាមម្តងទៀត'),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          );
        }

        final text = _document.extractedText ?? '';

        if (text.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.text_fields,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'គ្មានអត្ថបទ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'រូបភាពមិនមានអត្ថបទដែលអាចស្កេនបាន',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // Reset and re-run OCR using BLoC
                      context.read<OCRBloc>().add(const ResetOCR());
                      context.read<OCRBloc>().add(ExtractText(_document));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('ព្យាយាមម្តងទៀត'),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          );
        }

        // Show text content
        return Column(
          children: [
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      _showSnackBar('បានចម្លងអត្ថបទ');
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('ចម្លង'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Reset and re-run OCR using BLoC
                      context.read<OCRBloc>().add(const ResetOCR());
                      context.read<OCRBloc>().add(ExtractText(_document));
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('ស្កេនឡើងវិញ'),
                  ),
                ],
              ),
            ),

            // Text content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'ព័ត៌មានទូទៅ',
          [
            _buildInfoRow(
              Icons.category,
              'ប្រភេទ',
              _document.category.nameKhmer,
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'បង្កើត',
              Helpers.formatDateTime(_document.createdAt),
            ),
            if (_document.expiryDate != null)
              _buildInfoRow(
                Icons.event_busy,
                'ផុតកំណត់',
                Helpers.formatDate(_document.expiryDate!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'ព័ត៌មានបច្ចេកទេស',
          [
            _buildInfoRow(
              Icons.badge,
              'ID',
              _document.id.substring(0, 8),
            ),
            FutureBuilder<int>(
              future: File(_document.imagePath).length(),
              builder: (context, snapshot) {
                return _buildInfoRow(
                  Icons.storage,
                  'ទំហំ',
                  snapshot.hasData
                      ? Helpers.formatFileSize(snapshot.data!)
                      : 'Loading...',
                );
              },
            ),
            _buildInfoRow(
              Icons.text_fields,
              'អត្ថបទ',
              _document.extractedText != null &&
                      _document.extractedText!.isNotEmpty
                  ? '${_document.extractedText!.length} តួអក្សរ'
                  : 'គ្មាន',
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
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
          Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
