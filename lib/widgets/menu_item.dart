import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 菜单项数据模型
class MenuItemData {
  final IconData icon;
  final String title;
  final int index;

  const MenuItemData({
    required this.icon,
    required this.title,
    required this.index,
  });
}

/// 侧边栏菜单项组件
/// 圆角矩形背景，选中时粉色高亮
class SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.primaryLight,
          splashColor: AppColors.primary.withOpacity(0.3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? AppColors.iconActive : AppColors.iconInactive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? AppColors.textPrimary : AppColors.iconInactive,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
