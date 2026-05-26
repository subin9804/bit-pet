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

class UserProfile {
  final int id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final String userType;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    required this.userType,
  });

  // 서버 UserResponse: id, email, nickname, userType, profileImageUrl
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        email: json['email'] as String,
        name: (json['nickname'] ?? json['name']) as String, // 서버는 nickname
        profileImageUrl: json['profileImageUrl'] as String?,
        userType: json['userType'] as String? ?? 'GENERAL',
      );
}
