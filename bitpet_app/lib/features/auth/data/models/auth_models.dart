import '../age_gate.dart';

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class SignupRequest {
  final String email;
  final String password;
  final String nickname; // 서버 필드명: nickname

  /// 프로필 색 팔레트 키. 사진을 올리면 이 색이 테두리가 된다.
  final String profileColor;

  // 약관 동의. 필수 2종이 true 가 아니면 서버가 400 으로 거절한다.
  // 선택(마케팅)은 false 여도 그대로 보낸다 — 서버가 "동의 안 함"으로 기록해야
  // 나중에 "물어본 적 없음"과 구별된다.
  final bool agreeTos;
  final bool agreePrivacy;
  // 연령 확인용 생년월일. 서버가 만 14세 이상인지 판정만 하고 저장하지 않는다.
  final DateTime birthDate;
  final bool agreeMarketing;

  /// 이메일 인증 결과 토큰 (POST /auth/signup/email-code/verify). 없으면 서버가 400 으로 거절한다.
  final String emailVerificationToken;

  const SignupRequest({
    required this.email,
    required this.password,
    required this.nickname,
    this.profileColor = 'peach',
    required this.agreeTos,
    required this.agreePrivacy,
    required this.birthDate,
    required this.agreeMarketing,
    required this.emailVerificationToken,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'nickname': nickname, // 서버 SignupRequest.nickname 과 일치
        'profileColor': profileColor,
        'agreeTos': agreeTos,
        'agreePrivacy': agreePrivacy,
        'birthDate': AgeGate.format(birthDate),
        'agreeMarketing': agreeMarketing,
        'emailVerificationToken': emailVerificationToken,
      };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

/// 탈퇴 전 미리보기 — 공동 사육자가 있는 내 개체 한 마리.
/// 이 목록이 비어 있으면 탈퇴 화면에서 넘김/삭제 선택지를 띄우지 않는다.
class SharedPetPreview {
  final int petId;
  final String petName;

  /// 넘기기를 고르면 소유자가 될 사람 (가장 먼저 합류한 공동 사육자)
  final int recipientUserId;
  final String? recipientNickname;

  const SharedPetPreview({
    required this.petId,
    required this.petName,
    required this.recipientUserId,
    this.recipientNickname,
  });

  factory SharedPetPreview.fromJson(Map<String, dynamic> json) =>
      SharedPetPreview(
        petId: json['petId'] as int,
        petName: json['petName'] as String? ?? '이름 없음',
        recipientUserId: json['recipientUserId'] as int,
        recipientNickname: json['recipientNickname'] as String?,
      );
}

class UserProfile {
  final int id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final String userType;

  /// 프로필 색 팔레트 키. 사진이 없으면 아바타 배경, 있으면 테두리가 된다.
  final String profileColor;

  /// 남의 가계도에 내 닉네임을 노출할지. false면 서버가 '비공개'로 치환하고
  /// userId도 내리지 않아 남이 내 프로필로 들어올 수 없다
  final bool showNicknameInPedigree;

  /// 운영자 등급 (SUPER_ADMIN / MODERATOR). 일반 유저는 빈 목록.
  ///
  /// 개체 권한(OWNER/KEEPER)과 다른 축이다 — 이건 서비스 전체에 대한 권한이다.
  /// **화면을 켤지 정하는 용도로만 쓴다.** 실제 차단은 서버가 매 요청 DB로 다시 본다
  /// (이 값은 응답에 담겨 나온 뒤라 못 믿는다).
  final List<String> adminRoles;

  /// 만 14세 미만인가 (서버가 생년월일로 조회 시점에 계산한다).
  ///
  /// 어린이 게시판에서만 글·댓글을 남길 수 있는 계정이다. **화면 안내용일 뿐**
  /// 실제 차단은 서버(`KidsBoardPolicy`)가 매 요청 판정한다.
  final bool isChild;

  /// 커뮤니티를 쓸 수 있는가 (2026-11-10, Play 가족 정책). 성인은 항상 true,
  /// 자녀 계정은 보호자가 허용했을 때만. false 면 커뮤니티 탭이 안내 화면으로 바뀐다.
  /// 화면 안내용 — 실제 차단은 서버(`KidsBoardPolicy.assertCommunityAllowed`)가 한다.
  final bool communityAllowed;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.userType,
    this.profileColor = 'peach',
    this.showNicknameInPedigree = true,
    this.adminRoles = const [],
    this.isChild = false,
    this.communityAllowed = true,
  });

  /// 등급 종류를 가리지 않는 운영자 여부. 공지 작성 UI 노출 기준이다
  /// (서버 `verifyNoticePermission` 이 SUPER_ADMIN·MODERATOR 둘 다 허용한다).
  bool get isAdmin => adminRoles.isNotEmpty;

  /// 화면에 보여 줄 이메일. 소셜 제공자가 이메일을 안 주면 서버가
  /// `kakao_123@oauth.bitpet.local` 같은 **자리표시 주소**로 계정을 만든다 —
  /// 그대로 보이면 이상한 주소로 읽혀서 '카카오 계정' 처럼 바꿔 보여 준다 (2026-11-03).
  ///
  /// Apple '이메일 가리기'로 받은 중계 주소(`…@privaterelay.appleid.com`)도 같은 취급 —
  /// 사용자가 본 적 없는 무작위 주소다.
  String get displayEmail {
    if (email.endsWith('@privaterelay.appleid.com')) return 'Apple 계정';
    if (!email.endsWith('@oauth.bitpet.local')) return email;
    final provider = email.split('_').first.toLowerCase();
    return switch (provider) {
      'kakao' => '카카오 계정',
      'naver' => '네이버 계정',
      'google' => '구글 계정',
      'apple' => 'Apple 계정',
      _ => '소셜 계정',
    };
  }

  // 서버 UserResponse: id, email, nickname, userType, profileImageUrl,
  //                    showNicknameInPedigree, adminRoles, isChild, communityAllowed
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        email: json['email'] as String,
        name: (json['nickname'] ?? json['name']) as String, // 서버는 nickname
        profileImageUrl: json['profileImageUrl'] as String?,
        userType: json['userType'] as String? ?? 'GENERAL',
        profileColor: json['profileColor'] as String? ?? 'peach',
        showNicknameInPedigree:
            json['showNicknameInPedigree'] as bool? ?? true,
        adminRoles: ((json['adminRoles'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        isChild: json['isChild'] as bool? ?? false,
        communityAllowed: json['communityAllowed'] as bool? ?? true,
      );
}

/// 닉네임 중복확인 결과.
///
/// 서버가 `available` 과 함께 `reason`(불가 사유 문장)을 내려준다.
/// 길이·허용 문자·예약어·중복이 전부 여기로 들어오므로 앱은 규칙을 알 필요가 없다.
class NicknameCheckResult {
  final bool available;

  /// 사용 불가 사유. 사용 가능하면 null.
  final String? reason;

  const NicknameCheckResult({required this.available, this.reason});
}

/// 이메일 중복확인 결과. domainAllowed=false 면 '이미 가입됨'이 아니라 받지 않는 메일이다.
class EmailCheckResult {
  final bool available;
  final bool domainAllowed;

  const EmailCheckResult({required this.available, required this.domainAllowed});
}
