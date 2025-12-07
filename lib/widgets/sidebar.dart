import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import 'menu_item.dart';

/// 侧边栏组件
/// 固定宽度250px，包含Logo和菜单项
class Sidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  // 菜单项配置
  static const List<MenuItemData> menuItems = [
    MenuItemData(icon: CupertinoIcons.house_fill, title: 'Connect', index: 0),
    MenuItemData(icon: CupertinoIcons.creditcard, title: 'Read Card', index: 1),
    MenuItemData(icon: CupertinoIcons.pencil, title: 'Write Card', index: 2),
    MenuItemData(icon: CupertinoIcons.folder_fill, title: 'Saved Cards', index: 3),
    MenuItemData(icon: CupertinoIcons.gear, title: 'Settings', index: 4),
  ];

  @override
  Widget build(BuildContext context) {
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
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: menuItems.map((item) {
                return SidebarMenuItem(
                  icon: item.icon,
                  title: item.title,
                  isActive: currentIndex == item.index,
                  onTap: () => onItemSelected(item.index),
                );
              }).toList(),
            ),
          ),

          // 底部状态指示
          _buildStatusIndicator(),
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
  Widget _buildStatusIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.textDisabled,  // 未连接时灰色
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Disconnected',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
