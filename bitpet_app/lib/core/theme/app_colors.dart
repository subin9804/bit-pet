import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — retro green
  static const primary = Color(0xFF39D353);
  static const primaryDim = Color(0xFF1A6B28);

  // Secondary — amber
  static const secondary = Color(0xFFF4A42A);

  // Background (다크 테마)
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const card = Color(0xFF232330);
  static const border = Color(0xFF2E2E3E);

  // Text
  static const textPrimary = Color(0xFFE8E8E8);
  static const textSecondary = Color(0xFF9B9BB0);
  static const textDisabled = Color(0xFF5A5A70);

  // Status
  static const error = Color(0xFFFF5252);
  static const success = Color(0xFF39D353);
  static const warning = Color(0xFFF4A42A);
  static const info = Color(0xFF4A9EFF);

  // 성별 색상
  static const male = Color(0xFF4A9EFF);
  static const female = Color(0xFFFF7BAC);
  static const unknown = Color(0xFF9B9BB0);
}
