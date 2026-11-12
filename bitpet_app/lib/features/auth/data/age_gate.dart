import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 가입 연령 확인 (2026-11-13).
///
/// '만 14세 이상입니다' 체크박스는 기준선을 대놓고 알려줘서 그냥 체크하고 넘어가면 그만이었다.
/// 그래서 화면에서는 기준 나이를 말하지 않고 생년월일만 묻는다. 판정은 서버도 똑같이 한다
/// (AgePolicy) — 여기 판정은 안내 화면으로 보내기 위한 것뿐이다.
/// 생년월일은 판정에만 쓰고 서버에 남지 않는다.
class AgeGate {
  AgeGate._();

  /// 개인정보 보호법 제22조의2 — 이 나이 미만은 법정대리인 동의가 필요하다.
  static const consentAge = 14;

  static bool isUnderConsentAge(DateTime birth, {DateTime? now}) {
    final today = now ?? DateTime.now();
    var age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age < consentAge;
  }

  /// 서버로 보내는 형식 (LocalDate)
  static String format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

final ageGateStoreProvider = Provider<AgeGateStore>((ref) => AgeGateStore());

/// 이 기기에서 만 14세 미만으로 판정된 적이 있는지.
///
/// 판정 뒤 뒤로 가서 생년월일만 바꿔 다시 가입하는 걸 막는다. 앱을 지우면 같이 지워지니
/// 완벽한 차단은 아니다 — 본인인증 없이 할 수 있는 만큼의 문턱이다.
class AgeGateStore {
  static const _key = 'age_gate_under_consent';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> isBlocked() async {
    try {
      return await _storage.read(key: _key) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> block() async {
    try {
      await _storage.write(key: _key, value: '1');
    } catch (_) {
      // 저장 실패해도 지금 화면은 이미 안내로 바뀌었다 — 가입을 막는 건 서버다
    }
  }
}
