import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../data/models/photo_models.dart';
import '../../providers/photo_provider.dart';

class GalleryTab extends ConsumerWidget {
  final int petId;
  final PetPaletteKey paletteKey;
  final VoidCallback? onAddPhoto;

  const GalleryTab({
    super.key,
    required this.petId,
    required this.paletteKey,
    this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(petPhotosProvider(petId));
    final bg = PalePalette.pale(paletteKey);

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
            children: List.generate(9, (i) => Container(
              decoration: const BoxDecoration(
                color: AppColors.paleBgAlt,
              ),
            )),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (photos) {
            if (photos.isEmpty) {
              return _EmptyGallery(paletteKey: paletteKey, onAdd: onAddPhoto);
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
              itemBuilder: (_, i) => _PhotoTile(photo: photos[i], bg: bg),
            );
          },
        ),
        const SizedBox(height: 14),

        // 사진 추가 버튼
        GestureDetector(
          onTap: onAddPhoto,
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
                const Icon(Icons.camera_alt_outlined,
                    size: 18, color: AppColors.paleInk2),
                const SizedBox(width: 6),
                Text('사진 추가',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
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

  const _PhotoTile({required this.photo, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            photo.url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: bg,
              child: const Icon(Icons.pets, color: AppColors.primary, size: 28),
            ),
            loadingBuilder: (_, child, progress) =>
                progress == null
                    ? child
                    : Container(color: AppColors.paleBgAlt,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 1.5))),
          ),
          // 태그 pill
          if (photo.tag != null)
            Positioned(
              bottom: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                child: Text(photo.tag!,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ),
          // 날짜
          Positioned(
            top: 4, right: 4,
            child: Text(
              '${photo.createdAt.month}.${photo.createdAt.day}',
              style: AppTextStyles.mono(8, FontWeight.w700,
                  color: AppColors.primary.withValues(alpha: 0.7)),
            ),
          ),
        ],
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  final PetPaletteKey paletteKey;
  final VoidCallback? onAdd;

  const _EmptyGallery({required this.paletteKey, this.onAdd});

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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
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
