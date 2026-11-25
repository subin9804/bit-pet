import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/presentation/user_profile_screen.dart';
import 'package:bitpet_app/features/pet/providers/pet_provider.dart';
import 'harness.dart';

/// NFC 이름표에서 사육자를 눌러 들어온 경우 — 셸 Navigator 에 이 화면 하나뿐이어도
/// 뒤로가기가 있어야 하고 '프로필' 제목이 왼쪽 끝에 붙지 않아야 한다.
void main() {
  testWidgets('프로필 — 스택 맨 아래', (t) async {
    await shot(t, 'user_profile_root', const UserProfileScreen(userId: 7),
        overrides: [
          userProfileProvider(7).overrideWith((ref) async =>
              const PublicUserProfile(userId: 7, nickname: '게코집사', petsHidden: true)),
        ]);
  });
}
