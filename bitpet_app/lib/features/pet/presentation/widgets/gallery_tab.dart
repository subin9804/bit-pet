import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/upload/image_upload.dart';
import '../../../../core/widgets/confirm_modal.dart';
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
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (!isProfile)
              ListTile(
                leading: const Icon(Icons.star_outline, color: AppColors.primary),
                title: const Text('대표 사진으로 설정'),
                onTap: () => Navigator.pop(context, 'profile'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('삭제', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
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
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: List.generate(
                9,
                (i) => Container(
                      decoration: const BoxDecoration(color: AppColors.paleBgAlt),
                    )),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (photos) {
            if (photos.isEmpty) {
              return const _EmptyGallery();
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
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
        const SizedBox(height: 16),

        // 사진 추가 버튼
        GestureDetector(
          onTap: _uploading ? null : _addPhoto,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine, width: 1.5),
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
                      size: 20, color: AppColors.paleInk2),
                const SizedBox(width: 8),
                Text(_uploading ? '업로드 중…' : '사진 추가',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.paleInk2)),
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
              top: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.primary),
                child: const Icon(Icons.star, size: 12, color: Colors.white),
              ),
            ),
          if (photo.tag != null)
            Positioned(
              bottom: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                child: Text(photo.tag!,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ),
          Positioned(
            top: 4, right: 4,
            child: Text(
              '${photo.createdAt.month}.${photo.createdAt.day}',
              style: AppTextStyles.mono(8, FontWeight.w700,
                  color: AppColors.primary.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48, color: AppColors.paleInk3),
            const SizedBox(height: 12),
            Text('아직 사진이 없어요',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paleInk3)),
            const SizedBox(height: 4),
            Text('아래 버튼으로 첫 사진을 추가해 보세요',
                style: TextStyle(fontSize: 12, color: AppColors.paleInk3)),
          ],
        ),
      ),
    );
  }
}
