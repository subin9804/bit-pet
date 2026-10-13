import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_sheet.dart';
import 'legal_documents.dart';

/// 약관 전문 뷰어.
///
/// 회원가입 3단계와 마이페이지 > 앱 정보가 같이 쓴다.
/// 화면을 새로 밀지 않고 바텀시트로 띄우는 이유 — 가입 도중에 라우트를 쌓으면
/// 뒤로가기로 돌아왔을 때 입력 상태 복원이 얽힌다.
Future<void> showLegalDocument(BuildContext context, LegalDocument doc) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => AppSheet(
      title: doc.title,
      // 시행일은 설명이 아니라 **맥락**이라 보조 줄에 둔다 (AppSheet 슬롯 2).
      subtitle: '시행일 ${doc.effectiveDate}',
      maxHeightFactor: 0.85,
      primaryLabel: '확인',
      onPrimary: () => Navigator.of(context).pop(),
      // 닫기 X 를 지웠다. 핸들·바깥 탭·아래 '확인' 까지 닫는 길이 셋이나 되는데
      // 넷째를 두면 제목 줄이 그만큼 좁아진다 (긴 약관 제목이 두 줄로 접혔다).
      // 긴 본문은 흰 카드 안에 넣는다 — 연회색 시트 바탕에 글씨만 얹으면
      // 읽는 면이 없어 '아직 안 그려진 화면'처럼 보인다.
      child: SheetCard(
        child: SelectableText(
          doc.body.trim(),
          style: AppTextStyles.caption.copyWith(
            height: 1.65,
            color: AppColors.ink,
          ),
        ),
      ),
    ),
  );
}
