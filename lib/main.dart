import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/history/history_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SafeQRApp());
}

class SafeQRApp extends StatelessWidget {
  const SafeQRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe QR Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScannerScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primary.withOpacity(0.18),
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
              label: 'Scanner',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.history_rounded, color: AppTheme.primary),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.shield_rounded, color: AppTheme.primary),
              label: 'Security',
            ),
          ],
        ),
      ),
    );
  }
}
