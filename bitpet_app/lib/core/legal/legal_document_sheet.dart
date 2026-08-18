import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'legal_documents.dart';

/// 약관 전문 뷰어.
///
/// 회원가입 3단계와 마이페이지 > 앱 정보가 같이 쓴다.
/// 화면을 새로 밀지 않고 바텀시트로 띄우는 이유 — 가입 도중에 라우트를 쌓으면
/// 뒤로가기로 돌아왔을 때 입력 상태 복원이 얽힌다.
Future<void> showLegalDocument(BuildContext context, LegalDocument doc) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (_) => _LegalDocumentSheet(doc: doc),
  );
}

class _LegalDocumentSheet extends StatelessWidget {
  final LegalDocument doc;

  const _LegalDocumentSheet({required this.doc});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.paleLine)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '시행일 ${doc.effectiveDate}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.paleInk3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.paleInk2,
                  tooltip: '닫기',
                ),
              ],
            ),
          ),

          // 본문
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: SelectableText(
                doc.body.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.65,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // 하단 버튼 — 제스처 영역 침범을 피하려고 safe area 만큼 띄운다
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.bg2,
                  foregroundColor: AppColors.primary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
