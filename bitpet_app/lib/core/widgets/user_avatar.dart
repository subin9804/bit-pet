import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import './app_network_image.dart';

/// 프로필 색 팔레트 — 서버는 이 **키**를 저장하고(`user_mst.profile_color`)
/// 실제 색은 앱이 해석한다. 테마가 바뀌어도 'peach' 는 계속 'peach' 다.
///
/// 회원가입 화면과 마이페이지가 각자 목록을 들고 있으면 반드시 어긋나므로 여기 한 곳에 둔다.
class ProfilePalette {
  static const defaultKey = 'peach';

  /// (키, 배경색, 잉크색) — 순서가 곧 화면에 보이는 순서다
  static const entries = <(String, Color, Color)>[
    ('sage', AppColors.petSage, AppColors.petSageInk),
    ('peach', AppColors.petPeach, AppColors.petPeachInk),
    ('sky', AppColors.petSky, AppColors.petSkyInk),
    ('lilac', AppColors.petLilac, AppColors.petLilacInk),
    ('butter', AppColors.petButter, AppColors.petButterInk),
    ('coral', AppColors.petCoral, AppColors.petCoralInk),
  ];

  /// 모르는 키(서버에 새 색이 생겼는데 앱이 옛 버전인 경우)는 기본색으로 떨어뜨린다.
  /// 여기서 던지면 색 하나 때문에 프로필 화면 전체가 깨진다.
  static (Color, Color) resolve(String? key) {
    for (final (k, bg, ink) in entries) {
      if (k == key) return (bg, ink);
    }
    return (AppColors.petPeach, AppColors.petPeachInk);
  }

  static Color bgOf(String? key) => resolve(key).$1;
  static Color inkOf(String? key) => resolve(key).$2;
}

/// 사용자 프로필 아바타.
///
/// **사진이 없으면** 프로필 색이 배경이 되고 이모지가 올라간다.
/// **사진이 있으면** 사진이 배경을 덮고, 프로필 색은 [borderWidth] 두께의 테두리로 남는다 —
/// 고른 색이 사진 때문에 통째로 사라지면 색을 고른 의미가 없어지기 때문이다.
///
/// [localBytes] 는 아직 업로드되지 않은 사진(회원가입 중)을 미리 보여주기 위한 것이다.
/// 계정이 없으면 S3 presign 을 받을 수 없어 가입 완료 후에야 업로드할 수 있다.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? localBytes;
  final String? colorKey;
  final double size;
  final double borderWidth;
  final String emoji;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.localBytes,
    this.colorKey,
    this.size = 56,
    this.borderWidth = 3,
    this.emoji = '🦎',
  });

  bool get _hasPhoto => localBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final color = ProfilePalette.bgOf(colorKey);

    if (!_hasPhoto) {
      return Container(
        width: size,
        height: size,
        color: color,
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: size * 0.43)),
      );
    }

    // 테두리는 바깥쪽에 그린다. Container 의 border 는 안쪽을 파고들어
    // 사진이 테두리 두께만큼 잘려 보인다.
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      color: color,
      child: ClipRect(
        child: localBytes != null
            ? Image.memory(localBytes!, fit: BoxFit.cover, width: size, height: size)
            : AppNetworkImage(
                imageUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                memWidth: (size * 3).round(),
                placeholder: Container(
                  color: AppColors.bg2,
                  alignment: Alignment.center,
                  child: Text(emoji, style: TextStyle(fontSize: size * 0.4)),
                ),
              ),
      ),
    );
  }
}
