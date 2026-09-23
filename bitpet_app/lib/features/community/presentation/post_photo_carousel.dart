// 게시글 첨부 사진 캐러셀 — 개체 상세 갤러리(전체화면 뷰어)와 같은 조작감을 목표로 한다.
//
// 세로로 쌓으면 사진 5장짜리 글은 본문보다 사진이 길어져서 댓글까지 한참을 내려야 한다.
// 그래서 높이를 4:3 한 칸으로 고정하고 좌우 스와이프로 넘긴다. 잘려 보이는 부분은
// 탭 → 전체화면(확대 가능)에서 원본 비율 그대로 확인한다.
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_network_image.dart';

class PostPhotoCarousel extends StatefulWidget {
  final List<String> urls;
  const PostPhotoCarousel(this.urls, {super.key});

  @override
  State<PostPhotoCarousel> createState() => _PostPhotoCarouselState();
}

class _PostPhotoCarouselState extends State<PostPhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(int i) => PostPhotoViewer.show(context, widget.urls, i);

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _open(i),
                  child: Container(
                    color: AppColors.paleBgAlt,
                    child: AppNetworkImage(
                      urls[i],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // 한 화면 폭이면 충분하다 — 원본 해상도 디코딩은 전체화면에서만.
                      memWidth: 1000,
                      placeholder: const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // ── 몇 장 중 몇 번째인지 (2장 이상일 때만) ──
              if (urls.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Text(
                      '${_index + 1} / ${urls.length}',
                      style: AppTextStyles.mono(11, FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),

              // ── 페이지 점 (20장 넘어가면 줄이 지저분해져서 숨긴다) ──
              if (urls.length > 1 && urls.length <= 20)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(urls.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 14 : 5,
                        height: 5,
                        color: active ? Colors.white : Colors.white54,
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 첨부 사진 전체화면 — 좌우 스와이프 + 두 손가락/더블탭 확대.
/// 개체 갤러리 뷰어(`GalleryPhotoViewer`)와 조작은 같지만, 이쪽은 대표 설정·삭제가 없고
/// 모델도 URL 목록뿐이라 따로 둔다.
class PostPhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const PostPhotoViewer(
      {super.key, required this.urls, required this.initialIndex});

  static Future<void> show(
      BuildContext context, List<String> urls, int initialIndex) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, __, ___) =>
            PostPhotoViewer(urls: urls, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<PostPhotoViewer> createState() => _PostPhotoViewerState();
}

class _PostPhotoViewerState extends State<PostPhotoViewer> {
  late final PageController _controller;
  late int _index;
  // 확대 중에는 PageView 스와이프를 막아야 사진 안에서 이동할 수 있다
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() {
              _index = i;
              _zoomed = false;
            }),
            itemBuilder: (_, i) => _ZoomablePhoto(
              key: ValueKey(widget.urls[i]),
              url: widget.urls[i],
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
                        '${_index + 1} / ${widget.urls.length}',
                        style: AppTextStyles.mono(13, FontWeight.w700,
                            color: Colors.white),
                      ),
                      // 닫기 버튼과 폭을 맞춰 가운데 정렬을 유지한다
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (widget.urls.length > 1 && widget.urls.length <= 20)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
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

  const _ZoomablePhoto({super.key, required this.url, required this.onZoomChanged});

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

  void _notify() => widget.onZoomChanged(_tc.value.getMaxScaleOnAxis() > 1.01);

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
          // 확대해서 보는 자리라 원본 해상도 그대로 쓴다(memWidth 없음).
          child: AppNetworkImage(
            widget.url,
            fit: BoxFit.contain,
            placeholder: const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 40, color: Colors.white38),
            ),
          ),
        ),
      ),
    );
  }
}
