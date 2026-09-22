import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pet/providers/pet_provider.dart';
import '../theme/app_icons.dart';
import './app_network_image.dart';

/// 개체 선택 자리에 쓰는 정사각 썸네일.
/// 대표사진이 있으면 사진을, 없거나 로드 실패 시 [fallback](기본 발바닥 아이콘)을 보여준다.
class PetAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color background;
  final Color iconColor;
  final Widget? fallback;
  final BoxBorder? border;

  /// 개체의 `species.subcategory`. 주면 사진 없는 자리에 그 종의 실루엣이 뜬다.
  /// 모르면 발바닥 대신 도마뱀으로 떨어진다([AppIcons.species]).
  final String? subcategory;

  const PetAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.background,
    required this.iconColor,
    this.fallback,
    this.border,
    this.subcategory,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: fallback ??
          AppIcon(
            subcategory != null ? AppIcons.species(subcategory) : AppIcons.petLine,
            size: size * 0.48,
            color: iconColor,
          ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, border: border),
      clipBehavior: Clip.hardEdge,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? AppNetworkImage(
              imageUrl,
              fit: BoxFit.cover,
              width: size,
              height: size,
              memWidth: (size * 3).round(),
              placeholder: placeholder,
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
    String? sub;
    if (pets != null) {
      for (final p in pets) {
        if (p.id == petId) {
          url = p.profileImageUrl;
          sub = p.speciesSubcategory;
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
      subcategory: sub,
    );
  }
}
