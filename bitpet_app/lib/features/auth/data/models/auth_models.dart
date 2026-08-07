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

  const SignupRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'nickname': nickname, // 서버 SignupRequest.nickname 과 일치
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

  /// 남의 가계도에 내 닉네임을 노출할지. false면 서버가 '비공개'로 치환하고
  /// userId도 내리지 않아 남이 내 프로필로 들어올 수 없다
  final bool showNicknameInPedigree;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.userType,
    this.showNicknameInPedigree = true,
  });

  // 서버 UserResponse: id, email, nickname, userType, profileImageUrl, showNicknameInPedigree
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        email: json['email'] as String,
        name: (json['nickname'] ?? json['name']) as String, // 서버는 nickname
        profileImageUrl: json['profileImageUrl'] as String?,
        userType: json['userType'] as String? ?? 'GENERAL',
        showNicknameInPedigree:
            json['showNicknameInPedigree'] as bool? ?? true,
      );
}
