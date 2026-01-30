import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/arb/app_localizations.dart';
import '../router/app_router.dart';
import '../widgets/dashboard_feature_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Returns greeting info based on current hour
  /// Returns (greeting key, icon, gradient colors)
  _GreetingInfo _getGreetingInfo(int hour) {
    if (hour >= 5 && hour < 12) {
      // Morning: 5 AM - 11:59 AM
      return _GreetingInfo(
        type: _GreetingType.morning,
        icon: Icons.wb_sunny_outlined,
        colors: [const Color(0xFFFFB347), const Color(0xFFFFCC33)],
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: 12 PM - 4:59 PM
      return _GreetingInfo(
        type: _GreetingType.afternoon,
        icon: Icons.wb_sunny,
        colors: [const Color(0xFFFF8C00), const Color(0xFFFF6B35)],
      );
    } else if (hour >= 17 && hour < 21) {
      // Evening: 5 PM - 8:59 PM
      return _GreetingInfo(
        type: _GreetingType.evening,
        icon: Icons.wb_twilight,
        colors: [const Color(0xFFFF6B6B), const Color(0xFFC44569)],
      );
    } else {
      // Night: 9 PM - 4:59 AM
      return _GreetingInfo(
        type: _GreetingType.night,
        icon: Icons.nightlight_round,
        colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      );
    }
  }

  String _getGreetingText(AppLocalizations l10n, _GreetingType type) {
    switch (type) {
      case _GreetingType.morning:
        return l10n.greetingMorning;
      case _GreetingType.afternoon:
        return l10n.greetingAfternoon;
      case _GreetingType.evening:
        return l10n.greetingEvening;
      case _GreetingType.night:
        return l10n.greetingNight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greetingInfo = _getGreetingInfo(hour);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: greetingInfo.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: greetingInfo.colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreetingText(l10n, greetingInfo.type),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashboardWelcome,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    greetingInfo.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Title
          Text(
            l10n.dashboardFeatures,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Features Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              // Feature 1: Scan Document
              DashboardFeatureCard(
                title: l10n.scanDocument,
                description: l10n.scanDocumentDescription,
                icon: Icons.document_scanner,
                color: theme.colorScheme.secondary,
                onTap: () => context.push(AppRoutes.documents),
              ),

              // Feature 2: Product Scanner
              DashboardFeatureCard(
                title: l10n.scanProduct,
                description: l10n.scanProductDescription,
                icon: Icons.qr_code_2,
                color: Colors.purple,
                onTap: () => context.push(AppRoutes.productScan),
              ),

              // Feature 3: Coming Soon
              DashboardFeatureCard(
                title: l10n.moreFeatures,
                description: l10n.moreFeaturesDescription,
                icon: Icons.auto_awesome,
                color: Colors.grey,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.featureComingSoon)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _GreetingType { morning, afternoon, evening, night }

class _GreetingInfo {
  final _GreetingType type;
  final IconData icon;
  final List<Color> colors;

  _GreetingInfo({
    required this.type,
    required this.icon,
    required this.colors,
  });
}
