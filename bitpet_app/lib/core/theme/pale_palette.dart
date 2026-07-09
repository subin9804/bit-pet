import 'package:flutter/material.dart';
import 'app_colors.dart';

// Pet 색상 팔레트 키 — 6가지 PALE 색상
enum PetPaletteKey { sage, peach, sky, lilac, butter, coral }

abstract final class PalePalette {
  // 팔레트 키 → pale 배경색
  static Color pale(PetPaletteKey key) => switch (key) {
        PetPaletteKey.sage   => AppColors.petSage,
        PetPaletteKey.peach  => AppColors.petPeach,
        PetPaletteKey.sky    => AppColors.petSky,
        PetPaletteKey.lilac  => AppColors.petLilac,
        PetPaletteKey.butter => AppColors.petButter,
        PetPaletteKey.coral  => AppColors.petCoral,
      };

  // 팔레트 키 → ink 색상 (텍스트/점)
  static Color ink(PetPaletteKey key) => switch (key) {
        PetPaletteKey.sage   => AppColors.petSageInk,
        PetPaletteKey.peach  => AppColors.petPeachInk,
        PetPaletteKey.sky    => AppColors.petSkyInk,
        PetPaletteKey.lilac  => AppColors.petLilacInk,
        PetPaletteKey.butter => AppColors.petButterInk,
        PetPaletteKey.coral  => AppColors.petCoralInk,
      };

  // hex colorCode → 가장 가까운 팔레트 키 (순서대로 기본값 fallback)
  static PetPaletteKey keyFromHex(String? hex) {
    if (hex == null) return PetPaletteKey.sage;
    final norm = hex.toUpperCase().replaceAll('#', '');
    // 등록된 팔레트 hex → 키 매핑 (구버전 + 신버전 모두 인식)
    const knownMap = {
      // 구 팔레트
      'E2F5ED': PetPaletteKey.sage,
      'E8F2DC': PetPaletteKey.sage,
      'FBE4D8': PetPaletteKey.peach,
      'FFE3CE': PetPaletteKey.peach,
      'D8F3FF': PetPaletteKey.sky,
      'D5F0FF': PetPaletteKey.sky,
      'EAE2FF': PetPaletteKey.lilac,
      'F1E5FF': PetPaletteKey.lilac,
      'FFF7D8': PetPaletteKey.butter,
      'FCF2CD': PetPaletteKey.butter,
      'FFD8D8': PetPaletteKey.coral,
      'FFD8D4': PetPaletteKey.coral,
      // 신 팔레트 (muted)
      'EAEEEA': PetPaletteKey.sage,
      'EEECE6': PetPaletteKey.peach,
      'E6EEF5': PetPaletteKey.sky,
      'EDE9F5': PetPaletteKey.lilac,
      'F0EFEA': PetPaletteKey.butter,
      'F0EAE7': PetPaletteKey.coral,
    };
    if (knownMap.containsKey(norm)) return knownMap[norm]!;
    // 알 수 없는 hex → 채도 기반으로 가장 가까운 색상 추정
    return _nearestByHue(_parseHex(hex));
  }

  static Color _parseHex(String hex) {
    try {
      final v = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(v | 0xFF000000);
    } catch (_) {
      return AppColors.petSage;
    }
  }

  // 간단 hue 기반 nearest-palette
  static PetPaletteKey _nearestByHue(Color c) {
    final h = HSVColor.fromColor(c).hue; // 0–360
    if (h >= 100 && h < 165) return PetPaletteKey.sage;
    if (h >= 165 && h < 255) return PetPaletteKey.sky;
    if (h >= 255 && h < 330) return PetPaletteKey.lilac;
    if (h >= 40 && h < 70)   return PetPaletteKey.butter;
    if (h >= 15 && h < 40)   return PetPaletteKey.peach;
    return PetPaletteKey.coral; // 0–15 and 330–360
  }

  // 카테고리 코드 → pale 배경
  static Color catPale(String cat) => switch (cat.toUpperCase()) {
        'WEIGHT'  => AppColors.catWeight,
        'FEEDING' => AppColors.catFeed,
        'CLEANING'=> AppColors.catClean,
        'MEMO'    => AppColors.catMemo,
        'MATING'  => AppColors.catMating,
        'LAYING'  => AppColors.catLaying,
        _         => AppColors.petSage,
      };

  // 카테고리 코드 → ink 색상
  static Color catInk(String cat) => switch (cat.toUpperCase()) {
        'WEIGHT'  => AppColors.catWeightInk,
        'FEEDING' => AppColors.catFeedInk,
        'CLEANING'=> AppColors.catCleanInk,
        'MEMO'    => AppColors.catMemoInk,
        'MATING'  => AppColors.catMatingInk,
        'LAYING'  => AppColors.catLayingInk,
        _         => AppColors.petSageInk,
      };

  // 전체 팔레트 컬러 목록 (팔레트 피커 등 사용)
  static const List<PetPaletteKey> all = PetPaletteKey.values;
}
