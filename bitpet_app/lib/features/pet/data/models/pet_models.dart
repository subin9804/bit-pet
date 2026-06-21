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
  final DateTime? hatchingDate;
  final String hatchingDatePrecision;  // 'DAY' or 'MONTH'
  final bool hatchingDateApproximate;  // 날짜가 정확하지 않음
  final DateTime? adoptionDate;
  final double? latestWeightG;
  // 'Y' = 비공개(기본), 'N' = 공개(전체 검색 허용)
  final String privateYn;

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
    this.hatchingDate,
    this.hatchingDatePrecision = 'DAY',
    this.hatchingDateApproximate = false,
    this.adoptionDate,
    this.latestWeightG,
    this.privateYn = 'Y',
  }) : morphs = morphs ?? const [];

  bool get isPrivate => privateYn == 'Y';

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
