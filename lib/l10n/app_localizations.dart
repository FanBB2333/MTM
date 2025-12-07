import 'package:flutter/material.dart';
import 'l10n_en.dart';
import 'l10n_zh_CN.dart';
import 'l10n_zh_TW.dart';

/// 应用本地化类
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static const List<Locale> supportedLocales = [
    Locale('en'),           // English (default)
    Locale('zh', 'CN'),     // Simplified Chinese
    Locale('zh', 'TW'),     // Traditional Chinese
  ];
  
  late final Map<String, String> _localizedStrings = _loadStrings();
  
  Map<String, String> _loadStrings() {
    switch (locale.languageCode) {
      case 'zh':
        if (locale.countryCode == 'TW') {
          return l10nZhTW;
        }
        return l10nZhCN;
      default:
        return l10nEn;
    }
  }
  
  String get(String key) => _localizedStrings[key] ?? key;
  
  // === Common ===
  String get appTitle => get('appTitle');
  String get connected => get('connected');
  String get disconnected => get('disconnected');
  
  // === Sidebar Menu ===
  String get menuConnect => get('menuConnect');
  String get menuReadCard => get('menuReadCard');
  String get menuWriteCard => get('menuWriteCard');
  String get menuSavedCards => get('menuSavedCards');
  String get menuSettings => get('menuSettings');
  
  // === Connect Page ===
  String get connectTitle => get('connectTitle');
  String get connectSubtitle => get('connectSubtitle');
  String get availableDevices => get('availableDevices');
  String get scanningDevices => get('scanningDevices');
  String get noDevicesFound => get('noDevicesFound');
  String get refresh => get('refresh');
  String get connect => get('connect');
  String get disconnect => get('disconnect');
  String get connecting => get('connecting');
  String get deviceConnected => get('deviceConnected');
  String get connectionFailed => get('connectionFailed');
  String get firmwareVersion => get('firmwareVersion');
  
  // === Read Card Page ===
  String get readCardTitle => get('readCardTitle');
  String get readCardSubtitle => get('readCardSubtitle');
  String get readCardNotConnected => get('readCardNotConnected');
  String get readMode => get('readMode');
  String get fullCard => get('fullCard');
  String get sector => get('sector');
  String get block => get('block');
  String get keyA => get('keyA');
  String get keyB => get('keyB');
  String get startReading => get('startReading');
  String get reading => get('reading');
  String get cardInformation => get('cardInformation');
  String get sectorData => get('sectorData');
  String get noCardDetected => get('noCardDetected');
  String get placeCardOnReader => get('placeCardOnReader');
  String get pn532NotConnected => get('pn532NotConnected');
  String get goToConnectPage => get('goToConnectPage');
  String get authFailed => get('authFailed');
  String get notMifareClassic => get('notMifareClassic');
  
  String get keyList => get('keyList');
  String get keyListHint => get('keyListHint');
  String get loadKeysFromFile => get('loadKeysFromFile');
  String get copyData => get('copyData');
  String get copyAll => get('copyAll');
  String get dataCopied => get('dataCopied');
  
  // === Write Card Page ===
  String get writeCardTitle => get('writeCardTitle');
  String get writeCardSubtitle => get('writeCardSubtitle');
  String get dataSource => get('dataSource');
  String get loadFromFile => get('loadFromFile');
  String get selectDumpFile => get('selectDumpFile');
  String get cloneFromReader => get('cloneFromReader');
  String get useLastReadData => get('useLastReadData');
  String get options => get('options');
  String get writeBlock0 => get('writeBlock0');
  String get startWriting => get('startWriting');
  String get writing => get('writing');
  String get writingSectors => get('writingSectors');
  String get writeCompleted => get('writeCompleted');
  String get writeBlock0Warning => get('writeBlock0Warning');
  
  // === Saved Cards Page ===
  String get savedCardsTitle => get('savedCardsTitle');
  String get savedCardsSubtitle => get('savedCardsSubtitle');
  String get noSavedCards => get('noSavedCards');
  String get saveCardsHint => get('saveCardsHint');
  
  // === Settings Page ===
  String get settingsTitle => get('settingsTitle');
  String get settingsSubtitle => get('settingsSubtitle');
  String get serialPort => get('serialPort');
  String get baudRate => get('baudRate');
  String get autoConnect => get('autoConnect');
  String get autoConnectDesc => get('autoConnectDesc');
  String get general => get('general');
  String get soundEffects => get('soundEffects');
  String get soundEffectsDesc => get('soundEffectsDesc');
  String get language => get('language');
  String get about => get('about');
  String get version => get('version');
  String get pn532Driver => get('pn532Driver');
  String get builtIn => get('builtIn');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
