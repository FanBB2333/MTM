import 'package:flutter/material.dart';

/// PN532 Tools 配色方案
/// 基于设计文档的极简主义、柔和色调 - 蓝色系
class AppColors {
  AppColors._();

  // 背景色
  static const Color mainBackground = Color(0xFFFBFCFF);  // 极淡蓝白
  static const Color sidebarBackground = Color(0xFFF3F5F8);  // 侧边栏浅蓝灰

  // 主色调
  static const Color primary = Color(0xFFD6E4FF);  // 淡天蓝色（选中状态）
  static const Color primaryLight = Color(0xFFE8F0FF);  // 更淡的蓝色（悬浮）

  // 图标和文字
  static const Color iconActive = Color(0xFF4A5568);  // 深蓝灰色
  static const Color iconInactive = Color(0xFF9DA5B4);  // 蓝灰色
  static const Color textPrimary = Color(0xFF2C3E50);  // 主标题（深蓝灰）
  static const Color textSecondary = Color(0xFF5A6C7D);  // 副标题
  static const Color textDisabled = Color(0xFFC4CDD5);  // 禁用

  // 状态色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);

  // 卡片和边框
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE8ECF0);
}
