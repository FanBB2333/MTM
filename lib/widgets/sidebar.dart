import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../services/pn532_service.dart';
import '../l10n/app_localizations.dart';
import 'menu_item.dart';

/// 侧边栏组件
/// 固定宽度250px，包含Logo和菜单项
class Sidebar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final _pn532Service = PN532Service.instance;

  // 菜单项图标配置
  static const List<IconData> menuIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.creditcard,
    CupertinoIcons.pencil,
    CupertinoIcons.folder_fill,
    CupertinoIcons.gear,
  ];

  @override
  void initState() {
    super.initState();
    _pn532Service.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _pn532Service.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<String> _getMenuTitles(AppLocalizations l10n) {
    return [
      l10n.menuConnect,
      l10n.menuReadCard,
      l10n.menuWriteCard,
      l10n.menuSavedCards,
      l10n.menuSettings,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final menuTitles = _getMenuTitles(l10n);
    
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo 区域
          _buildHeader(),
          
          const SizedBox(height: 8),
          
          // 菜单项
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: menuIcons.length,
              itemBuilder: (context, index) {
                return SidebarMenuItem(
                  icon: menuIcons[index],
                  title: menuTitles[index],
                  isActive: widget.currentIndex == index,
                  onTap: () => widget.onItemSelected(index),
                );
              },
            ),
          ),

          // 底部状态指示
          _buildStatusIndicator(l10n),
        ],
      ),
    );
  }

  /// Logo 和标题区域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: [
          // NFC 图标
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.radiowaves_right,
              size: 24,
              color: AppColors.iconActive,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PN532',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'NFC Tools',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 底部连接状态指示器
  Widget _buildStatusIndicator(AppLocalizations l10n) {
    final isConnected = _pn532Service.isConnected;
    final port = _pn532Service.connectedPort;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppColors.success.withAlpha(75) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.success : AppColors.textDisabled,
              shape: BoxShape.circle,
              boxShadow: isConnected
                  ? [BoxShadow(color: AppColors.success.withAlpha(100), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected ? l10n.connected : l10n.disconnected,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isConnected ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
                if (isConnected && port != null)
                  Text(
                    port.split('/').last,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (_pn532Service.isScanning)
            const CupertinoActivityIndicator(radius: 8),
        ],
      ),
    );
  }
}

