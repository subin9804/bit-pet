import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/upload/image_upload.dart';
import 'age_gate.dart';
import 'models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    uploader: ref.watch(imageUploadServiceProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final ImageUploadService _uploader;

  AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
    required ImageUploadService uploader,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _uploader = uploader;

  // ── 로그인 ────────────────────────────────────────────────
  // 서버 응답: { success, data: { accessToken, refreshToken, tokenType } }
  Future<UserProfile> login(LoginRequest request, {bool keepLoggedIn = true}) async {
    final res = await _dio.post('/auth/login', data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '로그인에 실패했습니다.');
    }
    final data = apiRes.data!;
    await _tokenStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      persist: keepLoggedIn,
    );
    return getMe();
  }


  // ── 소셜 로그인 ───────────────────────────────────────────
  // 서버가 제공자와 왕복을 끝낸 뒤 토큰이 아니라 1회용 교환 코드를
  // `tailog://oauth/callback?code=` 로 돌려준다. 커스텀 스킴은 다른 앱이 가로챌 수
  // 있어서, 코드만으로는 못 쓰고 처음에 해시만 보낸 verifier 원문이 있어야 토큰이 된다.

  /// 브라우저로 제공자 로그인을 띄우고 교환 코드를 받아 온다.
  /// 사용자가 창을 닫으면 null. 서버가 실패로 돌려보내면 [SocialLoginException].
  Future<SocialGrant?> authorizeSocial(String provider) async {
    final verifier = _randomUrlSafe(48);
    final challenge = _s256(verifier);
    final url = Uri.parse(_serverOrigin).replace(
      path: '/oauth2/authorization/$provider',
      queryParameters: {'app_challenge': challenge},
    );

    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: kOAuthCallbackScheme,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return null;
      rethrow;
    }

    final uri = Uri.parse(result);
    final code = uri.queryParameters['code'];
    if (uri.host == 'oauth' && uri.path == '/callback' && code != null && code.isNotEmpty) {
      return SocialGrant(code: code, verifier: verifier);
    }
    throw SocialLoginException(uri.queryParameters['error'] ?? 'unknown');
  }

  /// 교환 코드 + verifier → 토큰. 소셜 로그인은 '로그인 유지'를 묻지 않는다(늘 유지).
  /// [onLinked] — 이번 로그인으로 기존(이메일) 계정에 소셜이 **처음 연결됐을 때만** 불린다
  /// (서버 `linkedProvider`, 값은 KAKAO / NAVER / GOOGLE).
  Future<UserProfile> exchangeSocial(SocialGrant grant,
      {void Function(String provider)? onLinked}) async {
    final res = await _dio.post('/auth/oauth/exchange',
        data: {'code': grant.code, 'verifier': grant.verifier});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '로그인에 실패했습니다.');
    }
    final data = apiRes.data!;
    await _tokenStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      persist: true,
    );
    final linked = data['linkedProvider'] as String?;
    if (linked != null) onLinked?.call(linked);
    return getMe();
  }

  // ── Apple 로그인 (iOS) ─────────────────────────────────────
  // 브라우저 왕복이 아니라 OS 시트에서 끝난다. 받은 신원 토큰(JWT)을 서버가 Apple 공개키로
  // 검증한다. nonce 는 원문을 서버에, **해시를** Apple 에 준다 — 토큰 안의 nonce 가
  // 서버에 보낸 원문의 해시와 맞아야 하므로 남이 가로챈 토큰을 다시 쓸 수 없다.

  /// Apple 시트를 띄운다. 사용자가 닫으면 null.
  Future<AppleGrant?> authorizeApple() async {
    final nonce = _randomUrlSafe(32);
    final AuthorizationCredentialAppleID cred;
    try {
      cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw SocialLoginException(e.code.name);
    }
    final token = cred.identityToken;
    if (token == null) throw const SocialLoginException('missing_token');
    return AppleGrant(
      identityToken: token,
      nonce: nonce,
      authorizationCode: cred.authorizationCode,
      // 이름은 **처음 동의할 때 한 번만** 온다. 다음부터는 null
      givenName: cred.givenName,
      familyName: cred.familyName,
    );
  }

  /// 신원 토큰 → 우리 토큰. [onLinked] 는 [exchangeSocial] 과 같다 (값은 APPLE).
  Future<UserProfile> exchangeApple(AppleGrant grant,
      {void Function(String provider)? onLinked}) async {
    final res = await _dio.post('/auth/oauth/apple', data: grant.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '로그인에 실패했습니다.');
    }
    final data = apiRes.data!;
    await _tokenStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      persist: true,
    );
    final linked = data['linkedProvider'] as String?;
    if (linked != null) onLinked?.call(linked);
    return getMe();
  }

  /// `kBaseUrl` 에서 `/api/v1` 을 뗀 서버 주소. OAuth 시작점은 API 경로 밖에 있다.
  static String get _serverOrigin => Uri.parse(kBaseUrl).origin;

  static String _randomUrlSafe(int bytes) {
    final rnd = Random.secure();
    final data = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return base64UrlEncode(data).replaceAll('=', '');
  }

  static String _s256(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

  // ── 약관 동의 상태 ────────────────────────────────────────
  // 소셜 가입은 약관 화면 없이 계정이 생긴다. 서버는 그 자리에서 동의를 기록하지
  // 않으므로(본 적 없는 약관에 동의했다는 거짓 기록이 된다) 앱이 로그인 직후 물어본다.
  // 약관 개정 후 재동의도 같은 값으로 걸린다.
  //
  // ageUnchecked — 연령 확인(AGE_14)을 한 번도 안 한 계정(소셜로 막 가입). 이때만 생년월일을
  // 묻는다. 약관 개정 재동의는 이미 확인을 마친 계정이라 다시 묻지 않는다.
  Future<({bool needs, bool ageUnchecked})> needsAgreement() async {
    final res = await _dio.get('/auth/me/agreements');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    final items = (apiRes.data?['items'] as List?) ?? const [];
    final ageUnchecked = items.whereType<Map<String, dynamic>>().any(
        (i) => i['type'] == 'AGE_14' && i['agreed'] != true);
    return (
      needs: apiRes.data?['needsReagreement'] as bool? ?? false,
      ageUnchecked: ageUnchecked,
    );
  }

  /// [birthDate] 가 있으면 서버가 그걸로 연령을 판정한다. 없으면(재동의) 기존 확인을 잇는다.
  Future<void> acceptAgreements({
    required bool agreeMarketing,
    DateTime? birthDate,
  }) async {
    await _dio.post('/auth/me/agreements', data: {
      'agreeTos': true,
      'agreePrivacy': true,
      if (birthDate != null)
        'birthDate': AgeGate.format(birthDate)
      else
        'agreeAge': true,
      'agreeMarketing': agreeMarketing,
    });
  }

  // ── 내 정보 조회 (앱 재시작 시 프로필 복원) ──────────────
  Future<UserProfile> getMe() async {
    final res = await _dio.get('/auth/me');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '사용자 정보를 불러올 수 없습니다.');
    }
    return UserProfile.fromJson(apiRes.data!);
  }

  // ── 내 프로필 수정 (닉네임/프로필 이미지/공개 설정) ─────────
  // 부분 수정이라 null인 필드는 아예 보내지 않는다 (서버도 전달된 것만 반영)
  Future<UserProfile> updateMe({
    String? nickname,
    String? profileImageKey,
    String? profileColor,
    bool? showNicknameInPedigree,
  }) async {
    final res = await _dio.patch('/auth/me', data: {
      if (nickname != null) 'nickname': nickname,
      if (profileImageKey != null) 'profileImageKey': profileImageKey,
      if (profileColor != null) 'profileColor': profileColor,
      if (showNicknameInPedigree != null)
        'showNicknameInPedigree': showNicknameInPedigree,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '프로필 수정에 실패했습니다.');
    }
    return UserProfile.fromJson(apiRes.data!);
  }

  // ── 프로필 이미지 업로드 (presign → S3 PUT → PATCH /me) ────
  Future<UserProfile> uploadProfileImage(PickedImage image) async {
    final presignRes = await _dio.post('/auth/me/profile-image/presign',
        queryParameters: {'filename': image.filename});
    final presign = ApiResponse.fromJson(
      presignRes.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    ).data!;
    await _uploader.putToPresignedUrl(
        presign['presignedUrl'] as String, image.bytes, image.contentType);
    return updateMe(profileImageKey: presign['s3Key'] as String);
  }

  // ── 이메일 중복확인 ───────────────────────────────────────
  // domainAllowed=false 면 중복이 아니라 받지 않는 메일(자주 쓰는 도메인만 허용)이라 막힌 것이다.
  Future<EmailCheckResult> checkEmailAvailable(String email) async {
    final res = await _dio.get('/auth/check-email', queryParameters: {'email': email});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '이메일 확인에 실패했습니다.');
    }
    return EmailCheckResult(
      available: apiRes.data!['available'] as bool,
      // 이 필드가 없던 서버(배포 전)는 도메인 제한도 없었다
      domainAllowed: apiRes.data!['domainAllowed'] as bool? ?? true,
    );
  }

  // ── 가입 이메일 인증 ──────────────────────────────────────
  // 1) 코드 발송 → 2) 코드 확인 → 토큰. 토큰은 가입 요청(emailVerificationToken)에 싣는다.
  Future<void> sendSignupEmailCode(String email) async {
    final res = await _dio.post('/auth/signup/email-code', data: {'email': email});
    final apiRes = ApiResponse.fromJson(res.data as Map<String, dynamic>, (d) => d);
    if (!apiRes.success) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '인증 코드 발송에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
  }

  Future<String> verifySignupEmailCode(String email, String code) async {
    final res = await _dio.post('/auth/signup/email-code/verify',
        data: {'email': email, 'code': code});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '인증 코드 확인에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
    return apiRes.data!['verificationToken'] as String;
  }

  // ── 닉네임 중복확인 ───────────────────────────────────────
  // 형식 규칙(길이·허용 문자·예약어)까지 서버가 판정한다. 앱이 따로 규칙을 들고 있으면
  // 서버와 어긋나 "확인은 통과했는데 가입에서 거절" 이 난다.
  Future<NicknameCheckResult> checkNicknameAvailable(String nickname) async {
    final res = await _dio.get('/auth/check-nickname',
        queryParameters: {'nickname': nickname});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '닉네임 확인에 실패했습니다.');
    }
    return NicknameCheckResult(
      available: apiRes.data!['available'] as bool,
      reason: apiRes.data!['reason'] as String?,
    );
  }

  // ── 회원가입 ──────────────────────────────────────────────
  // 서버 흐름:
  //   1) POST /auth/signup → UserResponse (토큰 없음)
  //   2) POST /auth/login  → TokenResponse → 토큰 저장
  //   3) (사진을 골랐다면) presign → S3 PUT → PATCH /me
  //
  // 사진을 가입 요청에 실어 보내지 않는 이유: presign 은 인증이 필요한데 가입 시점에는
  // 아직 계정도 토큰도 없다. 그래서 앱이 바이트만 들고 있다가 로그인 직후에 올린다.
  //
  // ⚠️ 사진 업로드 실패가 가입을 되돌리지는 않는다. 계정은 이미 만들어졌고 로그인도 끝났으므로
  //    여기서 예외를 던지면 "가입은 됐는데 가입 실패로 보이는" 최악의 상태가 된다.
  //    사진은 마이페이지에서 다시 올릴 수 있다.
  Future<UserProfile> signup(SignupRequest request, {PickedImage? profileImage}) async {
    // 1. 회원가입
    final res = await _dio.post('/auth/signup', data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '회원가입에 실패했습니다.');
    }
    final userData = apiRes.data!;

    // 2. 자동 로그인 → 토큰 발급
    await login(LoginRequest(email: request.email, password: request.password));

    // 3. 프로필 사진 — 토큰이 생긴 지금부터 올릴 수 있다
    if (profileImage != null) {
      try {
        return await uploadProfileImage(profileImage);
      } catch (_) {
        // 위 주석 참고 — 가입 자체는 성공이다. 사진 없는 프로필로 진행한다
      }
    }

    // 4. 가입 응답(UserResponse)으로 프로필 반환
    return UserProfile.fromJson(userData);
  }

  // ── 비밀번호 재설정 ───────────────────────────────────────
  // 1단계: 인증 코드 발송 (미가입 이메일이어도 서버는 정상 응답)
  Future<void> requestPasswordReset(String email) async {
    final res = await _dio.post('/auth/password-reset/request',
        data: {'email': email});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '인증 코드 발송에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
  }

  // 2단계: 코드 인증 → 비밀번호 변경용 토큰 반환
  Future<String> verifyResetCode(String email, String code) async {
    final res = await _dio.post('/auth/password-reset/verify',
        data: {'email': email, 'code': code});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '인증 코드 확인에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
    return apiRes.data!['token'] as String;
  }

  // 3단계: 새 비밀번호 저장
  Future<void> confirmPasswordReset(String token, String newPassword) async {
    final res = await _dio.post('/auth/password-reset/confirm',
        data: {'token': token, 'newPassword': newPassword});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '비밀번호 변경에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
  }

  // ── 로그아웃 ──────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dio.delete('/auth/logout');
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  // ── 탈퇴 전 미리보기 (공동 사육자가 있는 개체) ──────────────
  Future<List<SharedPetPreview>> getWithdrawPreview() async {
    final res = await _dio.get('/auth/withdraw/preview');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    final list = (apiRes.data?['sharedPets'] as List?) ?? const [];
    return list
        .map((e) => SharedPetPreview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 회원탈퇴 ──────────────────────────────────────────────
  /// [handOverSharedPets] 공동 사육자가 있는 개체를 그 사람에게 넘길지.
  /// false면 다른 개체와 똑같이 삭제된다. 기본 true — 지운 건 되돌릴 수 없다
  Future<void> withdraw({bool handOverSharedPets = true}) async {
    await _dio.delete('/auth/withdraw',
        queryParameters: {'handOverSharedPets': handOverSharedPets});
    await _tokenStorage.clearTokens();
  }

  Future<bool> get isLoggedIn => _tokenStorage.hasToken;
}

/// 소셜 로그인이 돌아올 커스텀 스킴. AndroidManifest 의 CallbackActivity 와
/// 서버 `bitpet.oauth2.success/failure-redirect-uri` 가 이 값과 같아야 한다.
const String kOAuthCallbackScheme = 'tailog';

/// 브라우저 왕복에서 받은 교환 코드와, 처음에 해시만 보낸 verifier 원문.
class SocialGrant {
  final String code;
  final String verifier;
  const SocialGrant({required this.code, required this.verifier});
}

/// Apple 시트에서 받은 것. [nonce] 는 Apple 에 해시만 보낸 원문이다.
class AppleGrant {
  final String identityToken;
  final String nonce;
  final String? authorizationCode;
  final String? givenName;
  final String? familyName;
  const AppleGrant({
    required this.identityToken,
    required this.nonce,
    this.authorizationCode,
    this.givenName,
    this.familyName,
  });

  Map<String, dynamic> toJson() => {
        'identityToken': identityToken,
        'nonce': nonce,
        'authorizationCode': authorizationCode,
        'givenName': givenName,
        'familyName': familyName,
      };
}

/// 서버가 실패로 돌려보낸 경우. [reason] 은 `?error=` 값 그대로.
class SocialLoginException implements Exception {
  final String reason;
  const SocialLoginException(this.reason);
  @override
  String toString() => 'SocialLoginException($reason)';
}
