class Species {
  final int id;
  final String code;
  final String category;
  final String? subcategory;
  final String nameKo;
  final String? nameEn;

  const Species({
    required this.id,
    required this.code,
    required this.category,
    this.subcategory,
    required this.nameKo,
    this.nameEn,
  });

  factory Species.fromJson(Map<String, dynamic> json) => Species(
        id: json['id'] as int,
        code: json['code'] as String,
        category: json['category'] as String,
        subcategory: json['subcategory'] as String?,
        nameKo: json['nameKo'] as String,
        nameEn: json['nameEn'] as String?,
      );
}

// 모프 마스터 (morph_cd) — GET /species/{speciesId}/morphs
class Morph {
  final int id;
  final int speciesId;
  final String nameKo;
  final String? nameEn;
  final String? aliasList;        // 쉼표 구분 별칭
  final bool hasHealthConcern;    // 건강 우려 모프 여부 (예: Spider, Enigma)

  const Morph({
    required this.id,
    required this.speciesId,
    required this.nameKo,
    this.nameEn,
    this.aliasList,
    this.hasHealthConcern = false,
  });

  // 표시용 라벨: 영문명 우선, 없으면 한글명
  String get label => (nameEn != null && nameEn!.isNotEmpty) ? nameEn! : nameKo;

  factory Morph.fromJson(Map<String, dynamic> json) => Morph(
        id: (json['id'] as num).toInt(),
        speciesId: (json['speciesId'] as num?)?.toInt() ?? 0,
        nameKo: json['nameKo'] as String? ?? '',
        nameEn: json['nameEn'] as String?,
        aliasList: json['aliasList'] as String?,
        hasHealthConcern: json['hasHealthConcern'] as bool? ?? false,
      );
}

class Pet {
  final int id;
  final String serialNo;
  final int speciesId;
  final String speciesName;
  final String? morphName; // 모프명 (백엔드에서 제공 시, 단일 하위호환용)
  final List<Morph> morphs;
  final String name;
  final String gender;
  final String? colorCode;
  final String? description;
  final String? environmentMemo;
  final String? profileImageUrl;
  final int? profilePhotoId; // 대표 사진으로 지정된 갤러리 사진 id
  final DateTime? hatchingDate;
  final String hatchingDatePrecision;  // 'DAY' or 'MONTH'
  final bool hatchingDateApproximate;  // 날짜가 정확하지 않음
  final DateTime? adoptionDate;
  final double? latestWeightG;
  // 'Y' = 비공개(기본), 'N' = 공개(전체 검색 허용)
  final String privateYn;
  // 폐사일 (이별하기) — null이면 생존
  final DateTime? deceasedAt;
  // 부모 개체 (단건 조회 시 포함)
  final int? fatherRelationId;
  final int? fatherId;
  final String? fatherName;
  final int? motherRelationId;
  final int? motherId;
  final String? motherName;
  // 내가 이 개체의 소유자(OWNER)인가. 공유받은 개체(KEEPER)면 false.
  // 서버가 값을 안 실어주는 응답도 있어 기본은 true — 없으면 기존처럼 내 개체로 본다.
  final bool isOwner;

  Pet({
    required this.id,
    required this.serialNo,
    required this.speciesId,
    required this.speciesName,
    this.morphName,
    List<Morph>? morphs,
    required this.name,
    required this.gender,
    this.colorCode,
    this.description,
    this.environmentMemo,
    this.profileImageUrl,
    this.profilePhotoId,
    this.hatchingDate,
    this.hatchingDatePrecision = 'DAY',
    this.hatchingDateApproximate = false,
    this.adoptionDate,
    this.latestWeightG,
    this.privateYn = 'Y',
    this.deceasedAt,
    this.fatherRelationId,
    this.fatherId,
    this.fatherName,
    this.motherRelationId,
    this.motherId,
    this.motherName,
    this.isOwner = true,
  }) : morphs = morphs ?? const [];

  /// 공유받아 함께 키우는 개체 — 기록·프로필 수정·이별·가계도 편집은 되지만
  /// 삭제·분양·공유 관리(개체가 사라지거나 남에게 넘어가는 동작)는 소유자만
  bool get isSharedWithMe => !isOwner;

  bool get isPrivate => privateYn == 'Y';

