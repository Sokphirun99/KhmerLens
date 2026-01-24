// screens/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/theme/theme_cubit.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _documentCount = 0;
  String _storageUsed = 'គណនា...';
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${appDir.path}/documents');

      if (await documentsDir.exists()) {
        int totalSize = 0;
        int fileCount = 0;

        await for (final entity in documentsDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
            fileCount++;
          }
        }

        if (mounted) {
          setState(() {
            _documentCount = fileCount;
            _storageUsed = _formatBytes(totalSize);
            _isLoadingStorage = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _documentCount = 0;
            _storageUsed = '0 B';
            _isLoadingStorage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _storageUsed = 'មិនអាចគណនាបាន';
          _isLoadingStorage = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ការកំណត់'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'ត្រឡប់ក្រោយ',
        ),
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          // Appearance section
          _buildSectionHeader(
            context,
            icon: Icons.palette_outlined,
            title: 'រូបរាង',
          ),
          _buildAppearanceSection(context, colorScheme),

          const SizedBox(height: AppSpacing.lg),

          // Storage section
          _buildSectionHeader(
            context,
            icon: Icons.storage_outlined,
            title: 'ទំហំផ្ទុក',
          ),
          _buildStorageSection(context, colorScheme),

          const SizedBox(height: AppSpacing.lg),

          // About section
          _buildSectionHeader(
            context,
            icon: Icons.info_outline,
            title: 'អំពីកម្មវិធី',
          ),
          _buildAboutSection(context, colorScheme),

          const SizedBox(height: AppSpacing.lg),

          // Support section
          _buildSectionHeader(
            context,
            icon: Icons.support_outlined,
            title: 'ជំនួយ',
          ),
          _buildSupportSection(context, colorScheme),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildAppearanceSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Column(
        children: [
          // Theme mode selector
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.brightness_6_outlined,
                    title: 'រូបភាពបង្ហាញ',
                    subtitle: _getThemeModeLabel(state.mode),
                    onTap: () => _showThemePicker(context, state.mode),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildThemePreview(context, state.mode),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildThemePreview(BuildContext context, AppThemeMode mode) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildThemeOption(
            context,
            label: 'ភ្លឺ',
            icon: Icons.light_mode,
            isSelected: mode == AppThemeMode.light,
            onTap: () =>
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.light),
          ),
          _buildThemeOption(
            context,
            label: 'ងងឹត',
            icon: Icons.dark_mode,
            isSelected: mode == AppThemeMode.dark,
            onTap: () =>
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.dark),
          ),
          _buildThemeOption(
            context,
            label: 'ប្រព័ន្ធ',
            icon: Icons.settings_suggest,
            isSelected: mode == AppThemeMode.system,
            onTap: () =>
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'ភ្លឺ';
      case AppThemeMode.dark:
        return 'ងងឹត';
      case AppThemeMode.system:
        return 'តាមប្រព័ន្ធ';
    }
  }

  void _showThemePicker(BuildContext context, AppThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppSpacing.paddingMd,
              child: Text(
                'ជ្រើសរើសរូបភាពបង្ហាញ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('ភ្លឺ'),
              trailing: currentMode == AppThemeMode.light
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('ងងឹត'),
              trailing: currentMode == AppThemeMode.dark
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: const Text('តាមប្រព័ន្ធ'),
              subtitle: const Text('ប្រើការកំណត់ពីឧបករណ៍'),
              trailing: currentMode == AppThemeMode.system
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.folder_outlined,
            title: 'ចំនួនឯកសារ',
            subtitle: _isLoadingStorage ? 'កំពុងរាប់...' : '$_documentCount ឯកសារ',
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.pie_chart_outline,
            title: 'ទំហំផ្ទុកដែលប្រើ',
            subtitle: _storageUsed,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.cleaning_services_outlined,
            title: 'សម្អាតឃ្លាំង',
            subtitle: 'លុបទិន្នន័យបណ្ដោះអាសន្ន',
            onTap: () => _showClearCacheDialog(context),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('សម្អាតឃ្លាំង'),
        content: const Text(
          'តើអ្នកពិតជាចង់លុបទិន្នន័យបណ្ដោះអាសន្នទាំងអស់មែនទេ? '
          'សកម្មភាពនេះនឹងមិនលុបឯកសាររបស់អ្នកទេ។',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('បោះបង់'),
          ),
          FilledButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);
              await _clearCache();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('បានសម្អាតឃ្លាំង')),
                );
              }
            },
            child: const Text('សម្អាត'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Widget _buildAboutSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.apps,
            title: 'កម្មវិធី',
            subtitle: AppConstants.appName,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.numbers,
            title: 'កំណែ',
            subtitle: AppConstants.appVersion,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'អាជ្ញាប័ណ្ណ',
            subtitle: 'ចុចដើម្បីមើលអាជ្ញាប័ណ្ណ',
            onTap: () => _showLicensesPage(context),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  void _showLicensesPage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: AppRadius.borderRadiusMd,
          child: Image.asset(
            'assets/icon/icon.png',
            width: 64,
            height: 64,
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.rate_review_outlined,
            title: 'វាយតម្លៃកម្មវិធី',
            subtitle: 'ជួយយើងកែលម្អដោយការវាយតម្លៃ',
            onTap: () => _rateApp(),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.share_outlined,
            title: 'ចែករំលែកកម្មវិធី',
            subtitle: 'ប្រាប់មិត្តភក្តិអំពីកម្មវិធីនេះ',
            onTap: () => _shareApp(),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.bug_report_outlined,
            title: 'រាយការណ៍បញ្ហា',
            subtitle: 'ប្រាប់យើងប្រសិនបើអ្នកជួបបញ្ហា',
            onTap: () => _reportBug(),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'គោលការណ៍ភាពឯកជន',
            onTap: () => _openPrivacyPolicy(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: AppRadius.borderRadiusSm,
        ),
        child: Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                )
              : null),
      onTap: onTap,
    );
  }

  void _rateApp() {
    // TODO: Implement app store rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('មុខងារនេះនឹងមានក្នុងពេលឆាប់ៗ')),
    );
  }

  void _shareApp() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('មុខងារនេះនឹងមានក្នុងពេលឆាប់ៗ')),
    );
  }

  void _reportBug() async {
    final uri = Uri.parse('mailto:support@khmerscan.app?subject=Bug Report');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openPrivacyPolicy() async {
    final uri = Uri.parse('https://khmerscan.app/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
