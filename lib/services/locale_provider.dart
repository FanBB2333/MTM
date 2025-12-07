import 'package:flutter/material.dart';

/// 语言状态管理
/// 使用 ChangeNotifier 管理当前语言设置
class LocaleProvider extends ChangeNotifier {
  static final LocaleProvider _instance = LocaleProvider._internal();
  static LocaleProvider get instance => _instance;
  
  LocaleProvider._internal();
  
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  /// 支持的语言列表
  static const List<LocaleInfo> supportedLocales = [
    LocaleInfo(locale: Locale('en'), name: 'English'),
    LocaleInfo(locale: Locale('zh', 'CN'), name: '简体中文'),
    LocaleInfo(locale: Locale('zh', 'TW'), name: '繁體中文'),
  ];
  
  /// 切换语言
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
  
  /// 获取当前语言名称
  String get currentLanguageName {
    for (final info in supportedLocales) {
      if (info.locale == _locale) {
        return info.name;
      }
    }
    return 'English';
  }
}

/// 语言信息
class LocaleInfo {
  final Locale locale;
  final String name;
  
  const LocaleInfo({required this.locale, required this.name});
}
