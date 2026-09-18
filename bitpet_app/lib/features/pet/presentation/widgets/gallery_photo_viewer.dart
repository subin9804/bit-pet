// 갤러리 사진 전체화면 캐러셀 — 좌우 스와이프로 넘기고, 두 손가락으로 확대한다.
// 대표 설정·삭제는 우측 상단 더보기에서 고르면 뷰어를 닫고 호출자에게 넘긴다
// (삭제 후 목록이 바뀌므로 뷰어 안에서 페이지를 다시 맞추는 것보다 닫는 쪽이 단순하다).
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/photo_models.dart';

/// 뷰어에서 고른 동작. [action] 은 'profile' / 'delete'.
typedef GalleryViewerResult = ({String action, PetPhoto photo});

class GalleryPhotoViewer extends StatefulWidget {
  final List<PetPhoto> photos;
  final int initialIndex;
  final int? profilePhotoId;

  const GalleryPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.profilePhotoId,
  });

  static Future<GalleryViewerResult?> show(
    BuildContext context, {
    required List<PetPhoto> photos,
    required int initialIndex,
    int? profilePhotoId,
  }) {
    return Navigator.of(context, rootNavigator: true).push<GalleryViewerResult>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, __, ___) => GalleryPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
          profilePhotoId: profilePhotoId,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<GalleryPhotoViewer> createState() => _GalleryPhotoViewerState();
}

class _GalleryPhotoViewerState extends State<GalleryPhotoViewer> {
  late final PageController _controller;
  late int _index;
  // 확대 중에는 PageView 스와이프를 막아야 사진 안에서 이동할 수 있다
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PetPhoto get _current => widget.photos[_index];

  Future<void> _openMenu() async {
    final photo = _current;
    final isProfile = widget.profilePhotoId == photo.id;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (!isProfile)
              ListTile(
                leading:
                    const Icon(Icons.star_outline, color: AppColors.primary),
                title: const Text('대표 사진으로 설정'),
                onTap: () => Navigator.pop(sheetCtx, 'profile'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('삭제', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(sheetCtx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    Navigator.pop<GalleryViewerResult>(context, (action: action, photo: photo));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final photo = _current;
    final isProfile = widget.profilePhotoId == photo.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 사진 ──
          PageView.builder(
            controller: _controller,
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() {
              _index = i;
              _zoomed = false;
            }),
            itemBuilder: (_, i) => _ZoomablePhoto(
              key: ValueKey(widget.photos[i].id),
              url: widget.photos[i].url,
              onZoomChanged: (z) {
                if (z != _zoomed) setState(() => _zoomed = z);
              },
            ),
          ),

          // ── 상단 바 ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        '${_index + 1} / ${widget.photos.length}',
                        style: AppTextStyles.mono(13, FontWeight.w700,
                            color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _openMenu,
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 하단 정보 ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      if (isProfile) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          color: Colors.white,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star,
                                  size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('대표',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (photo.tag != null) ...[
                        Flexible(
                          child: Text(
                            photo.tag!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      Text(
                        _fmtDate(photo.createdAt.toLocal()),
                        style: AppTextStyles.mono(12, FontWeight.w600,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 페이지 점 (사진이 2장 이상, 20장 이하일 때만) ──
          if (widget.photos.length > 1 && widget.photos.length <= 20)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photos.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: active ? 14 : 5,
                    height: 5,
                    color: active ? Colors.white : Colors.white38,
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  final String url;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePhoto({
    super.key,
    required this.url,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _tc = TransformationController();
  TapDownDetails? _doubleTapDown;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onZoomChanged(_tc.value.getMaxScaleOnAxis() > 1.01);
  }

  // 더블탭: 확대 상태면 원래대로, 아니면 탭한 지점을 2.5배로
  void _onDoubleTap() {
    if (_tc.value.getMaxScaleOnAxis() > 1.01) {
      _tc.value = Matrix4.identity();
    } else {
      final p = _doubleTapDown?.localPosition ?? Offset.zero;
      const s = 2.5;
      _tc.value = Matrix4.translationValues(-p.dx * (s - 1), -p.dy * (s - 1), 0)
        ..multiply(Matrix4.diagonal3Values(s, s, 1));
    }
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapDown = d,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _tc,
        minScale: 1,
        maxScale: 4,
        onInteractionEnd: (_) => _notify(),
        child: SizedBox.expand(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70)),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 40, color: Colors.white38),
            ),
          ),
        ),
      ),
    );
  }
}
