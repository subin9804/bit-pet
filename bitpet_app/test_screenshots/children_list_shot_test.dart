import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/guardian/data/guardian_repository.dart';
import 'package:bitpet_app/features/guardian/presentation/children_screen.dart';
import 'harness.dart';

/// 자녀 계정 목록 — 스위치·공유 줄이 아바타 아래로 들여 쓰지 않고 왼쪽에 붙는다.
void main() {
  testWidgets('자녀 목록', (t) async {
    await shot(t, 'children_list', const ChildrenScreen(), pushed: true, overrides: [
      childrenProvider.overrideWith((ref) async => [
            ChildAccount(
                id: 1,
                email: 'kid1@naver.com',
                nickname: '도윤',
                profileImageUrl: null,
                profileColor: 'peach',
                birthDate: DateTime(2016, 3, 1),
                isChild: true,
                communityEnabled: true),
            ChildAccount(
                id: 2,
                email: 'kid2@gmail.com',
                nickname: '서아',
                profileImageUrl: null,
                profileColor: 'sky',
                birthDate: DateTime(2018, 7, 9),
                isChild: true),
          ]),
    ]);
  });
}
