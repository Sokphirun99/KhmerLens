import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/arb/app_localizations.dart';
import '../router/app_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import '../widgets/dashboard_feature_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late int _currentHour;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentHour = DateTime.now().hour;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateGreeting();
    }
  }

  void _updateGreeting() {
    final newHour = DateTime.now().hour;
    if (_currentHour != newHour) {
      setState(() {
        _currentHour = newHour;
      });
    }
  }

  _GreetingInfo _getGreetingInfo(int hour) {
    if (hour >= 5 && hour < 12) {
      // Morning: 5 AM - 11:59 AM - Light orange/yellow
      return _GreetingInfo(
        type: _GreetingType.morning,
        icon: Mdi.weather_sunny,
        colors: [const Color(0xFFFFD9A3), const Color(0xFFFFE599)],
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: 12 PM - 4:59 PM - Light orange
      return _GreetingInfo(
        type: _GreetingType.afternoon,
        icon: Mdi.white_balance_sunny,
        colors: [const Color(0xFFFFC680), const Color(0xFFFFB599)],
      );
    } else if (hour >= 17 && hour < 21) {
      // Evening: 5 PM - 8:59 PM - Light pink/rose
      return _GreetingInfo(
        type: _GreetingType.evening,
        icon: Mdi.weather_sunset,
        colors: [const Color(0xFFFFB5B5), const Color(0xFFE2A2B4)],
      );
    } else {
      // Night: 9 PM - 4:59 AM - Light blue/purple
      return _GreetingInfo(
        type: _GreetingType.night,
        icon: Mdi.weather_night,
        colors: [const Color(0xFFB3BFF5), const Color(0xFFBBA5D1)],
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
    final greetingInfo = _getGreetingInfo(_currentHour);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Iconify(Mdi.cog_outline, color: Colors.black54),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashboardWelcome,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  child: Iconify(
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
                icon: Mdi.scanner,
                color: theme.colorScheme.secondary,
                onTap: () => context.push(AppRoutes.documents),
              ),

              // Feature 2: Product Scanner
              DashboardFeatureCard(
                title: l10n.scanProduct,
                description: l10n.scanProductDescription,
                icon: Mdi.qrcode_scan,
                color: Colors.purple,
                onTap: () => context.push(AppRoutes.productScan),
              ),

              // Feature 3: Coming Soon
              DashboardFeatureCard(
                title: l10n.moreFeatures,
                description: l10n.moreFeaturesDescription,
                icon: Mdi.auto_fix,
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
  final String icon;
  final List<Color> colors;

  _GreetingInfo({
    required this.type,
    required this.icon,
    required this.colors,
  });
}
