import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/upload/image_upload.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/confirm_modal.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/toast_message.dart';
import '../../data/models/photo_models.dart';
import '../../data/pet_repository.dart';
import '../../data/photo_repository.dart';
import '../../providers/pet_provider.dart';
import '../../providers/photo_provider.dart';
import 'gallery_photo_viewer.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_network_image.dart';

class GalleryTab extends ConsumerStatefulWidget {
  final int petId;
  final int? profilePhotoId;

  const GalleryTab({
    super.key,
    required this.petId,
    this.profilePhotoId,
  });

  @override
  ConsumerState<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends ConsumerState<GalleryTab> {
  bool _uploading = false;

  Future<void> _addPhoto() async {
    if (_uploading) return;
    try {
      final picked =
          await ref.read(imageUploadServiceProvider).pickFromGallery();
      if (picked == null) return;
      setState(() => _uploading = true);
      await ref.read(photoRepositoryProvider).upload(
            entityType: 'PET',
            entityId: widget.petId,
            image: picked,
          );
      ref.invalidate(petPhotosProvider(widget.petId));
      if (mounted) showToast(context, '사진을 추가했어요.', type: ToastType.success);
    } catch (e) {
      if (mounted) showToast(context, '업로드 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// 사진 탭 → 전체화면 캐러셀. 뷰어에서 고른 동작(대표 설정·삭제)은 여기서 처리한다.
  Future<void> _openViewer(List<PetPhoto> photos, int index) async {
    final result = await GalleryPhotoViewer.show(
      context,
      photos: photos,
      initialIndex: index,
      profilePhotoId: widget.profilePhotoId,
    );
    if (result == null || !mounted) return;
    if (result.action == 'profile') {
      await _setProfile(result.photo);
    } else if (result.action == 'delete') {
      await _delete(result.photo);
    }
  }

  /// 사진 길게 누르기 → 뷰어를 거치지 않고 바로 메뉴
  Future<void> _onTileMenu(PetPhoto photo) async {
    final isProfile = widget.profilePhotoId == photo.id;
    final action = await showAppSheet<String>(
      context: context,
      builder: (_) => AppSheet(
        title: '사진',
        // 다른 메뉴 시트와 같이 흰 카드에 담는다.
        child: SheetCard.list(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isProfile)
              ListTile(
                contentPadding: EdgeInsets.zero,
                // `primary` 는 먹색이다 — 대표 사진은 이 개체의 '고른 것'이라
                // 브랜드색이 맞다.
                leading: const Icon(Icons.star_outline,
                    color: AppColors.brandAction),
                title: const Text('대표 사진으로 설정'),
                onTap: () => Navigator.pop(context, 'profile'),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('삭제', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
          ),
        ),
      ),
    );
    if (action == 'profile') {
      await _setProfile(photo);
    } else if (action == 'delete') {
      await _delete(photo);
    }
  }

  Future<void> _setProfile(PetPhoto photo) async {
    try {
      await ref.read(petRepositoryProvider).setProfilePhoto(widget.petId, photo.id);
      ref.invalidate(petDetailProvider(widget.petId));
      if (mounted) showToast(context, '대표 사진으로 설정했어요.', type: ToastType.success);
    } catch (e) {
      if (mounted) showToast(context, '설정 실패: $e', type: ToastType.error);
    }
  }

  Future<void> _delete(PetPhoto photo) async {
    final ok = await ConfirmModal.show(
      context,
      title: '사진 삭제',
      message: '이 사진을 삭제할까요?\n삭제하면 복구할 수 없습니다.',
      confirmLabel: '삭제',
      isDangerous: true,
    );
    if (!ok) return;
    try {
      await ref.read(photoRepositoryProvider).deletePhoto(photo.id);
      ref.invalidate(petPhotosProvider(widget.petId));
      if (widget.profilePhotoId == photo.id) {
        ref.invalidate(petDetailProvider(widget.petId));
      }
      if (mounted) showToast(context, '사진을 삭제했어요.', type: ToastType.info);
    } catch (e) {
      if (mounted) showToast(context, '삭제 실패: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(petPhotosProvider(widget.petId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        photosAsync.when(
          loading: () => GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            children: List.generate(
                9,
                // 사진 타일이 들어올 자리라 **모양이 같아야** 한다 — 각진
                // 회색 네모가 떴다가 둥근 사진으로 바뀌면 한 번 덜컥한다.
                (_) => Container(
                      decoration: const BoxDecoration(
                        color: AppColors.bgAlt,
                        borderRadius: AppRadius.brMd,
                      ),
                    )),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (photos) {
            if (photos.isEmpty) {
              // 앱의 다른 빈 자리와 같은 `EmptyState` 로 — 48px 회색
              // 아이콘 한 개는 "비었다"보다 "꺼졌다"로 읽힌다.
              return Container(
                width: double.infinity,
                decoration: AppDecor.cardRaised,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: const EmptyState(
                  icon: Icons.photo_library_outlined,
                  message: '아직 사진이 없어요',
                  subMessage: '아래 버튼으로 첫 사진을 추가해 보세요',
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: photos.length,
              itemBuilder: (_, i) => _PhotoTile(
                photo: photos[i],
                isProfile: widget.profilePhotoId == photos[i].id,
                onTap: () => _openViewer(photos, i),
                onLongPress: () => _onTileMenu(photos[i]),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.cardGap),

        // 사진 추가 버튼
        GestureDetector(
          onTap: _uploading ? null : _addPhoto,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              color: AppColors.surface,
              border: Border.all(color: AppColors.line, width: 1.5),
              boxShadow: AppShadows.elev1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_uploading)
                  // 아이콘 자리를 대신 차지하므로 크기가 아이콘과 같아야 한다 —
                  // 다르면 업로드가 시작되는 순간 줄 전체가 덜컥 움직인다.
                  const SizedBox(
                    width: AppIconSize.md, height: AppIconSize.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.camera_alt_outlined,
                      size: AppIconSize.md, color: AppColors.ink2),
                const SizedBox(width: AppSpacing.sm),
                Text(_uploading ? '업로드 중…' : '사진 추가',
                    style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final PetPhoto photo;
  final bool isProfile;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoTile({
    required this.photo,
    required this.isProfile,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      // 타일이 **각진 네모**였다 — 둥근 모서리가 전부인 테마에서 사진만
      // 직각이라 갤러리 탭만 다른 앱처럼 보였다. 배지·태그가 모서리에
      // 붙어 있어서 `ClipRRect` 로 한 번에 깎는다.
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Stack(
          fit: StackFit.expand,
          children: [
          // 그리드 썸네일은 원본을 그대로 띄우지 않는다 — 한 화면에 열 몇 장이
          // 올라오는 자리라 원본 해상도로 디코딩하면 메모리가 순식간에 찬다.
          // `displayUrl` 은 서버 축소본(512px)이고, 없으면 원본으로 떨어진다
          // (썸네일 도입 전에 올라간 사진). memWidth 는 그 폴백 경우까지 대비한 방어선.
          AppNetworkImage(
            photo.displayUrl,
            fit: BoxFit.cover,
            memWidth: 400,
            placeholder: Container(
              color: AppColors.bgAlt,
              child: const AppIcon(AppIcons.petLine,
                  color: AppColors.ink3, size: 28),
            ),
          ),
            if (isProfile)
              Positioned(
                top: AppSpacing.xs, left: AppSpacing.xs,
                // 먹색 네모였다. 대표 표시는 '고른 것'이라 브랜드색이고,
                // 별 하나만 담는 자리라 원이 맞다.
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.brandAction,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star,
                      size: AppIconSize.badge, color: AppColors.bg),
                ),
              ),
            if (photo.tag != null)
              Positioned(
                bottom: AppSpacing.xs, left: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(photo.tag!,
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: AppColors.ink)),
                ),
              ),
            Positioned(
              top: AppSpacing.xs, right: AppSpacing.xs,
              // 사진 위에 글씨를 바로 얹으면 밝은 사진에선 먹색이, 어두운
              // 사진에선 흰색이 사라진다. 어두운 알약을 깔아 어느 사진에서나
              // 같은 밝기로 읽히게 한다.
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.4),
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  '${photo.createdAt.month}.${photo.createdAt.day}',
                  style: AppTextStyles.mono(9, FontWeight.w700,
                      color: AppColors.bg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

