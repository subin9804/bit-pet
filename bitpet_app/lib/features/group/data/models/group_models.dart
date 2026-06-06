// ── 사육 그룹 모델 ──────────────────────────────────────────────

class GroupInfo {
  final int id;
  final String name;
  final String inviteCode;
  final int ownerId;
  final GroupRole myRole;
  final List<GroupMember> members;

  const GroupInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.myRole,
    required this.members,
  });

  bool get isOwner => myRole == GroupRole.owner;

  factory GroupInfo.fromJson(Map<String, dynamic> json) => GroupInfo(
        id:         json['id'] as int,
        name:       json['name'] as String,
        inviteCode: json['inviteCode'] as String,
        ownerId:    json['ownerId'] as int,
        myRole:     GroupRole.fromString(json['myRole'] as String? ?? 'MEMBER'),
        members: (json['members'] as List<dynamic>? ?? [])
            .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GroupMember {
  final int userId;
  final String name;
  final GroupRole role;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  bool get isOwner => role == GroupRole.owner;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        userId:   json['userId'] as int,
        name:     json['name'] as String,
        role:     GroupRole.fromString(json['role'] as String? ?? 'MEMBER'),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );
}

enum GroupRole {
  owner,
  member;

  static GroupRole fromString(String v) =>
      v.toUpperCase() == 'OWNER' ? GroupRole.owner : GroupRole.member;

  String get label => this == GroupRole.owner ? '그룹장' : '멤버';
}
