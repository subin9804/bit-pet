import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../../../core/upload/image_upload.dart';
import '../../../../core/widgets/confirm_modal.dart';
import '../../../../core/widgets/toast_message.dart';
import '../../data/models/photo_models.dart';
import '../../data/pet_repository.dart';
import '../../data/photo_repository.dart';
import '../../providers/pet_provider.dart';
import '../../providers/photo_provider.dart';

class GalleryTab extends ConsumerStatefulWidget {
  final int petId;
  final PetPaletteKey paletteKey;
  final int? profilePhotoId;

  const GalleryTab({
    super.key,
    required this.petId,
    required this.paletteKey,
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
    final bg = PalePalette.pale(widget.paletteKey);

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
              return _EmptyGallery(paletteKey: widget.paletteKey);
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
                bg: bg,
                isProfile: widget.profilePhotoId == photos[i].id,
                onTap: () => _onTileMenu(photos[i]),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // 사진 추가 버튼
        GestureDetector(
          onTap: _uploading ? null : _addPhoto,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_uploading)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.camera_alt_outlined,
                      size: 18, color: AppColors.paleInk2),
                const SizedBox(width: 6),
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
  final Color bg;
  final bool isProfile;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.photo,
    required this.bg,
    required this.isProfile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            photo.url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: bg,
              child: const Icon(Icons.pets, color: AppColors.primary, size: 28),
            ),
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    color: AppColors.paleBgAlt,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 1.5))),
          ),
          if (isProfile)
            Positioned(
              top: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.primary),
                child: const Icon(Icons.star, size: 10, color: Colors.white),
              ),
            ),
          if (photo.tag != null)
            Positioned(
              bottom: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
  final PetPaletteKey paletteKey;

  const _EmptyGallery({required this.paletteKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
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
