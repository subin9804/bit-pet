// ── 개체 공유·입분양 모델 (pet_keeper_rls 기반) ─────────────────────────

/// 초대 유형
/// - share    : 사육자(KEEPER) 추가 — 공동 관리
/// - transfer : 입분양 — 소유권(OWNER) 이전, 기존 소유자는 KEEPER로 강등
enum ShareInviteType {
  share,
  transfer;

  String get serverValue => this == ShareInviteType.share ? 'SHARE' : 'TRANSFER';

  String get label => this == ShareInviteType.share ? '공유' : '입분양';

  static ShareInviteType fromString(String v) =>
      v.toUpperCase() == 'TRANSFER'
          ? ShareInviteType.transfer
          : ShareInviteType.share;
}

/// 초대 상태
enum ShareInviteStatus {
  pending,
  accepted,
  rejected,
  canceled,
  expired;

  String get label => switch (this) {
        ShareInviteStatus.pending => '대기중',
        ShareInviteStatus.accepted => '수락됨',
        ShareInviteStatus.rejected => '거절됨',
        ShareInviteStatus.canceled => '취소됨',
        ShareInviteStatus.expired => '만료됨',
      };

  static ShareInviteStatus fromString(String v) => switch (v.toUpperCase()) {
        'ACCEPTED' => ShareInviteStatus.accepted,
        'REJECTED' => ShareInviteStatus.rejected,
        'CANCELED' => ShareInviteStatus.canceled,
        'EXPIRED' => ShareInviteStatus.expired,
        _ => ShareInviteStatus.pending,
      };
}

/// 사육자 역할
enum KeeperRole {
  owner,
  keeper;

  bool get isOwner => this == KeeperRole.owner;

  String get label => this == KeeperRole.owner ? '소유자' : '사육자';

  static KeeperRole fromString(String v) =>
      v.toUpperCase() == 'OWNER' ? KeeperRole.owner : KeeperRole.keeper;
}

/// 공유·입분양 초대 (받은/보낸 함 공용)
class ShareInvitation {
  final int id;
  final int petId;
  final String petName;
  final int inviterUserId;
  final String inviterName;
  final int inviteeUserId;
  final String inviteeName;
  final ShareInviteType inviteType;
  final ShareInviteStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;

  const ShareInvitation({
    required this.id,
    required this.petId,
    required this.petName,
    required this.inviterUserId,
    required this.inviterName,
    required this.inviteeUserId,
    required this.inviteeName,
    required this.inviteType,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.respondedAt,
  });

  factory ShareInvitation.fromJson(Map<String, dynamic> json) => ShareInvitation(
        id: json['id'] as int,
        petId: json['petId'] as int,
        petName: json['petName'] as String? ?? '',
        inviterUserId: json['inviterUserId'] as int,
        inviterName: json['inviterName'] as String? ?? '',
        inviteeUserId: json['inviteeUserId'] as int,
        inviteeName: json['inviteeName'] as String? ?? '',
        inviteType: ShareInviteType.fromString(json['inviteType'] as String? ?? 'SHARE'),
        status: ShareInviteStatus.fromString(json['status'] as String? ?? 'PENDING'),
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'] as String)
            : null,
      );
}

/// 배치(벌크) 초대에 포함된 개체 1건
class BatchPetItem {
  final int invitationId;
  final int petId;
  final String petName;
  final ShareInviteStatus status;

  const BatchPetItem({
    required this.invitationId,
    required this.petId,
    required this.petName,
    required this.status,
  });

  factory BatchPetItem.fromJson(Map<String, dynamic> json) => BatchPetItem(
        invitationId: json['invitationId'] as int,
        petId: json['petId'] as int,
        petName: json['petName'] as String? ?? '',
        status: ShareInviteStatus.fromString(json['status'] as String? ?? 'PENDING'),
      );
}

/// 배치(여러 개체를 한 번에) 초대 — 받은 초대함/벌크 결과 공용
class ShareInvitationBatch {
  final String batchId;
  final int inviterUserId;
  final String inviterName;
  final int inviteeUserId;
  final String inviteeName;
  final ShareInviteType inviteType;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<BatchPetItem> pets;

  const ShareInvitationBatch({
    required this.batchId,
    required this.inviterUserId,
    required this.inviterName,
    required this.inviteeUserId,
    required this.inviteeName,
    required this.inviteType,
    required this.createdAt,
    this.expiresAt,
    required this.pets,
  });

  int get petCount => pets.length;

  factory ShareInvitationBatch.fromJson(Map<String, dynamic> json) =>
      ShareInvitationBatch(
        batchId: json['batchId'] as String,
        inviterUserId: json['inviterUserId'] as int,
        inviterName: json['inviterName'] as String? ?? '',
        inviteeUserId: json['inviteeUserId'] as int,
        inviteeName: json['inviteeName'] as String? ?? '',
        inviteType:
            ShareInviteType.fromString(json['inviteType'] as String? ?? 'SHARE'),
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        pets: (json['pets'] as List? ?? [])
            .map((e) => BatchPetItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 개체 사육자(공유 멤버)
class Keeper {
  final int userId;
  final String name;
  final String? profileImageUrl;
  final KeeperRole role;
  final DateTime? joinedAt;

  const Keeper({
    required this.userId,
    required this.name,
    this.profileImageUrl,
    required this.role,
    this.joinedAt,
  });

  factory Keeper.fromJson(Map<String, dynamic> json) => Keeper(
        userId: json['userId'] as int,
        name: json['name'] as String? ?? '',
        profileImageUrl: json['profileImageUrl'] as String?,
        role: KeeperRole.fromString(json['role'] as String? ?? 'KEEPER'),
        joinedAt: json['joinedAt'] != null
            ? DateTime.parse(json['joinedAt'] as String)
            : null,
      );
}
