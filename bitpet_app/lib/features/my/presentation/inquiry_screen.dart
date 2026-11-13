// 개발자에게 문의하기.
//
// 답장이 없는 일방향 건의함이다 — 운영자는 서버 DB 를 직접 본다. 그래서 '내 문의 내역'
// 화면도, 답변 알림도 없다. 화면에 그 사실을 미리 적어둔다: 답장을 기다리게 만들면
// 안 오는 답장이 불만이 된다.
//
// 앱 버전·OS 는 사용자가 적지 않아도 같이 보낸다. 오류 제보는 '어느 버전에서' 를
// 모르면 재현할 수 없다.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_memo_field.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/inquiry_repository.dart';

class InquiryScreen extends ConsumerStatefulWidget {
  const InquiryScreen({super.key});

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final _contentCtrl = TextEditingController();
  InquiryCategory _category = InquiryCategory.suggestion;
  bool _submitting = false;

  /// 서버 `InquiryCreateRequest.content` 의 @Size 와 같아야 한다.
  static const _maxLength = 2000;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_submitting && _contentCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final info = await PackageInfo.fromPlatform();
      await ref.read(inquiryRepositoryProvider).send(
            category: _category,
            content: _contentCtrl.text,
            appVersion: '${info.version}+${info.buildNumber}',
            platform: Platform.operatingSystem,
            osVersion: _clip(Platform.operatingSystemVersion, 100),
          );
      if (!mounted) return;
      showToast(context, '보냈어요. 고마워요!', type: ToastType.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showToast(
        context,
        serverMessageOf(e) ?? '보내지 못했어요. 잠시 후 다시 시도해 주세요',
        type: ToastType.error,
      );
    }
  }

  // 안드로이드 기종에 따라 OS 문자열이 길게 붙는다 — 서버 컬럼(100자)에 맞춰 자른다.
  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        titleSpacing: 0,
        title: const Text('개발자에게 문의하기'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text(
              '불편했던 점, 있었으면 하는 기능을 편하게 남겨 주세요.\n'
              '하나하나 읽고 앱에 반영할게요. 따로 답장은 드리지 않아요.',
              style:
                  TextStyle(fontSize: 13, height: 1.6, color: AppColors.ink3),
            ),
            const SizedBox(height: 20),
            const Text(
              '종류',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in InquiryCategory.values)
                  AppChip(
                    label: c.label,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppMemoField(
              controller: _contentCtrl,
              hintText: _category == InquiryCategory.bug
                  ? '어떤 화면에서 무엇을 했을 때 생겼는지 적어 주시면 빨리 고칠 수 있어요'
                  : '내용을 적어 주세요',
              maxLength: _maxLength,
              minLines: 8,
              maxLines: 14,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            const Text(
              '앱 버전과 기기 OS 정보가 함께 전송돼요.',
              style: TextStyle(fontSize: 12, color: AppColors.ink3),
            ),
            const SizedBox(height: 24),
            AppActionButton(
              '보내기',
              loading: _submitting,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
