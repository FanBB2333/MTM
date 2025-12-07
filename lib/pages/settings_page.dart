import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_provider.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _baudRate = 115200;
  bool _autoConnect = true;
  bool _soundEnabled = true;

  final List<int> _baudRates = [9600, 19200, 38400, 57600, 115200, 230400];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            l10n.settingsTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: [
                // 串口设置
                _buildSectionTitle(l10n.serialPort),
                const SizedBox(height: 12),
                _buildDropdownSetting(
                  l10n.baudRate,
                  _baudRate.toString(),
                  _baudRates.map((e) => e.toString()).toList(),
                  (v) => setState(() => _baudRate = int.parse(v)),
                ),
                const SizedBox(height: 12),
                _buildSwitchSetting(
                  l10n.autoConnect,
                  l10n.autoConnectDesc,
                  _autoConnect,
                  (v) => setState(() => _autoConnect = v),
                ),
                
                const SizedBox(height: 32),
                
                // 通用设置
                _buildSectionTitle(l10n.general),
                const SizedBox(height: 12),
                _buildSwitchSetting(
                  l10n.soundEffects,
                  l10n.soundEffectsDesc,
                  _soundEnabled,
                  (v) => setState(() => _soundEnabled = v),
                ),
                
                const SizedBox(height: 12),
                
                // 语言设置
                _buildLanguageSetting(l10n),
                
                const SizedBox(height: 32),
                
                // 关于
                _buildSectionTitle(l10n.about),
                const SizedBox(height: 12),
                _buildInfoRow(l10n.version, '1.0.0'),
                _buildInfoRow(l10n.pn532Driver, l10n.builtIn),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLanguageSetting(AppLocalizations l10n) {
    final localeProvider = LocaleProvider.instance;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.language,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: localeProvider.currentLanguageName,
              underline: const SizedBox(),
              isDense: true,
              icon: const Icon(CupertinoIcons.chevron_down, size: 14),
              items: LocaleProvider.supportedLocales.map((info) => DropdownMenuItem(
                value: info.name,
                child: Text(info.name),
              )).toList(),
              onChanged: (name) {
                final localeInfo = LocaleProvider.supportedLocales
                    .firstWhere((info) => info.name == name);
                localeProvider.setLocale(localeInfo.locale);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              isDense: true,
              icon: const Icon(CupertinoIcons.chevron_down, size: 14),
              items: options.map((opt) => DropdownMenuItem(
                value: opt,
                child: Text(opt),
              )).toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
