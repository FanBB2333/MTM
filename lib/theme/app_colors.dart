import 'package:flutter/material.dart';

/// PN532 Tools 配色方案
/// 基于设计文档的极简主义、柔和色调
class AppColors {
  AppColors._();

  // 背景色
  static const Color mainBackground = Color(0xFFFFFBFB);  // 极淡粉白
  static const Color sidebarBackground = Color(0xFFF5F5F5);  // 侧边栏浅灰

  // 主色调
  static const Color primary = Color(0xFFFFE0D6);  // 淡鲑鱼粉（选中状态）
  static const Color primaryLight = Color(0xFFFFEDE8);  // 更淡的粉色（悬浮）

  // 图标和文字
  static const Color iconActive = Color(0xFF5A4D4D);  // 深褐灰色
  static const Color iconInactive = Color(0xFF9E9E9E);  // 灰色
  static const Color textPrimary = Color(0xFF2C2C2C);  // 主标题
  static const Color textSecondary = Color(0xFF666666);  // 副标题
  static const Color textDisabled = Color(0xFFD1C4C4);  // 禁用

  // 状态色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);

  // 卡片和边框
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFEEEEEE);
}
