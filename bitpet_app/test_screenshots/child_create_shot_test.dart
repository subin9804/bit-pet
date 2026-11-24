import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/widgets/step_shell.dart';
import 'package:bitpet_app/features/guardian/presentation/child_create_screen.dart';
import 'harness.dart';

/// 자녀 계정 만들기 — 비밀번호 규칙 안내 + 비밀번호 확인 칸.
void main() {
  testWidgets('비밀번호 짧음 / 확인 불일치', (t) async {
    await shot(t, 'child_create_pw_bad', const ChildCreateScreen(), pushed: true,
        before: (t) async {
      final fields = find.byType(PaleTextField);
      await t.enterText(fields.at(1), 'abc123');
      await t.enterText(fields.at(2), 'abc12');
      await t.pump();
    });
  });
  testWidgets('이메일 입력 — 인증요청 안내', (t) async {
    await shot(t, 'child_create_email', const ChildCreateScreen(), pushed: true,
        before: (t) async {
      await t.enterText(find.byType(PaleTextField).at(0), 'kid@naver.com');
      await t.pump();
    });
  });
  testWidgets('비밀번호 통과 / 확인 일치', (t) async {
    await shot(t, 'child_create_pw_ok', const ChildCreateScreen(), pushed: true,
        before: (t) async {
      final fields = find.byType(PaleTextField);
      await t.enterText(fields.at(1), 'bitpet1234!');
      await t.enterText(fields.at(2), 'bitpet1234!');
      await t.pump();
    });
  });
}
