import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../widgets/app_sheet.dart';
import 'image_upload.dart';

/// 사진을 어디서 가져올지 — 촬영 / 갤러리.
enum _ImageSource { camera, gallery }

/// '촬영 / 갤러리에서 선택' 을 먼저 묻고 1장을 받는다. 취소하면 null.
///
/// 사진을 받는 자리는 **전부 이 함수를 거친다** — `pickFromGallery` 를 직접 부르면
/// 그 화면만 촬영이 안 된다 (2026-10-30 사용자 요청으로 촬영을 붙이면서 모았다).
Future<PickedImage?> pickImageWithSource(
    BuildContext context, WidgetRef ref) async {
  final source = await _askSource(context);
  if (source == null) return null;
  final service = ref.read(imageUploadServiceProvider);
  return source == _ImageSource.camera
      ? service.pickFromCamera()
      : service.pickFromGallery();
}

/// 여러 장 받는 자리용. 촬영은 한 번에 1장이라 목록 하나짜리로 돌려준다.
Future<List<PickedImage>> pickImagesWithSource(
    BuildContext context, WidgetRef ref,
    {int? limit}) async {
  final source = await _askSource(context);
  if (source == null) return const [];
  final service = ref.read(imageUploadServiceProvider);
  if (source == _ImageSource.camera) {
    final one = await service.pickFromCamera();
    return one == null ? const [] : [one];
  }
  return service.pickMultiFromGallery(limit: limit);
}

Future<_ImageSource?> _askSource(BuildContext context) {
  return showAppSheet<_ImageSource>(
    context: context,
    builder: (ctx) => AppSheet(
      title: '사진 추가',
      child: SheetCard.list(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.ink2),
              title: const Text('촬영하기'),
              onTap: () => Navigator.pop(ctx, _ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.ink2),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, _ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}
