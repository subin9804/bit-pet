import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pet/providers/pet_provider.dart';

/// 개체 선택 자리에 쓰는 정사각 썸네일.
/// 대표사진이 있으면 사진을, 없거나 로드 실패 시 [fallback](기본 발바닥 아이콘)을 보여준다.
class PetAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color background;
  final Color iconColor;
  final Widget? fallback;
  final BoxBorder? border;

  const PetAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.background,
    required this.iconColor,
    this.fallback,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: fallback ?? Icon(Icons.pets, size: size * 0.48, color: iconColor),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, border: border),
      clipBehavior: Clip.hardEdge,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

/// petId 만 아는 자리(루틴 오늘 상태 등)에서 개체 목록 캐시로 대표사진을 찾아 그린다.
class PetAvatarById extends ConsumerWidget {
  final int petId;
  final double size;
  final Color background;
  final Color iconColor;
  final Widget? fallback;
  final BoxBorder? border;

  const PetAvatarById({
    super.key,
    required this.petId,
    required this.size,
    required this.background,
    required this.iconColor,
    this.fallback,
    this.border,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petListProvider).valueOrNull;
    String? url;
    if (pets != null) {
      for (final p in pets) {
        if (p.id == petId) {
          url = p.profileImageUrl;
          break;
        }
      }
    }
    return PetAvatar(
      imageUrl: url,
      size: size,
      background: background,
      iconColor: iconColor,
      fallback: fallback,
      border: border,
    );
  }
}
