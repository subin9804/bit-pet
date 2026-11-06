import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/toast_message.dart';
import 'image_upload.dart';

/// 프로필용 정사각형 자르기. 취소하면 null.
///
/// 개체 프로필 사진만 거친다 — 갤러리·커뮤니티는 원본 그대로 올린다.
/// 갤러리의 '대표 사진으로 설정'도 자르지 않는다 (잘린 사진을 새로 올리면 갤러리에
/// 한 장이 더 생긴다). 잘라서 쓰고 싶으면 프로필 자리에서 새로 고르면 된다.
///
/// 원은 **가이드일 뿐** 결과는 정사각형이다. 프로필이 원·둥근 사각형 양쪽으로
/// 그려지므로 모서리를 투명하게 오려내면 사각 자리에서 빈 귀퉁이가 보인다.
Future<PickedImage?> cropProfileImage(BuildContext context, PickedImage src) {
  return Navigator.of(context).push<PickedImage>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ProfileCropPage(src: src),
    ),
  );
}

/// 결과 한 변 최대 길이. 프로필은 화면 폭 정도로만 크게 보이므로 이 이상은 낭비다.
const int _kCropMaxEdge = 1080;

class _ProfileCropPage extends StatefulWidget {
  final PickedImage src;
  const _ProfileCropPage({required this.src});

  @override
  State<_ProfileCropPage> createState() => _ProfileCropPageState();
}

class _ProfileCropPageState extends State<_ProfileCropPage> {
  final _controller = CropController();
  bool _ready = false;
  bool _cropping = false;

  void _done() {
    setState(() => _cropping = true);
    _controller.crop(); // 결과는 onCropped 로 온다
  }

  Future<void> _onCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        // 자르기 결과는 원본 포맷(PNG 일 수도 있다)에 무손실에 가깝게 인코딩돼 크다.
        // 다른 업로드와 똑같이 JPEG 로 맞추고 크기도 줄인다.
        final jpeg = await FlutterImageCompress.compressWithList(
          croppedImage,
          minWidth: _kCropMaxEdge,
          minHeight: _kCropMaxEdge,
          quality: 85,
          format: CompressFormat.jpeg,
        );
        if (!mounted) return;
        final base = widget.src.filename.replaceFirst(RegExp(r'\.[^.]*$'), '');
        Navigator.of(context).pop(PickedImage(
          bytes: jpeg,
          filename: '${base}_crop.jpg',
          contentType: 'image/jpeg',
        ));
      case CropFailure():
        if (!mounted) return;
        setState(() => _cropping = false);
        ToastMessage.show(context, '사진을 자르지 못했어요. 다시 시도해 주세요.',
            type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('사진 자르기'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Crop(
                image: widget.src.bytes,
                controller: _controller,
                onCropped: _onCropped,
                aspectRatio: 1,
                withCircleUi: true,
                // 틀은 고정하고 사진을 움직인다 — 손가락으로 끌고 두 손가락으로 확대
                interactive: true,
                fixCropRect: true,
                initialRectBuilder:
                    InitialRectBuilder.withSizeAndRatio(size: 0.9, aspectRatio: 1),
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.6),
                cornerDotBuilder: (_, _) => const SizedBox.shrink(),
                progressIndicator: const CircularProgressIndicator(
                    color: AppColors.brand300),
                onStatusChanged: (s) {
                  if (!mounted) return;
                  final ready = s == CropStatus.ready;
                  if (ready != _ready) setState(() => _ready = ready);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                '사진을 움직이거나 두 손가락으로 확대해 맞춰 주세요',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: AppActionButton(
                  '완료',
                  loading: _cropping,
                  onPressed: _ready ? _done : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
