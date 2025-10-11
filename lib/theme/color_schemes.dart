import 'package:flutter/material.dart';

/// Pavra brand color palette
/// 品牌颜色调色板
class PavraColors {
  PavraColors._();

  // 品牌主色 - Logo colors
  static const Color logoYellow = Color(0xFFF2D336);
  static const Color logoYellowVariant = Color(0xFFD4B82E);

  // 背景颜色 - Background colors
  static const Color lightBackground = Color(0xFFFDFFE0); // 浅色背景
  static const Color darkBackground = Color(0xFF202020); // 深色背景

  // 强调色 - Accent colors
  static const Color activeButton = logoYellow; // 活动按钮颜色
  static const Color navbarActive = logoYellow; // 导航栏激活状态

  // 辅助颜色 - Supporting colors
  static const Color alertOrange = Color(0xFFFF6F00);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF388E3C);
  static const Color warningAmber = Color(0xFFF57C00);

  // 文字颜色 - Text colors
  static const Color textOnYellow = Color(0xFF202020); // 黄色背景上的深色文字
  static const Color textOnLight = Color(0xFF212121); // 浅色背景上的深色文字
  static const Color textOnDark = Color(0xFFFFFFFF); // 深色背景上的浅色文字
}