  bool get isDeceased => deceasedAt != null;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: (json['id'] as num).toInt(),
        serialNo: json['serialNo'] as String? ?? '',
        speciesId: (json['speciesId'] as num?)?.toInt() ?? 0,
        speciesName: (json['speciesNameKo'] ?? json['speciesName']) as String? ?? '',
        morphName: json['morphName'] as String?,
        morphs: (() {
          try {
            final raw = json['morphs'];
            if (raw == null) return <Morph>[];
            return (raw as List<dynamic>)
                .map((e) => Morph.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {
            return <Morph>[];
          }
        })(),
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? 'UNKNOWN',
        colorCode: json['colorCode'] as String?,
        description: json['description'] as String?,
        environmentMemo: json['environmentMemo'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        profilePhotoId: (json['profilePhotoId'] as num?)?.toInt(),
        hatchingDate: json['hatchingDate'] != null
            ? DateTime.tryParse(json['hatchingDate'] as String)
            : null,
        hatchingDatePrecision: json['hatchingDatePrecision'] as String? ?? 'DAY',
        hatchingDateApproximate: json['hatchingDateApproximate'] as bool? ?? false,
        adoptionDate: json['adoptionDate'] != null
            ? DateTime.tryParse(json['adoptionDate'] as String)
            : null,
        latestWeightG: (json['latestWeightG'] as num?)?.toDouble(),
        privateYn: json['privateYn'] as String? ?? 'Y',
        deceasedAt: json['deceasedAt'] != null
            ? DateTime.tryParse(json['deceasedAt'] as String)
            : null,
        fatherRelationId: (json['fatherRelationId'] as num?)?.toInt(),
        fatherId: (json['fatherId'] as num?)?.toInt(),
        fatherName: json['fatherName'] as String?,
        motherRelationId: (json['motherRelationId'] as num?)?.toInt(),
        motherId: (json['motherId'] as num?)?.toInt(),
        motherName: json['motherName'] as String?,
        isOwner: json['isOwner'] as bool? ?? true,
      );
}

/// 개체 소유자 표시 정보 (가계도 카드 1줄).
///
/// [isMe] / [isOrphaned] 는 **서버가 판정해서 내려준다**. 앱에서 현재 로그인 유저와
/// 비교하지 말 것 — 같은 분기가 화면마다 흩어지고, 화면마다 다르게 틀린다.
class PetOwner {
  final int? userId;
  final String? nickname;
  final bool isMe;
  /// 소유자 없음 (탈퇴 익명화). 표시는 '정보 없음', 탭 불가
  final bool isOrphaned;

  const PetOwner({
    this.userId,
    this.nickname,
    this.isMe = false,
    this.isOrphaned = false,
  });

  factory PetOwner.fromJson(Map<String, dynamic> json) => PetOwner(
        userId: (json['userId'] as num?)?.toInt(),
        nickname: json['nickname'] as String?,
        isMe: json['isMe'] as bool? ?? false,
        isOrphaned: json['isOrphaned'] as bool? ?? false,
      );
}

/// 가계도 노드 / 남의 개체 공개 조회 카드.
///
/// 남의 개체가 섞이는 자리라 서버가 사육 기록(메모·체중·입양일)을 빼고 내려준다.
/// 여기 있는 필드가 남에게 보여도 되는 전부다.
class PetCard {
  final int? relationId;      // 가계도 노드일 때만
  final String? relationType; // FATHER / MOTHER
  final int petId;
  final String name;
  final String serialNo;
  final String gender;
  final int? speciesId;
  final String speciesName;
  final List<Morph> morphs;
  final DateTime? hatchingDate;
  final String hatchingDatePrecision;
  final bool hatchingDateApproximate;
  final DateTime? deceasedAt;
  final String? colorCode;
  final String? profileImageUrl;
  final String privateYn;
  /// 내가 사육하는 개체(OWNER/KEEPER)인지 → 전체 상세 `/pets/:id` 로 간다.
  /// false인데 [canOpenDetail]이 true면 남의 공개 개체이므로 공개 화면으로 보내야 한다.
  final bool isKeeper;
  /// 개체 상세로 들어갈 수 있는지 (내가 사육하는 개체이거나 공개 개체).
  /// false면 카드에 담긴 정보만으로 바텀시트를 띄운다.
  final bool canOpenDetail;
  final PetOwner owner;

  const PetCard({
    this.relationId,
    this.relationType,
    required this.petId,
    required this.name,
    this.serialNo = '',
    this.gender = 'UNKNOWN',
    this.speciesId,
    this.speciesName = '',
    this.morphs = const [],
    this.hatchingDate,
    this.hatchingDatePrecision = 'DAY',
    this.hatchingDateApproximate = false,
    this.deceasedAt,
    this.colorCode,
    this.profileImageUrl,
    this.privateYn = 'Y',
    this.isKeeper = false,
    this.canOpenDetail = false,
    this.owner = const PetOwner(),
  });

  bool get isPrivate => privateYn == 'Y';
  bool get isDeceased => deceasedAt != null;
  bool get isFather => relationType == 'FATHER';

  /// 내 개체([Pet])를 카드로 — 부모 선택 시트가 "내 목록"과 "일련번호로 찾은 남의 개체"를
  /// 같은 타입으로 다루기 위한 변환. 소유자는 당연히 나이므로 [PetOwner.isMe] = true.
  factory PetCard.fromPet(Pet pet) => PetCard(
        petId: pet.id,
        name: pet.name,
        serialNo: pet.serialNo,
        gender: pet.gender,
        speciesId: pet.speciesId,
        speciesName: pet.speciesName,
        morphs: pet.morphs,
        hatchingDate: pet.hatchingDate,
        hatchingDatePrecision: pet.hatchingDatePrecision,
        hatchingDateApproximate: pet.hatchingDateApproximate,
        deceasedAt: pet.deceasedAt,
        colorCode: pet.colorCode,
        profileImageUrl: pet.profileImageUrl,
        privateYn: pet.privateYn,
        isKeeper: true,
        canOpenDetail: true,
        owner: const PetOwner(isMe: true),
      );

  String get morphLabel => morphs.map((m) => m.label).join(' · ');

  factory PetCard.fromJson(Map<String, dynamic> json) => PetCard(
        relationId: (json['relationId'] as num?)?.toInt(),
        relationType: json['relationType'] as String?,
        petId: (json['petId'] as num).toInt(),
        name: json['name'] as String? ?? '',
        serialNo: json['serialNo'] as String? ?? '',
        gender: json['gender'] as String? ?? 'UNKNOWN',
        speciesId: (json['speciesId'] as num?)?.toInt(),
        speciesName: json['speciesNameKo'] as String? ?? '',
        morphs: (json['morphs'] as List<dynamic>? ?? [])
            .map((e) => Morph.fromJson(e as Map<String, dynamic>))
            .toList(),
        hatchingDate: json['hatchingDate'] != null
            ? DateTime.tryParse(json['hatchingDate'] as String)
            : null,
        hatchingDatePrecision: json['hatchingDatePrecision'] as String? ?? 'DAY',
        hatchingDateApproximate: json['hatchingDateApproximate'] as bool? ?? false,
        deceasedAt: json['deceasedAt'] != null
            ? DateTime.tryParse(json['deceasedAt'] as String)
            : null,
        colorCode: json['colorCode'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        privateYn: json['privateYn'] as String? ?? 'Y',
        isKeeper: json['isKeeper'] as bool? ?? false,
        canOpenDetail: json['canOpenDetail'] as bool? ?? false,
        owner: json['owner'] != null
            ? PetOwner.fromJson(json['owner'] as Map<String, dynamic>)
            : const PetOwner(),
      );
}

/// 가계도 — 가운데 개체 + 부모 + 자식
class Genealogy {
  final Pet pet;
  final List<PetCard> parents;
  final List<PetCard> children;

  const Genealogy({
    required this.pet,
    this.parents = const [],
    this.children = const [],
  });

  PetCard? get father => _parentOf('FATHER');
  PetCard? get mother => _parentOf('MOTHER');

  PetCard? _parentOf(String relationType) {
    for (final p in parents) {
      if (p.relationType == relationType) return p;
    }
    return null;
  }

  factory Genealogy.fromJson(Map<String, dynamic> json) => Genealogy(
        pet: Pet.fromJson(json['pet'] as Map<String, dynamic>),
        parents: (json['parents'] as List<dynamic>? ?? [])
            .map((e) => PetCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        children: (json['children'] as List<dynamic>? ?? [])
            .map((e) => PetCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 공개 프로필 — 가계도 카드의 '@닉네임' 탭
class UserProfile {
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final bool isMe;
  final List<PetCard> publicPets;

  const UserProfile({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    this.isMe = false,
    this.publicPets = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: (json['userId'] as num).toInt(),
        nickname: json['nickname'] as String? ?? '',
        profileImageUrl: json['profileImageUrl'] as String?,
        isMe: json['isMe'] as bool? ?? false,
        publicPets: (json['publicPets'] as List<dynamic>? ?? [])
            .map((e) => PetCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CreatePetRequest {
  final int speciesId;
  final String name;
  final String gender;
  final String? colorCode;
  final String? description;
  final String? environmentMemo;
  final List<int> morphIds;
  final String? hatchingDate;
  final String? hatchingDatePrecision;   // 'DAY' or 'MONTH'
  final bool hatchingDateApproximate;
  final String? adoptionDate;
  final double? currentWeightG; // 초기 몸무게 (g 기준)
  final int? fatherPetId;       // 부개체 연결
  final int? motherPetId;       // 모개체 연결
  final String privateYn;       // 'Y'=비공개(기본), 'N'=공개

  const CreatePetRequest({
    required this.speciesId,
    required this.name,
    required this.gender,
    this.colorCode,
    this.description,
    this.environmentMemo,
    this.morphIds = const [],
    this.hatchingDate,
    this.hatchingDatePrecision,
    this.hatchingDateApproximate = false,
    this.adoptionDate,
    this.currentWeightG,
    this.fatherPetId,
    this.motherPetId,
    this.privateYn = 'Y',
  });

  Map<String, dynamic> toJson() => {
        'speciesId': speciesId,
        'name': name,
        'gender': gender,
        if (colorCode != null) 'colorCode': colorCode,
        if (description != null) 'description': description,
        if (environmentMemo != null) 'environmentMemo': environmentMemo,
        if (morphIds.isNotEmpty) 'morphIds': morphIds,
        if (hatchingDate != null) 'hatchingDate': hatchingDate,
        if (hatchingDatePrecision != null) 'hatchingDatePrecision': hatchingDatePrecision,
        'hatchingDateApproximate': hatchingDateApproximate,
        if (adoptionDate != null) 'adoptionDate': adoptionDate,
        if (currentWeightG != null) 'currentWeightG': currentWeightG,
        if (fatherPetId != null) 'fatherPetId': fatherPetId,
        if (motherPetId != null) 'motherPetId': motherPetId,
        'privateYn': privateYn,
      };
}
