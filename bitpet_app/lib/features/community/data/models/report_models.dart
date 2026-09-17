// 신고 / 차단 모델 — 서버(io.bitpet.community) 계약 기준
//
// 신고와 차단은 사용자에게 **따로 보이는 두 개의 선택지**다.
//   신고하기 → 운영자에게 접수 + 작성자 차단이 함께 생긴다
//   차단하기 → 차단만. 운영자에게 아무것도 올라가지 않는다
// 차단은 해제할 수 있지만 신고는 취소할 수 없다(이력이라 서버에 취소 API 가 없다).

/// 신고 대상. USER 는 글 하나가 아니라 그 사람의 활동 전반을 문제 삼는 신고.
enum ReportTargetType { post, comment, user }

extension ReportTargetTypeX on ReportTargetType {
  /// 서버 enum 이름 (POST / COMMENT / USER)
  String get code => name.toUpperCase();
}

/// 신고 사유 선택지. 라벨을 앱이 들고 있지 않고 서버에서 받는다 —
/// 사유가 늘거나 문구가 바뀔 때 스토어 심사를 기다리지 않아도 되게.
class ReportReason {
  final String code;
  final String label;

  const ReportReason({required this.code, required this.label});

  factory ReportReason.fromJson(Map<String, dynamic> json) => ReportReason(
        code: json['code'] as String,
        label: json['label'] as String,
      );
}

/// 차단 목록 한 줄. 해제 버튼을 달려면 userId 가 필요하다.
class BlockedUser {
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final DateTime blockedAt;

  const BlockedUser({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        userId: json['userId'] as int,
        nickname: json['nickname'] as String? ?? '알 수 없음',
        profileImageUrl: json['profileImageUrl'] as String?,
        blockedAt: DateTime.parse(json['blockedAt'] as String),
      );
}
