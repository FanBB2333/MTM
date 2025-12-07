import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/sidebar.dart';
import 'pages/connect_page.dart';
import 'pages/read_card_page.dart';
import 'pages/write_card_page.dart';
import 'pages/saved_cards_page.dart';
import 'pages/settings_page.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_provider.dart';

void main() {
  runApp(const PN532App());
}

/// PN532 NFC Tools 主应用
class PN532App extends StatelessWidget {
  const PN532App({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'PN532 NFC Tools',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: LocaleProvider.instance.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainScreen(),
        );
      },
    );
  }
}


/// 主界面 - 左右分栏布局
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 页面列表
  final List<Widget> _pages = const [
    ConnectPage(),
    ReadCardPage(),
    WriteCardPage(),
    SavedCardsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧: 侧边栏导航
          Sidebar(
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() => _currentIndex = index);
            },
          ),
          
          // 右侧: 内容区域
          Expanded(
            child: Container(
              color: AppColors.mainBackground,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _pages[_currentIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
