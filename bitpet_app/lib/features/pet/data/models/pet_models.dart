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

class Pet {
  final int id;
  final String serialNo;
  final int speciesId;
  final String speciesName;
  final String? morphName; // 모프명 (백엔드에서 제공 시)
  final String name;
  final String gender;
  final String? colorCode;
  final String? description;
  final String? environmentMemo;
  final String? profileImageUrl;
  final DateTime? hatchingDate;
  final DateTime? adoptionDate;
  final double? latestWeightG;

  const Pet({
    required this.id,
    required this.serialNo,
    required this.speciesId,
    required this.speciesName,
    this.morphName,
    required this.name,
    required this.gender,
    this.colorCode,
    this.description,
    this.environmentMemo,
    this.profileImageUrl,
    this.hatchingDate,
    this.adoptionDate,
    this.latestWeightG,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'] as int,
        serialNo: json['serialNo'] as String,
        speciesId: json['speciesId'] as int,
        speciesName: json['speciesName'] as String? ?? '',
        morphName: json['morphName'] as String?,
        name: json['name'] as String,
        gender: json['gender'] as String? ?? 'UNKNOWN',
        colorCode: json['colorCode'] as String?,
        description: json['description'] as String?,
        environmentMemo: json['environmentMemo'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        hatchingDate: json['hatchingDate'] != null
            ? DateTime.tryParse(json['hatchingDate'] as String)
            : null,
        adoptionDate: json['adoptionDate'] != null
            ? DateTime.tryParse(json['adoptionDate'] as String)
            : null,
        latestWeightG: (json['latestWeightG'] as num?)?.toDouble(),
      );
}

class CreatePetRequest {
  final int speciesId;
  final String name;
  final String gender;
  final String? colorCode;
  final String? description;
  final String? environmentMemo;
  final int? morphId;
  final String? morphText;      // 직접 입력 모프
  final String? hatchingDate;
  final String? adoptionDate;
  final double? currentWeightG; // 초기 몸무게 (g 기준)
  final int? fatherPetId;       // 부개체 연결
  final int? motherPetId;       // 모개체 연결

  const CreatePetRequest({
    required this.speciesId,
    required this.name,
    required this.gender,
    this.colorCode,
    this.description,
    this.environmentMemo,
    this.morphId,
    this.morphText,
    this.hatchingDate,
    this.adoptionDate,
    this.currentWeightG,
    this.fatherPetId,
    this.motherPetId,
  });

  Map<String, dynamic> toJson() => {
        'speciesId': speciesId,
        'name': name,
        'gender': gender,
        if (colorCode != null) 'colorCode': colorCode,
        if (description != null) 'description': description,
        if (environmentMemo != null) 'environmentMemo': environmentMemo,
        if (morphId != null) 'morphId': morphId,
        if (morphText != null && morphId == null) 'morphText': morphText,
        if (hatchingDate != null) 'hatchingDate': hatchingDate,
        if (adoptionDate != null) 'adoptionDate': adoptionDate,
        if (currentWeightG != null) 'currentWeightG': currentWeightG,
        if (fatherPetId != null) 'fatherPetId': fatherPetId,
        if (motherPetId != null) 'motherPetId': motherPetId,
      };
}
