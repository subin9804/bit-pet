import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/pale_palette.dart';

class GalleryTab extends StatelessWidget {
  final PetPaletteKey paletteKey;
  final VoidCallback? onAddPhoto;

  const GalleryTab({
    super.key,
    required this.paletteKey,
    this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    // mock 갤러리 데이터 (추후 photo API 대체)
    final items = [
      _GalleryItem(d: '12.20', tag: '탈피'),
      _GalleryItem(d: '12.14', tag: '식사'),
      _GalleryItem(d: '12.08', tag: null),
      _GalleryItem(d: '12.02', tag: '환경'),
      _GalleryItem(d: '11.24', tag: null),
      _GalleryItem(d: '11.18', tag: '체중'),
      _GalleryItem(d: '11.10', tag: null),
      _GalleryItem(d: '11.02', tag: '탈피'),
      _GalleryItem(d: '10.28', tag: null),
    ];

    final bg = PalePalette.pale(paletteKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3열 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final g = items[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 플레이스홀더 배경 (opacity 변화로 갤러리 느낌)
                  Container(
                    color: bg.withValues(alpha: 0.45 + (i % 4) * 0.18),
                    alignment: Alignment.center,
                    child: const Icon(Icons.pets,
                        color: AppColors.primary, size: 28, semanticLabel: null),
                  ),
                  // 태그 pill
                  if (g.tag != null)
                    Positioned(
                      bottom: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          g.tag!,
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                  // 날짜
                  Positioned(
                    top: 4, right: 4,
                    child: Text(
                      g.d,
                      style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 8, fontWeight: FontWeight.w700,
                          color: AppColors.primary.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
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
              border: Border.all(color: AppColors.paleLine, width: 1.5,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined,
                    size: 18, color: AppColors.paleInk2),
                const SizedBox(width: 6),
                Text(
                  '사진 추가',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.paleInk2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GalleryItem {
  final String d;
  final String? tag;
  const _GalleryItem({required this.d, this.tag});
}
