// screens/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:khmerscan/l10n/arb/app_localizations.dart';

import '../bloc/locale/locale_cubit.dart';
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
  String _storageUsed = '';
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
          _storageUsed = '';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: l10n.back,
        ),
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          // Appearance section
          _buildSectionHeader(
            context,
            icon: Icons.palette_outlined,
            title: l10n.appearance,
          ),
          _buildAppearanceSection(context, colorScheme, l10n),

          const SizedBox(height: AppSpacing.lg),

          // Storage section
          _buildSectionHeader(
            context,
            icon: Icons.storage_outlined,
            title: l10n.storage,
          ),
          _buildStorageSection(context, colorScheme, l10n),

          const SizedBox(height: AppSpacing.lg),

          // About section
          _buildSectionHeader(
            context,
            icon: Icons.info_outline,
            title: l10n.aboutApp,
          ),
          _buildAboutSection(context, colorScheme, l10n),

          const SizedBox(height: AppSpacing.lg),

          // Support section
          _buildSectionHeader(
            context,
            icon: Icons.support_outlined,
            title: l10n.support,
          ),
          _buildSupportSection(context, colorScheme, l10n),

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
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildAppearanceSection(
      BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
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
                    title: l10n.displayMode,
                    subtitle: _getThemeModeLabel(state.mode, l10n),
                    onTap: () => _showThemePicker(context, state.mode, l10n),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildThemePreview(context, state.mode, l10n),
                ],
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          // Language selector
          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, state) {
              return _buildSettingsTile(
                context,
                icon: Icons.language_outlined,
                title: l10n.language,
                subtitle: _getLanguageLabel(state.language, l10n),
                onTap: () => _showLanguagePicker(context, state.language, l10n),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildThemePreview(
      BuildContext context, AppThemeMode mode, AppLocalizations l10n) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildThemeOption(
            context,
            label: l10n.light,
            icon: Icons.light_mode,
            isSelected: mode == AppThemeMode.light,
            onTap: () =>
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.light),
          ),
          _buildThemeOption(
            context,
            label: l10n.dark,
            icon: Icons.dark_mode,
            isSelected: mode == AppThemeMode.dark,
            onTap: () =>
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.dark),
          ),
          _buildThemeOption(
            context,
            label: l10n.system,
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
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.light;
      case AppThemeMode.dark:
        return l10n.dark;
      case AppThemeMode.system:
        return l10n.system;
    }
  }

  String _getLanguageLabel(AppLanguage language, AppLocalizations l10n) {
    switch (language) {
      case AppLanguage.km:
        return l10n.khmer;
      case AppLanguage.en:
        return l10n.english;
    }
  }

  void _showThemePicker(
      BuildContext context, AppThemeMode currentMode, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppSpacing.paddingMd,
              child: Text(
                l10n.chooseDisplayMode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text(l10n.light),
              trailing: currentMode == AppThemeMode.light
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(l10n.dark),
              trailing: currentMode == AppThemeMode.dark
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.read<ThemeCubit>().setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: Text(l10n.system),
              subtitle: Text(l10n.useDeviceSettings),
              trailing: currentMode == AppThemeMode.system
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
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

  void _showLanguagePicker(BuildContext context, AppLanguage currentLanguage,
      AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppSpacing.paddingMd,
              child: Text(
                l10n.chooseLanguage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Text('🇰🇭', style: TextStyle(fontSize: 24)),
              title: Text(l10n.khmer),
              trailing: currentLanguage == AppLanguage.km
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.read<LocaleCubit>().setLanguage(AppLanguage.km);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(l10n.english),
              trailing: currentLanguage == AppLanguage.en
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.read<LocaleCubit>().setLanguage(AppLanguage.en);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection(
      BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.folder_outlined,
            title: l10n.documentCount,
            subtitle: _isLoadingStorage
                ? l10n.counting
                : '$_documentCount ${l10n.documents}',
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.pie_chart_outline,
            title: l10n.storageUsed,
            subtitle:
                _storageUsed.isEmpty ? l10n.unableToCalculate : _storageUsed,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.cleaning_services_outlined,
            title: l10n.clearCache,
            subtitle: l10n.clearCacheSubtitle,
            onTap: () => _showClearCacheDialog(context, l10n),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  void _showClearCacheDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCacheTitle),
        content: Text(l10n.clearCacheMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(this.context);
              Navigator.pop(context);
              await _clearCache();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.cacheCleared)),
                );
              }
            },
            child: Text(l10n.clear),
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

  Widget _buildAboutSection(
      BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.apps,
            title: l10n.app,
            subtitle: AppConstants.appName,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.numbers,
            title: l10n.version,
            subtitle: AppConstants.appVersion,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: l10n.license,
            subtitle: l10n.tapToViewLicense,
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
            'assets/icon/app_icon.png',
            width: 64,
            height: 64,
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection(
      BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.rate_review_outlined,
            title: l10n.rateApp,
            subtitle: l10n.rateAppSubtitle,
            onTap: () => _rateApp(l10n),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.share_outlined,
            title: l10n.shareApp,
            subtitle: l10n.shareAppSubtitle,
            onTap: () => _shareApp(l10n),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.bug_report_outlined,
            title: l10n.reportBug,
            subtitle: l10n.reportBugSubtitle,
            onTap: () => _reportBug(),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
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
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
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

  void _rateApp(AppLocalizations l10n) {
    // TODO: Implement app store rating
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.featureComingSoon)),
    );
  }

  void _shareApp(AppLocalizations l10n) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.featureComingSoon)),
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
