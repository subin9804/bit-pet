import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _base = TextStyle(
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static final h1 = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700);
  static final h2 = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700);
  static final h3 = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final body = _base.copyWith(fontSize: 14);
  static final bodyBold = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  static final caption = _base.copyWith(fontSize: 12, color: AppColors.textSecondary);
  static final label = _base.copyWith(
    fontSize: 11,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
    fontWeight: FontWeight.w500,
  );
  static final button = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
