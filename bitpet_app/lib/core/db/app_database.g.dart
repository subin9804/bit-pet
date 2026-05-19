// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PetTableTable extends PetTable
    with TableInfo<$PetTableTable, PetTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PetTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serialNoMeta = const VerificationMeta(
    'serialNo',
  );
  @override
  late final GeneratedColumn<String> serialNo = GeneratedColumn<String>(
    'serial_no',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 8,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speciesIdMeta = const VerificationMeta(
    'speciesId',
  );
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
    'species_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UNKNOWN'),
  );
  static const VerificationMeta _morphIdMeta = const VerificationMeta(
    'morphId',
  );
  @override
  late final GeneratedColumn<int> morphId = GeneratedColumn<int>(
    'morph_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorCodeMeta = const VerificationMeta(
    'colorCode',
  );
  @override
  late final GeneratedColumn<String> colorCode = GeneratedColumn<String>(
    'color_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _environmentMemoMeta = const VerificationMeta(
    'environmentMemo',
  );
  @override
  late final GeneratedColumn<String> environmentMemo = GeneratedColumn<String>(
    'environment_memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _breedingDateMeta = const VerificationMeta(
    'breedingDate',
  );
  @override
  late final GeneratedColumn<DateTime> breedingDate = GeneratedColumn<DateTime>(
    'breeding_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hatchingDateMeta = const VerificationMeta(
    'hatchingDate',
  );
  @override
  late final GeneratedColumn<DateTime> hatchingDate = GeneratedColumn<DateTime>(
    'hatching_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adoptionDateMeta = const VerificationMeta(
    'adoptionDate',
  );
  @override
  late final GeneratedColumn<DateTime> adoptionDate = GeneratedColumn<DateTime>(
    'adoption_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profilePhotoIdMeta = const VerificationMeta(
    'profilePhotoId',
  );
  @override
  late final GeneratedColumn<int> profilePhotoId = GeneratedColumn<int>(
    'profile_photo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientChangeIdMeta = const VerificationMeta(
    'clientChangeId',
  );
  @override
  late final GeneratedColumn<String> clientChangeId = GeneratedColumn<String>(
    'client_change_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serialNo,
    userId,
    speciesId,
    name,
    gender,
    morphId,
    description,
    colorCode,
    environmentMemo,
    breedingDate,
    hatchingDate,
    adoptionDate,
    profilePhotoId,
    deletedAt,
    syncVersion,
    clientId,
    clientChangeId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pet_mst';
  @override
  VerificationContext validateIntegrity(
    Insertable<PetTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('serial_no')) {
      context.handle(
        _serialNoMeta,
        serialNo.isAcceptableOrUnknown(data['serial_no']!, _serialNoMeta),
      );
    } else if (isInserting) {
      context.missing(_serialNoMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('species_id')) {
      context.handle(
        _speciesIdMeta,
        speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('morph_id')) {
      context.handle(
        _morphIdMeta,
        morphId.isAcceptableOrUnknown(data['morph_id']!, _morphIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color_code')) {
      context.handle(
        _colorCodeMeta,
        colorCode.isAcceptableOrUnknown(data['color_code']!, _colorCodeMeta),
      );
    }
    if (data.containsKey('environment_memo')) {
      context.handle(
        _environmentMemoMeta,
        environmentMemo.isAcceptableOrUnknown(
          data['environment_memo']!,
          _environmentMemoMeta,
        ),
      );
    }
    if (data.containsKey('breeding_date')) {
      context.handle(
        _breedingDateMeta,
        breedingDate.isAcceptableOrUnknown(
          data['breeding_date']!,
          _breedingDateMeta,
        ),
      );
    }
    if (data.containsKey('hatching_date')) {
      context.handle(
        _hatchingDateMeta,
        hatchingDate.isAcceptableOrUnknown(
          data['hatching_date']!,
          _hatchingDateMeta,
        ),
      );
    }
    if (data.containsKey('adoption_date')) {
      context.handle(
        _adoptionDateMeta,
        adoptionDate.isAcceptableOrUnknown(
          data['adoption_date']!,
          _adoptionDateMeta,
        ),
      );
    }
    if (data.containsKey('profile_photo_id')) {
      context.handle(
        _profilePhotoIdMeta,
        profilePhotoId.isAcceptableOrUnknown(
          data['profile_photo_id']!,
          _profilePhotoIdMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('client_change_id')) {
      context.handle(
        _clientChangeIdMeta,
        clientChangeId.isAcceptableOrUnknown(
          data['client_change_id']!,
          _clientChangeIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PetTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PetTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serialNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_no'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      speciesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}species_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      morphId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}morph_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      colorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_code'],
      ),
      environmentMemo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_memo'],
      ),
      breedingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}breeding_date'],
      ),
      hatchingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hatching_date'],
      ),
      adoptionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}adoption_date'],
      ),
      profilePhotoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_photo_id'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      clientChangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_change_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PetTableTable createAlias(String alias) {
    return $PetTableTable(attachedDatabase, alias);
  }
}

class PetTableData extends DataClass implements Insertable<PetTableData> {
  final int id;
  final String serialNo;
  final int userId;
  final int speciesId;
  final String name;
  final String gender;
  final int? morphId;
  final String? description;
  final String? colorCode;
  final String? environmentMemo;
  final DateTime? breedingDate;
  final DateTime? hatchingDate;
  final DateTime? adoptionDate;
  final int? profilePhotoId;
  final DateTime? deletedAt;
  final int syncVersion;
  final String? clientId;
  final String? clientChangeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PetTableData({
    required this.id,
    required this.serialNo,
    required this.userId,
    required this.speciesId,
    required this.name,
    required this.gender,
    this.morphId,
    this.description,
    this.colorCode,
    this.environmentMemo,
    this.breedingDate,
    this.hatchingDate,
    this.adoptionDate,
    this.profilePhotoId,
    this.deletedAt,
    required this.syncVersion,
    this.clientId,
    this.clientChangeId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['serial_no'] = Variable<String>(serialNo);
    map['user_id'] = Variable<int>(userId);
    map['species_id'] = Variable<int>(speciesId);
    map['name'] = Variable<String>(name);
    map['gender'] = Variable<String>(gender);
    if (!nullToAbsent || morphId != null) {
      map['morph_id'] = Variable<int>(morphId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || colorCode != null) {
      map['color_code'] = Variable<String>(colorCode);
    }
    if (!nullToAbsent || environmentMemo != null) {
      map['environment_memo'] = Variable<String>(environmentMemo);
    }
    if (!nullToAbsent || breedingDate != null) {
      map['breeding_date'] = Variable<DateTime>(breedingDate);
    }
    if (!nullToAbsent || hatchingDate != null) {
      map['hatching_date'] = Variable<DateTime>(hatchingDate);
    }
    if (!nullToAbsent || adoptionDate != null) {
      map['adoption_date'] = Variable<DateTime>(adoptionDate);
    }
    if (!nullToAbsent || profilePhotoId != null) {
      map['profile_photo_id'] = Variable<int>(profilePhotoId);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || clientChangeId != null) {
      map['client_change_id'] = Variable<String>(clientChangeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PetTableCompanion toCompanion(bool nullToAbsent) {
    return PetTableCompanion(
      id: Value(id),
      serialNo: Value(serialNo),
      userId: Value(userId),
      speciesId: Value(speciesId),
      name: Value(name),
      gender: Value(gender),
      morphId: morphId == null && nullToAbsent
          ? const Value.absent()
          : Value(morphId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      colorCode: colorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(colorCode),
      environmentMemo: environmentMemo == null && nullToAbsent
          ? const Value.absent()
          : Value(environmentMemo),
      breedingDate: breedingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(breedingDate),
      hatchingDate: hatchingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(hatchingDate),
      adoptionDate: adoptionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(adoptionDate),
      profilePhotoId: profilePhotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePhotoId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncVersion: Value(syncVersion),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      clientChangeId: clientChangeId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientChangeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PetTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PetTableData(
      id: serializer.fromJson<int>(json['id']),
      serialNo: serializer.fromJson<String>(json['serialNo']),
      userId: serializer.fromJson<int>(json['userId']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      name: serializer.fromJson<String>(json['name']),
      gender: serializer.fromJson<String>(json['gender']),
      morphId: serializer.fromJson<int?>(json['morphId']),
      description: serializer.fromJson<String?>(json['description']),
      colorCode: serializer.fromJson<String?>(json['colorCode']),
      environmentMemo: serializer.fromJson<String?>(json['environmentMemo']),
      breedingDate: serializer.fromJson<DateTime?>(json['breedingDate']),
      hatchingDate: serializer.fromJson<DateTime?>(json['hatchingDate']),
      adoptionDate: serializer.fromJson<DateTime?>(json['adoptionDate']),
      profilePhotoId: serializer.fromJson<int?>(json['profilePhotoId']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      clientChangeId: serializer.fromJson<String?>(json['clientChangeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serialNo': serializer.toJson<String>(serialNo),
      'userId': serializer.toJson<int>(userId),
      'speciesId': serializer.toJson<int>(speciesId),
      'name': serializer.toJson<String>(name),
      'gender': serializer.toJson<String>(gender),
      'morphId': serializer.toJson<int?>(morphId),
      'description': serializer.toJson<String?>(description),
      'colorCode': serializer.toJson<String?>(colorCode),
      'environmentMemo': serializer.toJson<String?>(environmentMemo),
      'breedingDate': serializer.toJson<DateTime?>(breedingDate),
      'hatchingDate': serializer.toJson<DateTime?>(hatchingDate),
      'adoptionDate': serializer.toJson<DateTime?>(adoptionDate),
      'profilePhotoId': serializer.toJson<int?>(profilePhotoId),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'clientId': serializer.toJson<String?>(clientId),
      'clientChangeId': serializer.toJson<String?>(clientChangeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PetTableData copyWith({
    int? id,
    String? serialNo,
    int? userId,
    int? speciesId,
    String? name,
    String? gender,
    Value<int?> morphId = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> colorCode = const Value.absent(),
    Value<String?> environmentMemo = const Value.absent(),
    Value<DateTime?> breedingDate = const Value.absent(),
    Value<DateTime?> hatchingDate = const Value.absent(),
    Value<DateTime?> adoptionDate = const Value.absent(),
    Value<int?> profilePhotoId = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncVersion,
    Value<String?> clientId = const Value.absent(),
    Value<String?> clientChangeId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PetTableData(
    id: id ?? this.id,
    serialNo: serialNo ?? this.serialNo,
    userId: userId ?? this.userId,
    speciesId: speciesId ?? this.speciesId,
    name: name ?? this.name,
    gender: gender ?? this.gender,
    morphId: morphId.present ? morphId.value : this.morphId,
    description: description.present ? description.value : this.description,
    colorCode: colorCode.present ? colorCode.value : this.colorCode,
    environmentMemo: environmentMemo.present
        ? environmentMemo.value
        : this.environmentMemo,
    breedingDate: breedingDate.present ? breedingDate.value : this.breedingDate,
    hatchingDate: hatchingDate.present ? hatchingDate.value : this.hatchingDate,
    adoptionDate: adoptionDate.present ? adoptionDate.value : this.adoptionDate,
    profilePhotoId: profilePhotoId.present
        ? profilePhotoId.value
        : this.profilePhotoId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncVersion: syncVersion ?? this.syncVersion,
    clientId: clientId.present ? clientId.value : this.clientId,
    clientChangeId: clientChangeId.present
        ? clientChangeId.value
        : this.clientChangeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PetTableData copyWithCompanion(PetTableCompanion data) {
    return PetTableData(
      id: data.id.present ? data.id.value : this.id,
      serialNo: data.serialNo.present ? data.serialNo.value : this.serialNo,
      userId: data.userId.present ? data.userId.value : this.userId,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      name: data.name.present ? data.name.value : this.name,
      gender: data.gender.present ? data.gender.value : this.gender,
      morphId: data.morphId.present ? data.morphId.value : this.morphId,
      description: data.description.present
          ? data.description.value
          : this.description,
      colorCode: data.colorCode.present ? data.colorCode.value : this.colorCode,
      environmentMemo: data.environmentMemo.present
          ? data.environmentMemo.value
          : this.environmentMemo,
      breedingDate: data.breedingDate.present
          ? data.breedingDate.value
          : this.breedingDate,
      hatchingDate: data.hatchingDate.present
          ? data.hatchingDate.value
          : this.hatchingDate,
      adoptionDate: data.adoptionDate.present
          ? data.adoptionDate.value
          : this.adoptionDate,
      profilePhotoId: data.profilePhotoId.present
          ? data.profilePhotoId.value
          : this.profilePhotoId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientChangeId: data.clientChangeId.present
          ? data.clientChangeId.value
          : this.clientChangeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PetTableData(')
          ..write('id: $id, ')
          ..write('serialNo: $serialNo, ')
          ..write('userId: $userId, ')
          ..write('speciesId: $speciesId, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('morphId: $morphId, ')
          ..write('description: $description, ')
          ..write('colorCode: $colorCode, ')
          ..write('environmentMemo: $environmentMemo, ')
          ..write('breedingDate: $breedingDate, ')
          ..write('hatchingDate: $hatchingDate, ')
          ..write('adoptionDate: $adoptionDate, ')
          ..write('profilePhotoId: $profilePhotoId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('clientId: $clientId, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serialNo,
    userId,
    speciesId,
    name,
    gender,
    morphId,
    description,
    colorCode,
    environmentMemo,
    breedingDate,
    hatchingDate,
    adoptionDate,
    profilePhotoId,
    deletedAt,
    syncVersion,
    clientId,
    clientChangeId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetTableData &&
          other.id == this.id &&
          other.serialNo == this.serialNo &&
          other.userId == this.userId &&
          other.speciesId == this.speciesId &&
          other.name == this.name &&
          other.gender == this.gender &&
          other.morphId == this.morphId &&
          other.description == this.description &&
          other.colorCode == this.colorCode &&
          other.environmentMemo == this.environmentMemo &&
          other.breedingDate == this.breedingDate &&
          other.hatchingDate == this.hatchingDate &&
          other.adoptionDate == this.adoptionDate &&
          other.profilePhotoId == this.profilePhotoId &&
          other.deletedAt == this.deletedAt &&
          other.syncVersion == this.syncVersion &&
          other.clientId == this.clientId &&
          other.clientChangeId == this.clientChangeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PetTableCompanion extends UpdateCompanion<PetTableData> {
  final Value<int> id;
  final Value<String> serialNo;
  final Value<int> userId;
  final Value<int> speciesId;
  final Value<String> name;
  final Value<String> gender;
  final Value<int?> morphId;
  final Value<String?> description;
  final Value<String?> colorCode;
  final Value<String?> environmentMemo;
  final Value<DateTime?> breedingDate;
  final Value<DateTime?> hatchingDate;
  final Value<DateTime?> adoptionDate;
  final Value<int?> profilePhotoId;
  final Value<DateTime?> deletedAt;
  final Value<int> syncVersion;
  final Value<String?> clientId;
  final Value<String?> clientChangeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PetTableCompanion({
    this.id = const Value.absent(),
    this.serialNo = const Value.absent(),
    this.userId = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.morphId = const Value.absent(),
    this.description = const Value.absent(),
    this.colorCode = const Value.absent(),
    this.environmentMemo = const Value.absent(),
    this.breedingDate = const Value.absent(),
    this.hatchingDate = const Value.absent(),
    this.adoptionDate = const Value.absent(),
    this.profilePhotoId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientChangeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PetTableCompanion.insert({
    this.id = const Value.absent(),
    required String serialNo,
    required int userId,
    required int speciesId,
    required String name,
    this.gender = const Value.absent(),
    this.morphId = const Value.absent(),
    this.description = const Value.absent(),
    this.colorCode = const Value.absent(),
    this.environmentMemo = const Value.absent(),
    this.breedingDate = const Value.absent(),
    this.hatchingDate = const Value.absent(),
    this.adoptionDate = const Value.absent(),
    this.profilePhotoId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientChangeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : serialNo = Value(serialNo),
       userId = Value(userId),
       speciesId = Value(speciesId),
       name = Value(name);
  static Insertable<PetTableData> custom({
    Expression<int>? id,
    Expression<String>? serialNo,
    Expression<int>? userId,
    Expression<int>? speciesId,
    Expression<String>? name,
    Expression<String>? gender,
    Expression<int>? morphId,
    Expression<String>? description,
    Expression<String>? colorCode,
    Expression<String>? environmentMemo,
    Expression<DateTime>? breedingDate,
    Expression<DateTime>? hatchingDate,
    Expression<DateTime>? adoptionDate,
    Expression<int>? profilePhotoId,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncVersion,
    Expression<String>? clientId,
    Expression<String>? clientChangeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serialNo != null) 'serial_no': serialNo,
      if (userId != null) 'user_id': userId,
      if (speciesId != null) 'species_id': speciesId,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (morphId != null) 'morph_id': morphId,
      if (description != null) 'description': description,
      if (colorCode != null) 'color_code': colorCode,
      if (environmentMemo != null) 'environment_memo': environmentMemo,
      if (breedingDate != null) 'breeding_date': breedingDate,
      if (hatchingDate != null) 'hatching_date': hatchingDate,
      if (adoptionDate != null) 'adoption_date': adoptionDate,
      if (profilePhotoId != null) 'profile_photo_id': profilePhotoId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (clientId != null) 'client_id': clientId,
      if (clientChangeId != null) 'client_change_id': clientChangeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PetTableCompanion copyWith({
    Value<int>? id,
    Value<String>? serialNo,
    Value<int>? userId,
    Value<int>? speciesId,
    Value<String>? name,
    Value<String>? gender,
    Value<int?>? morphId,
    Value<String?>? description,
    Value<String?>? colorCode,
    Value<String?>? environmentMemo,
    Value<DateTime?>? breedingDate,
    Value<DateTime?>? hatchingDate,
    Value<DateTime?>? adoptionDate,
    Value<int?>? profilePhotoId,
    Value<DateTime?>? deletedAt,
    Value<int>? syncVersion,
    Value<String?>? clientId,
    Value<String?>? clientChangeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PetTableCompanion(
      id: id ?? this.id,
      serialNo: serialNo ?? this.serialNo,
      userId: userId ?? this.userId,
      speciesId: speciesId ?? this.speciesId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      morphId: morphId ?? this.morphId,
      description: description ?? this.description,
      colorCode: colorCode ?? this.colorCode,
      environmentMemo: environmentMemo ?? this.environmentMemo,
      breedingDate: breedingDate ?? this.breedingDate,
      hatchingDate: hatchingDate ?? this.hatchingDate,
      adoptionDate: adoptionDate ?? this.adoptionDate,
      profilePhotoId: profilePhotoId ?? this.profilePhotoId,
      deletedAt: deletedAt ?? this.deletedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      clientId: clientId ?? this.clientId,
      clientChangeId: clientChangeId ?? this.clientChangeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serialNo.present) {
      map['serial_no'] = Variable<String>(serialNo.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (morphId.present) {
      map['morph_id'] = Variable<int>(morphId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (colorCode.present) {
      map['color_code'] = Variable<String>(colorCode.value);
    }
    if (environmentMemo.present) {
      map['environment_memo'] = Variable<String>(environmentMemo.value);
    }
    if (breedingDate.present) {
      map['breeding_date'] = Variable<DateTime>(breedingDate.value);
    }
    if (hatchingDate.present) {
      map['hatching_date'] = Variable<DateTime>(hatchingDate.value);
    }
    if (adoptionDate.present) {
      map['adoption_date'] = Variable<DateTime>(adoptionDate.value);
    }
    if (profilePhotoId.present) {
      map['profile_photo_id'] = Variable<int>(profilePhotoId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientChangeId.present) {
      map['client_change_id'] = Variable<String>(clientChangeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PetTableCompanion(')
          ..write('id: $id, ')
          ..write('serialNo: $serialNo, ')
          ..write('userId: $userId, ')
          ..write('speciesId: $speciesId, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('morphId: $morphId, ')
          ..write('description: $description, ')
          ..write('colorCode: $colorCode, ')
          ..write('environmentMemo: $environmentMemo, ')
          ..write('breedingDate: $breedingDate, ')
          ..write('hatchingDate: $hatchingDate, ')
          ..write('adoptionDate: $adoptionDate, ')
          ..write('profilePhotoId: $profilePhotoId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('clientId: $clientId, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WeightTableTable extends WeightTable
    with TableInfo<$WeightTableTable, WeightTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<int> petId = GeneratedColumn<int>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pet_mst (id)',
    ),
  );
  static const VerificationMeta _weightGMeta = const VerificationMeta(
    'weightG',
  );
  @override
  late final GeneratedColumn<double> weightG = GeneratedColumn<double>(
    'weight_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MANUAL'),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientChangeIdMeta = const VerificationMeta(
    'clientChangeId',
  );
  @override
  late final GeneratedColumn<String> clientChangeId = GeneratedColumn<String>(
    'client_change_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petId,
    weightG,
    measuredAt,
    source,
    memo,
    deletedAt,
    syncVersion,
    clientId,
    clientChangeId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_dtl';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('weight_g')) {
      context.handle(
        _weightGMeta,
        weightG.isAcceptableOrUnknown(data['weight_g']!, _weightGMeta),
      );
    } else if (isInserting) {
      context.missing(_weightGMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('client_change_id')) {
      context.handle(
        _clientChangeIdMeta,
        clientChangeId.isAcceptableOrUnknown(
          data['client_change_id']!,
          _clientChangeIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_id'],
      )!,
      weightG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_g'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      clientChangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_change_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WeightTableTable createAlias(String alias) {
    return $WeightTableTable(attachedDatabase, alias);
  }
}

class WeightTableData extends DataClass implements Insertable<WeightTableData> {
  final int id;
  final int petId;
  final double weightG;
  final DateTime measuredAt;
  final String source;
  final String? memo;
  final DateTime? deletedAt;
  final int syncVersion;
  final String? clientId;
  final String? clientChangeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WeightTableData({
    required this.id,
    required this.petId,
    required this.weightG,
    required this.measuredAt,
    required this.source,
    this.memo,
    this.deletedAt,
    required this.syncVersion,
    this.clientId,
    this.clientChangeId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<int>(petId);
    map['weight_g'] = Variable<double>(weightG);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || clientChangeId != null) {
      map['client_change_id'] = Variable<String>(clientChangeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WeightTableCompanion toCompanion(bool nullToAbsent) {
    return WeightTableCompanion(
      id: Value(id),
      petId: Value(petId),
      weightG: Value(weightG),
      measuredAt: Value(measuredAt),
      source: Value(source),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncVersion: Value(syncVersion),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      clientChangeId: clientChangeId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientChangeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeightTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightTableData(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<int>(json['petId']),
      weightG: serializer.fromJson<double>(json['weightG']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      source: serializer.fromJson<String>(json['source']),
      memo: serializer.fromJson<String?>(json['memo']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      clientChangeId: serializer.fromJson<String?>(json['clientChangeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<int>(petId),
      'weightG': serializer.toJson<double>(weightG),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'source': serializer.toJson<String>(source),
      'memo': serializer.toJson<String?>(memo),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'clientId': serializer.toJson<String?>(clientId),
      'clientChangeId': serializer.toJson<String?>(clientChangeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WeightTableData copyWith({
    int? id,
    int? petId,
    double? weightG,
    DateTime? measuredAt,
    String? source,
    Value<String?> memo = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncVersion,
    Value<String?> clientId = const Value.absent(),
    Value<String?> clientChangeId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WeightTableData(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    weightG: weightG ?? this.weightG,
    measuredAt: measuredAt ?? this.measuredAt,
    source: source ?? this.source,
    memo: memo.present ? memo.value : this.memo,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncVersion: syncVersion ?? this.syncVersion,
    clientId: clientId.present ? clientId.value : this.clientId,
    clientChangeId: clientChangeId.present
        ? clientChangeId.value
        : this.clientChangeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WeightTableData copyWithCompanion(WeightTableCompanion data) {
    return WeightTableData(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      weightG: data.weightG.present ? data.weightG.value : this.weightG,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      source: data.source.present ? data.source.value : this.source,
      memo: data.memo.present ? data.memo.value : this.memo,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientChangeId: data.clientChangeId.present
          ? data.clientChangeId.value
          : this.clientChangeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightTableData(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('weightG: $weightG, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('source: $source, ')
          ..write('memo: $memo, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('clientId: $clientId, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    weightG,
    measuredAt,
    source,
    memo,
    deletedAt,
    syncVersion,
    clientId,
    clientChangeId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightTableData &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.weightG == this.weightG &&
          other.measuredAt == this.measuredAt &&
          other.source == this.source &&
          other.memo == this.memo &&
          other.deletedAt == this.deletedAt &&
          other.syncVersion == this.syncVersion &&
          other.clientId == this.clientId &&
          other.clientChangeId == this.clientChangeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WeightTableCompanion extends UpdateCompanion<WeightTableData> {
  final Value<int> id;
  final Value<int> petId;
  final Value<double> weightG;
  final Value<DateTime> measuredAt;
  final Value<String> source;
  final Value<String?> memo;
  final Value<DateTime?> deletedAt;
  final Value<int> syncVersion;
  final Value<String?> clientId;
  final Value<String?> clientChangeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const WeightTableCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.weightG = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.source = const Value.absent(),
    this.memo = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientChangeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WeightTableCompanion.insert({
    this.id = const Value.absent(),
    required int petId,
    required double weightG,
    required DateTime measuredAt,
    this.source = const Value.absent(),
    this.memo = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientChangeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : petId = Value(petId),
       weightG = Value(weightG),
       measuredAt = Value(measuredAt);
  static Insertable<WeightTableData> custom({
    Expression<int>? id,
    Expression<int>? petId,
    Expression<double>? weightG,
    Expression<DateTime>? measuredAt,
    Expression<String>? source,
    Expression<String>? memo,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncVersion,
    Expression<String>? clientId,
    Expression<String>? clientChangeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (weightG != null) 'weight_g': weightG,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (source != null) 'source': source,
      if (memo != null) 'memo': memo,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (clientId != null) 'client_id': clientId,
      if (clientChangeId != null) 'client_change_id': clientChangeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WeightTableCompanion copyWith({
    Value<int>? id,
    Value<int>? petId,
    Value<double>? weightG,
    Value<DateTime>? measuredAt,
    Value<String>? source,
    Value<String?>? memo,
    Value<DateTime?>? deletedAt,
    Value<int>? syncVersion,
    Value<String?>? clientId,
    Value<String?>? clientChangeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return WeightTableCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      weightG: weightG ?? this.weightG,
      measuredAt: measuredAt ?? this.measuredAt,
      source: source ?? this.source,
      memo: memo ?? this.memo,
      deletedAt: deletedAt ?? this.deletedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      clientId: clientId ?? this.clientId,
      clientChangeId: clientChangeId ?? this.clientChangeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<int>(petId.value);
    }
    if (weightG.present) {
      map['weight_g'] = Variable<double>(weightG.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientChangeId.present) {
      map['client_change_id'] = Variable<String>(clientChangeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightTableCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('weightG: $weightG, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('source: $source, ')
          ..write('memo: $memo, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('clientId: $clientId, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FeedingTableTable extends FeedingTable
    with TableInfo<$FeedingTableTable, FeedingTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedingTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<int> petId = GeneratedColumn<int>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pet_mst (id)',
    ),
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foodTypeMeta = const VerificationMeta(
    'foodType',
  );
  @override
  late final GeneratedColumn<String> foodType = GeneratedColumn<String>(
    'food_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedResponseMeta = const VerificationMeta(
    'feedResponse',
  );
  @override
  late final GeneratedColumn<String> feedResponse = GeneratedColumn<String>(
    'feed_response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fedAtMeta = const VerificationMeta('fedAt');
  @override
  late final GeneratedColumn<DateTime> fedAt = GeneratedColumn<DateTime>(
    'fed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientChangeIdMeta = const VerificationMeta(
    'clientChangeId',
  );
  @override
  late final GeneratedColumn<String> clientChangeId = GeneratedColumn<String>(
    'client_change_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petId,
    routineId,
    foodType,
    amount,
    unit,
    feedResponse,
    fedAt,
    memo,
    deletedAt,
    syncVersion,
    clientId,
    clientChangeId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feeding_dtl';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedingTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    }
    if (data.containsKey('food_type')) {
      context.handle(
        _foodTypeMeta,
        foodType.isAcceptableOrUnknown(data['food_type']!, _foodTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_foodTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('feed_response')) {
      context.handle(
        _feedResponseMeta,
        feedResponse.isAcceptableOrUnknown(
          data['feed_response']!,
          _feedResponseMeta,
        ),
      );
    }
    if (data.containsKey('fed_at')) {
      context.handle(
        _fedAtMeta,
        fedAt.isAcceptableOrUnknown(data['fed_at']!, _fedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fedAtMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('client_change_id')) {
      context.handle(
        _clientChangeIdMeta,
        clientChangeId.isAcceptableOrUnknown(
          data['client_change_id']!,
          _clientChangeIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedingTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedingTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}routine_id'],
      ),
      foodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      feedResponse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_response'],
      ),
      fedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fed_at'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      clientChangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_change_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FeedingTableTable createAlias(String alias) {
    return $FeedingTableTable(attachedDatabase, alias);
  }
}

class FeedingTableData extends DataClass
    implements Insertable<FeedingTableData> {
  final int id;
  final int petId;
  final int? routineId;
  final String foodType;
  final double? amount;
  final String? unit;
  final String? feedResponse;
  final DateTime fedAt;
  final String? memo;
  final DateTime? deletedAt;
  final int syncVersion;
  final String? clientId;
  final String? clientChangeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FeedingTableData({
    required this.id,
    required this.petId,
    this.routineId,
    required this.foodType,
    this.amount,
    this.unit,
    this.feedResponse,
    required this.fedAt,
    this.memo,
    this.deletedAt,
    required this.syncVersion,
    this.clientId,
    this.clientChangeId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<int>(petId);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<int>(routineId);
    }
    map['food_type'] = Variable<String>(foodType);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || feedResponse != null) {
      map['feed_response'] = Variable<String>(feedResponse);
    }
    map['fed_at'] = Variable<DateTime>(fedAt);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_version'] = Variable<int>(syncVersion);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || clientChangeId != null) {
      map['client_change_id'] = Variable<String>(clientChangeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FeedingTableCompanion toCompanion(bool nullToAbsent) {
    return FeedingTableCompanion(
      id: Value(id),
      petId: Value(petId),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      foodType: Value(foodType),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      feedResponse: feedResponse == null && nullToAbsent
          ? const Value.absent()
          : Value(feedResponse),
      fedAt: Value(fedAt),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncVersion: Value(syncVersion),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      clientChangeId: clientChangeId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientChangeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FeedingTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedingTableData(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<int>(json['petId']),
      routineId: serializer.fromJson<int?>(json['routineId']),
      foodType: serializer.fromJson<String>(json['foodType']),
      amount: serializer.fromJson<double?>(json['amount']),
      unit: serializer.fromJson<String?>(json['unit']),
      feedResponse: serializer.fromJson<String?>(json['feedResponse']),
      fedAt: serializer.fromJson<DateTime>(json['fedAt']),
      memo: serializer.fromJson<String?>(json['memo']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      clientChangeId: serializer.fromJson<String?>(json['clientChangeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<int>(petId),
      'routineId': serializer.toJson<int?>(routineId),
      'foodType': serializer.toJson<String>(foodType),
      'amount': serializer.toJson<double?>(amount),
      'unit': serializer.toJson<String?>(unit),
      'feedResponse': serializer.toJson<String?>(feedResponse),
      'fedAt': serializer.toJson<DateTime>(fedAt),
      'memo': serializer.toJson<String?>(memo),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'clientId': serializer.toJson<String?>(clientId),
      'clientChangeId': serializer.toJson<String?>(clientChangeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FeedingTableData copyWith({
    int? id,
    int? petId,
    Value<int?> routineId = const Value.absent(),
    String? foodType,
    Value<double?> amount = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> feedResponse = const Value.absent(),
    DateTime? fedAt,
    Value<String?> memo = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncVersion,
    Value<String?> clientId = const Value.absent(),
    Value<String?> clientChangeId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FeedingTableData(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    routineId: routineId.present ? routineId.value : this.routineId,
    foodType: foodType ?? this.foodType,
    amount: amount.present ? amount.value : this.amount,
    unit: unit.present ? unit.value : this.unit,
    feedResponse: feedResponse.present ? feedResponse.value : this.feedResponse,
    fedAt: fedAt ?? this.fedAt,
    memo: memo.present ? memo.value : this.memo,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncVersion: syncVersion ?? this.syncVersion,
    clientId: clientId.present ? clientId.value : this.clientId,
    clientChangeId: clientChangeId.present
        ? clientChangeId.value
        : this.clientChangeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FeedingTableData copyWithCompanion(FeedingTableCompanion data) {
    return FeedingTableData(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      foodType: data.foodType.present ? data.foodType.value : this.foodType,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      feedResponse: data.feedResponse.present
          ? data.feedResponse.value
          : this.feedResponse,
      fedAt: data.fedAt.present ? data.fedAt.value : this.fedAt,
      memo: data.memo.present ? data.memo.value : this.memo,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientChangeId: data.clientChangeId.present
          ? data.clientChangeId.value
          : this.clientChangeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedingTableData(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('routineId: $routineId, ')
          ..write('foodType: $foodType, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('feedResponse: $feedResponse, ')
          ..write('fedAt: $fedAt, ')
          ..write('memo: $memo, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('clientId: $clientId, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    routineId,
    foodType,
    amount,
    unit,
    feedResponse,
    fedAt,
    memo,
    deletedAt,
    syncVersion,
    clientId,
    clientChangeId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedingTableData &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.routineId == this.routineId &&
          other.foodType == this.foodType &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.feedResponse == this.feedResponse &&
          other.fedAt == this.fedAt &&
          other.memo == this.memo &&
          other.deletedAt == this.deletedAt &&
          other.syncVersion == this.syncVersion &&
          other.clientId == this.clientId &&
          other.clientChangeId == this.clientChangeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FeedingTableCompanion extends UpdateCompanion<FeedingTableData> {
  final Value<int> id;
  final Value<int> petId;
  final Value<int?> routineId;
  final Value<String> foodType;
  final Value<double?> amount;
  final Value<String?> unit;
  final Value<String?> feedResponse;
  final Value<DateTime> fedAt;
  final Value<String?> memo;
  final Value<DateTime?> deletedAt;
  final Value<int> syncVersion;
  final Value<String?> clientId;
  final Value<String?> clientChangeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FeedingTableCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.foodType = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.feedResponse = const Value.absent(),
    this.fedAt = const Value.absent(),
    this.memo = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientChangeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FeedingTableCompanion.insert({
    this.id = const Value.absent(),
    required int petId,
    this.routineId = const Value.absent(),
    required String foodType,
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.feedResponse = const Value.absent(),
    required DateTime fedAt,
    this.memo = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientChangeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : petId = Value(petId),
       foodType = Value(foodType),
       fedAt = Value(fedAt);
  static Insertable<FeedingTableData> custom({
    Expression<int>? id,
    Expression<int>? petId,
    Expression<int>? routineId,
    Expression<String>? foodType,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<String>? feedResponse,
    Expression<DateTime>? fedAt,
    Expression<String>? memo,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncVersion,
    Expression<String>? clientId,
    Expression<String>? clientChangeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (routineId != null) 'routine_id': routineId,
      if (foodType != null) 'food_type': foodType,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (feedResponse != null) 'feed_response': feedResponse,
      if (fedAt != null) 'fed_at': fedAt,
      if (memo != null) 'memo': memo,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (clientId != null) 'client_id': clientId,
      if (clientChangeId != null) 'client_change_id': clientChangeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FeedingTableCompanion copyWith({
    Value<int>? id,
    Value<int>? petId,
    Value<int?>? routineId,
    Value<String>? foodType,
    Value<double?>? amount,
    Value<String?>? unit,
    Value<String?>? feedResponse,
    Value<DateTime>? fedAt,
    Value<String?>? memo,
    Value<DateTime?>? deletedAt,
    Value<int>? syncVersion,
    Value<String?>? clientId,
    Value<String?>? clientChangeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FeedingTableCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      routineId: routineId ?? this.routineId,
      foodType: foodType ?? this.foodType,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      feedResponse: feedResponse ?? this.feedResponse,
      fedAt: fedAt ?? this.fedAt,
      memo: memo ?? this.memo,
      deletedAt: deletedAt ?? this.deletedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      clientId: clientId ?? this.clientId,
      clientChangeId: clientChangeId ?? this.clientChangeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<int>(petId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (foodType.present) {
      map['food_type'] = Variable<String>(foodType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (feedResponse.present) {
      map['feed_response'] = Variable<String>(feedResponse.value);
    }
    if (fedAt.present) {
      map['fed_at'] = Variable<DateTime>(fedAt.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (clientChangeId.present) {
      map['client_change_id'] = Variable<String>(clientChangeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedingTableCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('routineId: $routineId, ')
          ..write('foodType: $foodType, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('feedResponse: $feedResponse, ')
          ..write('fedAt: $fedAt, ')
          ..write('memo: $memo, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('clientId: $clientId, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HealthMemoTableTable extends HealthMemoTable
    with TableInfo<$HealthMemoTableTable, HealthMemoTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthMemoTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<int> petId = GeneratedColumn<int>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pet_mst (id)',
    ),
  );
  static const VerificationMeta _symptomMeta = const VerificationMeta(
    'symptom',
  );
  @override
  late final GeneratedColumn<String> symptom = GeneratedColumn<String>(
    'symptom',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _treatmentMeta = const VerificationMeta(
    'treatment',
  );
  @override
  late final GeneratedColumn<String> treatment = GeneratedColumn<String>(
    'treatment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petId,
    symptom,
    treatment,
    memo,
    recordedAt,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_memo_dtl';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthMemoTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('symptom')) {
      context.handle(
        _symptomMeta,
        symptom.isAcceptableOrUnknown(data['symptom']!, _symptomMeta),
      );
    }
    if (data.containsKey('treatment')) {
      context.handle(
        _treatmentMeta,
        treatment.isAcceptableOrUnknown(data['treatment']!, _treatmentMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthMemoTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthMemoTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_id'],
      )!,
      symptom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptom'],
      ),
      treatment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}treatment'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HealthMemoTableTable createAlias(String alias) {
    return $HealthMemoTableTable(attachedDatabase, alias);
  }
}

class HealthMemoTableData extends DataClass
    implements Insertable<HealthMemoTableData> {
  final int id;
  final int petId;
  final String? symptom;
  final String? treatment;
  final String? memo;
  final DateTime recordedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HealthMemoTableData({
    required this.id,
    required this.petId,
    this.symptom,
    this.treatment,
    this.memo,
    required this.recordedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<int>(petId);
    if (!nullToAbsent || symptom != null) {
      map['symptom'] = Variable<String>(symptom);
    }
    if (!nullToAbsent || treatment != null) {
      map['treatment'] = Variable<String>(treatment);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HealthMemoTableCompanion toCompanion(bool nullToAbsent) {
    return HealthMemoTableCompanion(
      id: Value(id),
      petId: Value(petId),
      symptom: symptom == null && nullToAbsent
          ? const Value.absent()
          : Value(symptom),
      treatment: treatment == null && nullToAbsent
          ? const Value.absent()
          : Value(treatment),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      recordedAt: Value(recordedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HealthMemoTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthMemoTableData(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<int>(json['petId']),
      symptom: serializer.fromJson<String?>(json['symptom']),
      treatment: serializer.fromJson<String?>(json['treatment']),
      memo: serializer.fromJson<String?>(json['memo']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<int>(petId),
      'symptom': serializer.toJson<String?>(symptom),
      'treatment': serializer.toJson<String?>(treatment),
      'memo': serializer.toJson<String?>(memo),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HealthMemoTableData copyWith({
    int? id,
    int? petId,
    Value<String?> symptom = const Value.absent(),
    Value<String?> treatment = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    DateTime? recordedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HealthMemoTableData(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    symptom: symptom.present ? symptom.value : this.symptom,
    treatment: treatment.present ? treatment.value : this.treatment,
    memo: memo.present ? memo.value : this.memo,
    recordedAt: recordedAt ?? this.recordedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HealthMemoTableData copyWithCompanion(HealthMemoTableCompanion data) {
    return HealthMemoTableData(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      symptom: data.symptom.present ? data.symptom.value : this.symptom,
      treatment: data.treatment.present ? data.treatment.value : this.treatment,
      memo: data.memo.present ? data.memo.value : this.memo,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthMemoTableData(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('symptom: $symptom, ')
          ..write('treatment: $treatment, ')
          ..write('memo: $memo, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    symptom,
    treatment,
    memo,
    recordedAt,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthMemoTableData &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.symptom == this.symptom &&
          other.treatment == this.treatment &&
          other.memo == this.memo &&
          other.recordedAt == this.recordedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HealthMemoTableCompanion extends UpdateCompanion<HealthMemoTableData> {
  final Value<int> id;
  final Value<int> petId;
  final Value<String?> symptom;
  final Value<String?> treatment;
  final Value<String?> memo;
  final Value<DateTime> recordedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const HealthMemoTableCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.symptom = const Value.absent(),
    this.treatment = const Value.absent(),
    this.memo = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HealthMemoTableCompanion.insert({
    this.id = const Value.absent(),
    required int petId,
    this.symptom = const Value.absent(),
    this.treatment = const Value.absent(),
    this.memo = const Value.absent(),
    required DateTime recordedAt,
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : petId = Value(petId),
       recordedAt = Value(recordedAt);
  static Insertable<HealthMemoTableData> custom({
    Expression<int>? id,
    Expression<int>? petId,
    Expression<String>? symptom,
    Expression<String>? treatment,
    Expression<String>? memo,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (symptom != null) 'symptom': symptom,
      if (treatment != null) 'treatment': treatment,
      if (memo != null) 'memo': memo,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HealthMemoTableCompanion copyWith({
    Value<int>? id,
    Value<int>? petId,
    Value<String?>? symptom,
    Value<String?>? treatment,
    Value<String?>? memo,
    Value<DateTime>? recordedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return HealthMemoTableCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      symptom: symptom ?? this.symptom,
      treatment: treatment ?? this.treatment,
      memo: memo ?? this.memo,
      recordedAt: recordedAt ?? this.recordedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<int>(petId.value);
    }
    if (symptom.present) {
      map['symptom'] = Variable<String>(symptom.value);
    }
    if (treatment.present) {
      map['treatment'] = Variable<String>(treatment.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthMemoTableCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('symptom: $symptom, ')
          ..write('treatment: $treatment, ')
          ..write('memo: $memo, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RoutineTableTable extends RoutineTable
    with TableInfo<$RoutineTableTable, RoutineTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<int> petId = GeneratedColumn<int>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pet_mst (id)',
    ),
  );
  static const VerificationMeta _routineTypeMeta = const VerificationMeta(
    'routineType',
  );
  @override
  late final GeneratedColumn<String> routineType = GeneratedColumn<String>(
    'routine_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleDaysMeta = const VerificationMeta(
    'cycleDays',
  );
  @override
  late final GeneratedColumn<int> cycleDays = GeneratedColumn<int>(
    'cycle_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alarmTimeMeta = const VerificationMeta(
    'alarmTime',
  );
  @override
  late final GeneratedColumn<String> alarmTime = GeneratedColumn<String>(
    'alarm_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAlarmEnabledMeta = const VerificationMeta(
    'isAlarmEnabled',
  );
  @override
  late final GeneratedColumn<bool> isAlarmEnabled = GeneratedColumn<bool>(
    'is_alarm_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alarm_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastExecutedAtMeta = const VerificationMeta(
    'lastExecutedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastExecutedAt =
      GeneratedColumn<DateTime>(
        'last_executed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextDueAtMeta = const VerificationMeta(
    'nextDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueAt = GeneratedColumn<DateTime>(
    'next_due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    petId,
    routineType,
    title,
    cycleDays,
    alarmTime,
    isAlarmEnabled,
    lastExecutedAt,
    nextDueAt,
    isActive,
    memo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_mst';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('routine_type')) {
      context.handle(
        _routineTypeMeta,
        routineType.isAcceptableOrUnknown(
          data['routine_type']!,
          _routineTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_routineTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cycle_days')) {
      context.handle(
        _cycleDaysMeta,
        cycleDays.isAcceptableOrUnknown(data['cycle_days']!, _cycleDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleDaysMeta);
    }
    if (data.containsKey('alarm_time')) {
      context.handle(
        _alarmTimeMeta,
        alarmTime.isAcceptableOrUnknown(data['alarm_time']!, _alarmTimeMeta),
      );
    }
    if (data.containsKey('is_alarm_enabled')) {
      context.handle(
        _isAlarmEnabledMeta,
        isAlarmEnabled.isAcceptableOrUnknown(
          data['is_alarm_enabled']!,
          _isAlarmEnabledMeta,
        ),
      );
    }
    if (data.containsKey('last_executed_at')) {
      context.handle(
        _lastExecutedAtMeta,
        lastExecutedAt.isAcceptableOrUnknown(
          data['last_executed_at']!,
          _lastExecutedAtMeta,
        ),
      );
    }
    if (data.containsKey('next_due_at')) {
      context.handle(
        _nextDueAtMeta,
        nextDueAt.isAcceptableOrUnknown(data['next_due_at']!, _nextDueAtMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_id'],
      )!,
      routineType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cycleDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_days'],
      )!,
      alarmTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alarm_time'],
      ),
      isAlarmEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alarm_enabled'],
      )!,
      lastExecutedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_executed_at'],
      ),
      nextDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RoutineTableTable createAlias(String alias) {
    return $RoutineTableTable(attachedDatabase, alias);
  }
}

class RoutineTableData extends DataClass
    implements Insertable<RoutineTableData> {
  final int id;
  final int petId;
  final String routineType;
  final String title;
  final int cycleDays;
  final String? alarmTime;
  final bool isAlarmEnabled;
  final DateTime? lastExecutedAt;
  final DateTime? nextDueAt;
  final bool isActive;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RoutineTableData({
    required this.id,
    required this.petId,
    required this.routineType,
    required this.title,
    required this.cycleDays,
    this.alarmTime,
    required this.isAlarmEnabled,
    this.lastExecutedAt,
    this.nextDueAt,
    required this.isActive,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<int>(petId);
    map['routine_type'] = Variable<String>(routineType);
    map['title'] = Variable<String>(title);
    map['cycle_days'] = Variable<int>(cycleDays);
    if (!nullToAbsent || alarmTime != null) {
      map['alarm_time'] = Variable<String>(alarmTime);
    }
    map['is_alarm_enabled'] = Variable<bool>(isAlarmEnabled);
    if (!nullToAbsent || lastExecutedAt != null) {
      map['last_executed_at'] = Variable<DateTime>(lastExecutedAt);
    }
    if (!nullToAbsent || nextDueAt != null) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RoutineTableCompanion toCompanion(bool nullToAbsent) {
    return RoutineTableCompanion(
      id: Value(id),
      petId: Value(petId),
      routineType: Value(routineType),
      title: Value(title),
      cycleDays: Value(cycleDays),
      alarmTime: alarmTime == null && nullToAbsent
          ? const Value.absent()
          : Value(alarmTime),
      isAlarmEnabled: Value(isAlarmEnabled),
      lastExecutedAt: lastExecutedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExecutedAt),
      nextDueAt: nextDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueAt),
      isActive: Value(isActive),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RoutineTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineTableData(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<int>(json['petId']),
      routineType: serializer.fromJson<String>(json['routineType']),
      title: serializer.fromJson<String>(json['title']),
      cycleDays: serializer.fromJson<int>(json['cycleDays']),
      alarmTime: serializer.fromJson<String?>(json['alarmTime']),
      isAlarmEnabled: serializer.fromJson<bool>(json['isAlarmEnabled']),
      lastExecutedAt: serializer.fromJson<DateTime?>(json['lastExecutedAt']),
      nextDueAt: serializer.fromJson<DateTime?>(json['nextDueAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<int>(petId),
      'routineType': serializer.toJson<String>(routineType),
      'title': serializer.toJson<String>(title),
      'cycleDays': serializer.toJson<int>(cycleDays),
      'alarmTime': serializer.toJson<String?>(alarmTime),
      'isAlarmEnabled': serializer.toJson<bool>(isAlarmEnabled),
      'lastExecutedAt': serializer.toJson<DateTime?>(lastExecutedAt),
      'nextDueAt': serializer.toJson<DateTime?>(nextDueAt),
      'isActive': serializer.toJson<bool>(isActive),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RoutineTableData copyWith({
    int? id,
    int? petId,
    String? routineType,
    String? title,
    int? cycleDays,
    Value<String?> alarmTime = const Value.absent(),
    bool? isAlarmEnabled,
    Value<DateTime?> lastExecutedAt = const Value.absent(),
    Value<DateTime?> nextDueAt = const Value.absent(),
    bool? isActive,
    Value<String?> memo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RoutineTableData(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    routineType: routineType ?? this.routineType,
    title: title ?? this.title,
    cycleDays: cycleDays ?? this.cycleDays,
    alarmTime: alarmTime.present ? alarmTime.value : this.alarmTime,
    isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
    lastExecutedAt: lastExecutedAt.present
        ? lastExecutedAt.value
        : this.lastExecutedAt,
    nextDueAt: nextDueAt.present ? nextDueAt.value : this.nextDueAt,
    isActive: isActive ?? this.isActive,
    memo: memo.present ? memo.value : this.memo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RoutineTableData copyWithCompanion(RoutineTableCompanion data) {
    return RoutineTableData(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      routineType: data.routineType.present
          ? data.routineType.value
          : this.routineType,
      title: data.title.present ? data.title.value : this.title,
      cycleDays: data.cycleDays.present ? data.cycleDays.value : this.cycleDays,
      alarmTime: data.alarmTime.present ? data.alarmTime.value : this.alarmTime,
      isAlarmEnabled: data.isAlarmEnabled.present
          ? data.isAlarmEnabled.value
          : this.isAlarmEnabled,
      lastExecutedAt: data.lastExecutedAt.present
          ? data.lastExecutedAt.value
          : this.lastExecutedAt,
      nextDueAt: data.nextDueAt.present ? data.nextDueAt.value : this.nextDueAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineTableData(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('routineType: $routineType, ')
          ..write('title: $title, ')
          ..write('cycleDays: $cycleDays, ')
          ..write('alarmTime: $alarmTime, ')
          ..write('isAlarmEnabled: $isAlarmEnabled, ')
          ..write('lastExecutedAt: $lastExecutedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('isActive: $isActive, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    petId,
    routineType,
    title,
    cycleDays,
    alarmTime,
    isAlarmEnabled,
    lastExecutedAt,
    nextDueAt,
    isActive,
    memo,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineTableData &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.routineType == this.routineType &&
          other.title == this.title &&
          other.cycleDays == this.cycleDays &&
          other.alarmTime == this.alarmTime &&
          other.isAlarmEnabled == this.isAlarmEnabled &&
          other.lastExecutedAt == this.lastExecutedAt &&
          other.nextDueAt == this.nextDueAt &&
          other.isActive == this.isActive &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RoutineTableCompanion extends UpdateCompanion<RoutineTableData> {
  final Value<int> id;
  final Value<int> petId;
  final Value<String> routineType;
  final Value<String> title;
  final Value<int> cycleDays;
  final Value<String?> alarmTime;
  final Value<bool> isAlarmEnabled;
  final Value<DateTime?> lastExecutedAt;
  final Value<DateTime?> nextDueAt;
  final Value<bool> isActive;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RoutineTableCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.routineType = const Value.absent(),
    this.title = const Value.absent(),
    this.cycleDays = const Value.absent(),
    this.alarmTime = const Value.absent(),
    this.isAlarmEnabled = const Value.absent(),
    this.lastExecutedAt = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RoutineTableCompanion.insert({
    this.id = const Value.absent(),
    required int petId,
    required String routineType,
    required String title,
    required int cycleDays,
    this.alarmTime = const Value.absent(),
    this.isAlarmEnabled = const Value.absent(),
    this.lastExecutedAt = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : petId = Value(petId),
       routineType = Value(routineType),
       title = Value(title),
       cycleDays = Value(cycleDays);
  static Insertable<RoutineTableData> custom({
    Expression<int>? id,
    Expression<int>? petId,
    Expression<String>? routineType,
    Expression<String>? title,
    Expression<int>? cycleDays,
    Expression<String>? alarmTime,
    Expression<bool>? isAlarmEnabled,
    Expression<DateTime>? lastExecutedAt,
    Expression<DateTime>? nextDueAt,
    Expression<bool>? isActive,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (routineType != null) 'routine_type': routineType,
      if (title != null) 'title': title,
      if (cycleDays != null) 'cycle_days': cycleDays,
      if (alarmTime != null) 'alarm_time': alarmTime,
      if (isAlarmEnabled != null) 'is_alarm_enabled': isAlarmEnabled,
      if (lastExecutedAt != null) 'last_executed_at': lastExecutedAt,
      if (nextDueAt != null) 'next_due_at': nextDueAt,
      if (isActive != null) 'is_active': isActive,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RoutineTableCompanion copyWith({
    Value<int>? id,
    Value<int>? petId,
    Value<String>? routineType,
    Value<String>? title,
    Value<int>? cycleDays,
    Value<String?>? alarmTime,
    Value<bool>? isAlarmEnabled,
    Value<DateTime?>? lastExecutedAt,
    Value<DateTime?>? nextDueAt,
    Value<bool>? isActive,
    Value<String?>? memo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return RoutineTableCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      routineType: routineType ?? this.routineType,
      title: title ?? this.title,
      cycleDays: cycleDays ?? this.cycleDays,
      alarmTime: alarmTime ?? this.alarmTime,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      isActive: isActive ?? this.isActive,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<int>(petId.value);
    }
    if (routineType.present) {
      map['routine_type'] = Variable<String>(routineType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cycleDays.present) {
      map['cycle_days'] = Variable<int>(cycleDays.value);
    }
    if (alarmTime.present) {
      map['alarm_time'] = Variable<String>(alarmTime.value);
    }
    if (isAlarmEnabled.present) {
      map['is_alarm_enabled'] = Variable<bool>(isAlarmEnabled.value);
    }
    if (lastExecutedAt.present) {
      map['last_executed_at'] = Variable<DateTime>(lastExecutedAt.value);
    }
    if (nextDueAt.present) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineTableCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('routineType: $routineType, ')
          ..write('title: $title, ')
          ..write('cycleDays: $cycleDays, ')
          ..write('alarmTime: $alarmTime, ')
          ..write('isAlarmEnabled: $isAlarmEnabled, ')
          ..write('lastExecutedAt: $lastExecutedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('isActive: $isActive, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RoutineLogTableTable extends RoutineLogTable
    with TableInfo<$RoutineLogTableTable, RoutineLogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineLogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routine_mst (id)',
    ),
  );
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<int> petId = GeneratedColumn<int>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pet_mst (id)',
    ),
  );
  static const VerificationMeta _executedAtMeta = const VerificationMeta(
    'executedAt',
  );
  @override
  late final GeneratedColumn<DateTime> executedAt = GeneratedColumn<DateTime>(
    'executed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraDataMeta = const VerificationMeta(
    'extraData',
  );
  @override
  late final GeneratedColumn<String> extraData = GeneratedColumn<String>(
    'extra_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routineId,
    petId,
    executedAt,
    extraData,
    memo,
    deletedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_log_dtl';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineLogTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('executed_at')) {
      context.handle(
        _executedAtMeta,
        executedAt.isAcceptableOrUnknown(data['executed_at']!, _executedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_executedAtMeta);
    }
    if (data.containsKey('extra_data')) {
      context.handle(
        _extraDataMeta,
        extraData.isAcceptableOrUnknown(data['extra_data']!, _extraDataMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineLogTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineLogTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}routine_id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_id'],
      )!,
      executedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}executed_at'],
      )!,
      extraData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_data'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RoutineLogTableTable createAlias(String alias) {
    return $RoutineLogTableTable(attachedDatabase, alias);
  }
}

class RoutineLogTableData extends DataClass
    implements Insertable<RoutineLogTableData> {
  final int id;
  final int routineId;
  final int petId;
  final DateTime executedAt;
  final String? extraData;
  final String? memo;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RoutineLogTableData({
    required this.id,
    required this.routineId,
    required this.petId,
    required this.executedAt,
    this.extraData,
    this.memo,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['routine_id'] = Variable<int>(routineId);
    map['pet_id'] = Variable<int>(petId);
    map['executed_at'] = Variable<DateTime>(executedAt);
    if (!nullToAbsent || extraData != null) {
      map['extra_data'] = Variable<String>(extraData);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RoutineLogTableCompanion toCompanion(bool nullToAbsent) {
    return RoutineLogTableCompanion(
      id: Value(id),
      routineId: Value(routineId),
      petId: Value(petId),
      executedAt: Value(executedAt),
      extraData: extraData == null && nullToAbsent
          ? const Value.absent()
          : Value(extraData),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RoutineLogTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineLogTableData(
      id: serializer.fromJson<int>(json['id']),
      routineId: serializer.fromJson<int>(json['routineId']),
      petId: serializer.fromJson<int>(json['petId']),
      executedAt: serializer.fromJson<DateTime>(json['executedAt']),
      extraData: serializer.fromJson<String?>(json['extraData']),
      memo: serializer.fromJson<String?>(json['memo']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routineId': serializer.toJson<int>(routineId),
      'petId': serializer.toJson<int>(petId),
      'executedAt': serializer.toJson<DateTime>(executedAt),
      'extraData': serializer.toJson<String?>(extraData),
      'memo': serializer.toJson<String?>(memo),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RoutineLogTableData copyWith({
    int? id,
    int? routineId,
    int? petId,
    DateTime? executedAt,
    Value<String?> extraData = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RoutineLogTableData(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    petId: petId ?? this.petId,
    executedAt: executedAt ?? this.executedAt,
    extraData: extraData.present ? extraData.value : this.extraData,
    memo: memo.present ? memo.value : this.memo,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RoutineLogTableData copyWithCompanion(RoutineLogTableCompanion data) {
    return RoutineLogTableData(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      petId: data.petId.present ? data.petId.value : this.petId,
      executedAt: data.executedAt.present
          ? data.executedAt.value
          : this.executedAt,
      extraData: data.extraData.present ? data.extraData.value : this.extraData,
      memo: data.memo.present ? data.memo.value : this.memo,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineLogTableData(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('petId: $petId, ')
          ..write('executedAt: $executedAt, ')
          ..write('extraData: $extraData, ')
          ..write('memo: $memo, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    routineId,
    petId,
    executedAt,
    extraData,
    memo,
    deletedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineLogTableData &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.petId == this.petId &&
          other.executedAt == this.executedAt &&
          other.extraData == this.extraData &&
          other.memo == this.memo &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RoutineLogTableCompanion extends UpdateCompanion<RoutineLogTableData> {
  final Value<int> id;
  final Value<int> routineId;
  final Value<int> petId;
  final Value<DateTime> executedAt;
  final Value<String?> extraData;
  final Value<String?> memo;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RoutineLogTableCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.petId = const Value.absent(),
    this.executedAt = const Value.absent(),
    this.extraData = const Value.absent(),
    this.memo = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RoutineLogTableCompanion.insert({
    this.id = const Value.absent(),
    required int routineId,
    required int petId,
    required DateTime executedAt,
    this.extraData = const Value.absent(),
    this.memo = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : routineId = Value(routineId),
       petId = Value(petId),
       executedAt = Value(executedAt);
  static Insertable<RoutineLogTableData> custom({
    Expression<int>? id,
    Expression<int>? routineId,
    Expression<int>? petId,
    Expression<DateTime>? executedAt,
    Expression<String>? extraData,
    Expression<String>? memo,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (petId != null) 'pet_id': petId,
      if (executedAt != null) 'executed_at': executedAt,
      if (extraData != null) 'extra_data': extraData,
      if (memo != null) 'memo': memo,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RoutineLogTableCompanion copyWith({
    Value<int>? id,
    Value<int>? routineId,
    Value<int>? petId,
    Value<DateTime>? executedAt,
    Value<String?>? extraData,
    Value<String?>? memo,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return RoutineLogTableCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      petId: petId ?? this.petId,
      executedAt: executedAt ?? this.executedAt,
      extraData: extraData ?? this.extraData,
      memo: memo ?? this.memo,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<int>(petId.value);
    }
    if (executedAt.present) {
      map['executed_at'] = Variable<DateTime>(executedAt.value);
    }
    if (extraData.present) {
      map['extra_data'] = Variable<String>(extraData.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineLogTableCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('petId: $petId, ')
          ..write('executedAt: $executedAt, ')
          ..write('extraData: $extraData, ')
          ..write('memo: $memo, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingOpTableTable extends PendingOpTable
    with TableInfo<$PendingOpTableTable, PendingOpTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOpTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientChangeIdMeta = const VerificationMeta(
    'clientChangeId',
  );
  @override
  late final GeneratedColumn<String> clientChangeId = GeneratedColumn<String>(
    'client_change_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    recordId,
    operation,
    payload,
    clientChangeId,
    retryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = '_pending_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOpTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('client_change_id')) {
      context.handle(
        _clientChangeIdMeta,
        clientChangeId.isAcceptableOrUnknown(
          data['client_change_id']!,
          _clientChangeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientChangeIdMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOpTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOpTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      clientChangeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_change_id'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingOpTableTable createAlias(String alias) {
    return $PendingOpTableTable(attachedDatabase, alias);
  }
}

class PendingOpTableData extends DataClass
    implements Insertable<PendingOpTableData> {
  final int id;
  final String targetTable;
  final int recordId;
  final String operation;
  final String payload;
  final String clientChangeId;
  final int retryCount;
  final DateTime createdAt;
  const PendingOpTableData({
    required this.id,
    required this.targetTable,
    required this.recordId,
    required this.operation,
    required this.payload,
    required this.clientChangeId,
    required this.retryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<int>(recordId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['client_change_id'] = Variable<String>(clientChangeId);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingOpTableCompanion toCompanion(bool nullToAbsent) {
    return PendingOpTableCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      operation: Value(operation),
      payload: Value(payload),
      clientChangeId: Value(clientChangeId),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory PendingOpTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOpTableData(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<int>(json['recordId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      clientChangeId: serializer.fromJson<String>(json['clientChangeId']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<int>(recordId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'clientChangeId': serializer.toJson<String>(clientChangeId),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingOpTableData copyWith({
    int? id,
    String? targetTable,
    int? recordId,
    String? operation,
    String? payload,
    String? clientChangeId,
    int? retryCount,
    DateTime? createdAt,
  }) => PendingOpTableData(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    recordId: recordId ?? this.recordId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    clientChangeId: clientChangeId ?? this.clientChangeId,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingOpTableData copyWithCompanion(PendingOpTableCompanion data) {
    return PendingOpTableData(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      clientChangeId: data.clientChangeId.present
          ? data.clientChangeId.value
          : this.clientChangeId,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpTableData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    recordId,
    operation,
    payload,
    clientChangeId,
    retryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOpTableData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.clientChangeId == this.clientChangeId &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class PendingOpTableCompanion extends UpdateCompanion<PendingOpTableData> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<int> recordId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<String> clientChangeId;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  const PendingOpTableCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.clientChangeId = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingOpTableCompanion.insert({
    this.id = const Value.absent(),
    required String targetTable,
    required int recordId,
    required String operation,
    required String payload,
    required String clientChangeId,
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : targetTable = Value(targetTable),
       recordId = Value(recordId),
       operation = Value(operation),
       payload = Value(payload),
       clientChangeId = Value(clientChangeId);
  static Insertable<PendingOpTableData> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<int>? recordId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? clientChangeId,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (clientChangeId != null) 'client_change_id': clientChangeId,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingOpTableCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<int>? recordId,
    Value<String>? operation,
    Value<String>? payload,
    Value<String>? clientChangeId,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
  }) {
    return PendingOpTableCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      clientChangeId: clientChangeId ?? this.clientChangeId,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (clientChangeId.present) {
      map['client_change_id'] = Variable<String>(clientChangeId.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpTableCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('clientChangeId: $clientChangeId, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PetTableTable petTable = $PetTableTable(this);
  late final $WeightTableTable weightTable = $WeightTableTable(this);
  late final $FeedingTableTable feedingTable = $FeedingTableTable(this);
  late final $HealthMemoTableTable healthMemoTable = $HealthMemoTableTable(
    this,
  );
  late final $RoutineTableTable routineTable = $RoutineTableTable(this);
  late final $RoutineLogTableTable routineLogTable = $RoutineLogTableTable(
    this,
  );
  late final $PendingOpTableTable pendingOpTable = $PendingOpTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    petTable,
    weightTable,
    feedingTable,
    healthMemoTable,
    routineTable,
    routineLogTable,
    pendingOpTable,
  ];
}

typedef $$PetTableTableCreateCompanionBuilder =
    PetTableCompanion Function({
      Value<int> id,
      required String serialNo,
      required int userId,
      required int speciesId,
      required String name,
      Value<String> gender,
      Value<int?> morphId,
      Value<String?> description,
      Value<String?> colorCode,
      Value<String?> environmentMemo,
      Value<DateTime?> breedingDate,
      Value<DateTime?> hatchingDate,
      Value<DateTime?> adoptionDate,
      Value<int?> profilePhotoId,
      Value<DateTime?> deletedAt,
      Value<int> syncVersion,
      Value<String?> clientId,
      Value<String?> clientChangeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PetTableTableUpdateCompanionBuilder =
    PetTableCompanion Function({
      Value<int> id,
      Value<String> serialNo,
      Value<int> userId,
      Value<int> speciesId,
      Value<String> name,
      Value<String> gender,
      Value<int?> morphId,
      Value<String?> description,
      Value<String?> colorCode,
      Value<String?> environmentMemo,
      Value<DateTime?> breedingDate,
      Value<DateTime?> hatchingDate,
      Value<DateTime?> adoptionDate,
      Value<int?> profilePhotoId,
      Value<DateTime?> deletedAt,
      Value<int> syncVersion,
      Value<String?> clientId,
      Value<String?> clientChangeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PetTableTableReferences
    extends BaseReferences<_$AppDatabase, $PetTableTable, PetTableData> {
  $$PetTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WeightTableTable, List<WeightTableData>>
  _weightTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weightTable,
    aliasName: $_aliasNameGenerator(db.petTable.id, db.weightTable.petId),
  );

  $$WeightTableTableProcessedTableManager get weightTableRefs {
    final manager = $$WeightTableTableTableManager(
      $_db,
      $_db.weightTable,
    ).filter((f) => f.petId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_weightTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FeedingTableTable, List<FeedingTableData>>
  _feedingTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.feedingTable,
    aliasName: $_aliasNameGenerator(db.petTable.id, db.feedingTable.petId),
  );

  $$FeedingTableTableProcessedTableManager get feedingTableRefs {
    final manager = $$FeedingTableTableTableManager(
      $_db,
      $_db.feedingTable,
    ).filter((f) => f.petId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_feedingTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HealthMemoTableTable, List<HealthMemoTableData>>
  _healthMemoTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.healthMemoTable,
    aliasName: $_aliasNameGenerator(db.petTable.id, db.healthMemoTable.petId),
  );

  $$HealthMemoTableTableProcessedTableManager get healthMemoTableRefs {
    final manager = $$HealthMemoTableTableTableManager(
      $_db,
      $_db.healthMemoTable,
    ).filter((f) => f.petId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _healthMemoTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RoutineTableTable, List<RoutineTableData>>
  _routineTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routineTable,
    aliasName: $_aliasNameGenerator(db.petTable.id, db.routineTable.petId),
  );

  $$RoutineTableTableProcessedTableManager get routineTableRefs {
    final manager = $$RoutineTableTableTableManager(
      $_db,
      $_db.routineTable,
    ).filter((f) => f.petId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RoutineLogTableTable, List<RoutineLogTableData>>
  _routineLogTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routineLogTable,
    aliasName: $_aliasNameGenerator(db.petTable.id, db.routineLogTable.petId),
  );

  $$RoutineLogTableTableProcessedTableManager get routineLogTableRefs {
    final manager = $$RoutineLogTableTableTableManager(
      $_db,
      $_db.routineLogTable,
    ).filter((f) => f.petId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _routineLogTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PetTableTableFilterComposer
    extends Composer<_$AppDatabase, $PetTableTable> {
  $$PetTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNo => $composableBuilder(
    column: $table.serialNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get morphId => $composableBuilder(
    column: $table.morphId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorCode => $composableBuilder(
    column: $table.colorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentMemo => $composableBuilder(
    column: $table.environmentMemo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get breedingDate => $composableBuilder(
    column: $table.breedingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hatchingDate => $composableBuilder(
    column: $table.hatchingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get adoptionDate => $composableBuilder(
    column: $table.adoptionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profilePhotoId => $composableBuilder(
    column: $table.profilePhotoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> weightTableRefs(
    Expression<bool> Function($$WeightTableTableFilterComposer f) f,
  ) {
    final $$WeightTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weightTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightTableTableFilterComposer(
            $db: $db,
            $table: $db.weightTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> feedingTableRefs(
    Expression<bool> Function($$FeedingTableTableFilterComposer f) f,
  ) {
    final $$FeedingTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feedingTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedingTableTableFilterComposer(
            $db: $db,
            $table: $db.feedingTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> healthMemoTableRefs(
    Expression<bool> Function($$HealthMemoTableTableFilterComposer f) f,
  ) {
    final $$HealthMemoTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.healthMemoTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HealthMemoTableTableFilterComposer(
            $db: $db,
            $table: $db.healthMemoTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> routineTableRefs(
    Expression<bool> Function($$RoutineTableTableFilterComposer f) f,
  ) {
    final $$RoutineTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineTableTableFilterComposer(
            $db: $db,
            $table: $db.routineTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> routineLogTableRefs(
    Expression<bool> Function($$RoutineLogTableTableFilterComposer f) f,
  ) {
    final $$RoutineLogTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineLogTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineLogTableTableFilterComposer(
            $db: $db,
            $table: $db.routineLogTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PetTableTable> {
  $$PetTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNo => $composableBuilder(
    column: $table.serialNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get speciesId => $composableBuilder(
    column: $table.speciesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get morphId => $composableBuilder(
    column: $table.morphId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorCode => $composableBuilder(
    column: $table.colorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentMemo => $composableBuilder(
    column: $table.environmentMemo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get breedingDate => $composableBuilder(
    column: $table.breedingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hatchingDate => $composableBuilder(
    column: $table.hatchingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get adoptionDate => $composableBuilder(
    column: $table.adoptionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profilePhotoId => $composableBuilder(
    column: $table.profilePhotoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PetTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PetTableTable> {
  $$PetTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serialNo =>
      $composableBuilder(column: $table.serialNo, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get speciesId =>
      $composableBuilder(column: $table.speciesId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get morphId =>
      $composableBuilder(column: $table.morphId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorCode =>
      $composableBuilder(column: $table.colorCode, builder: (column) => column);

  GeneratedColumn<String> get environmentMemo => $composableBuilder(
    column: $table.environmentMemo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get breedingDate => $composableBuilder(
    column: $table.breedingDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get hatchingDate => $composableBuilder(
    column: $table.hatchingDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get adoptionDate => $composableBuilder(
    column: $table.adoptionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get profilePhotoId => $composableBuilder(
    column: $table.profilePhotoId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> weightTableRefs<T extends Object>(
    Expression<T> Function($$WeightTableTableAnnotationComposer a) f,
  ) {
    final $$WeightTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weightTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightTableTableAnnotationComposer(
            $db: $db,
            $table: $db.weightTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> feedingTableRefs<T extends Object>(
    Expression<T> Function($$FeedingTableTableAnnotationComposer a) f,
  ) {
    final $$FeedingTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feedingTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedingTableTableAnnotationComposer(
            $db: $db,
            $table: $db.feedingTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> healthMemoTableRefs<T extends Object>(
    Expression<T> Function($$HealthMemoTableTableAnnotationComposer a) f,
  ) {
    final $$HealthMemoTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.healthMemoTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HealthMemoTableTableAnnotationComposer(
            $db: $db,
            $table: $db.healthMemoTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> routineTableRefs<T extends Object>(
    Expression<T> Function($$RoutineTableTableAnnotationComposer a) f,
  ) {
    final $$RoutineTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routineTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> routineLogTableRefs<T extends Object>(
    Expression<T> Function($$RoutineLogTableTableAnnotationComposer a) f,
  ) {
    final $$RoutineLogTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineLogTable,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineLogTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routineLogTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PetTableTable,
          PetTableData,
          $$PetTableTableFilterComposer,
          $$PetTableTableOrderingComposer,
          $$PetTableTableAnnotationComposer,
          $$PetTableTableCreateCompanionBuilder,
          $$PetTableTableUpdateCompanionBuilder,
          (PetTableData, $$PetTableTableReferences),
          PetTableData,
          PrefetchHooks Function({
            bool weightTableRefs,
            bool feedingTableRefs,
            bool healthMemoTableRefs,
            bool routineTableRefs,
            bool routineLogTableRefs,
          })
        > {
  $$PetTableTableTableManager(_$AppDatabase db, $PetTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PetTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PetTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PetTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serialNo = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> speciesId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int?> morphId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> colorCode = const Value.absent(),
                Value<String?> environmentMemo = const Value.absent(),
                Value<DateTime?> breedingDate = const Value.absent(),
                Value<DateTime?> hatchingDate = const Value.absent(),
                Value<DateTime?> adoptionDate = const Value.absent(),
                Value<int?> profilePhotoId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientChangeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PetTableCompanion(
                id: id,
                serialNo: serialNo,
                userId: userId,
                speciesId: speciesId,
                name: name,
                gender: gender,
                morphId: morphId,
                description: description,
                colorCode: colorCode,
                environmentMemo: environmentMemo,
                breedingDate: breedingDate,
                hatchingDate: hatchingDate,
                adoptionDate: adoptionDate,
                profilePhotoId: profilePhotoId,
                deletedAt: deletedAt,
                syncVersion: syncVersion,
                clientId: clientId,
                clientChangeId: clientChangeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serialNo,
                required int userId,
                required int speciesId,
                required String name,
                Value<String> gender = const Value.absent(),
                Value<int?> morphId = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> colorCode = const Value.absent(),
                Value<String?> environmentMemo = const Value.absent(),
                Value<DateTime?> breedingDate = const Value.absent(),
                Value<DateTime?> hatchingDate = const Value.absent(),
                Value<DateTime?> adoptionDate = const Value.absent(),
                Value<int?> profilePhotoId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientChangeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PetTableCompanion.insert(
                id: id,
                serialNo: serialNo,
                userId: userId,
                speciesId: speciesId,
                name: name,
                gender: gender,
                morphId: morphId,
                description: description,
                colorCode: colorCode,
                environmentMemo: environmentMemo,
                breedingDate: breedingDate,
                hatchingDate: hatchingDate,
                adoptionDate: adoptionDate,
                profilePhotoId: profilePhotoId,
                deletedAt: deletedAt,
                syncVersion: syncVersion,
                clientId: clientId,
                clientChangeId: clientChangeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PetTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                weightTableRefs = false,
                feedingTableRefs = false,
                healthMemoTableRefs = false,
                routineTableRefs = false,
                routineLogTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (weightTableRefs) db.weightTable,
                    if (feedingTableRefs) db.feedingTable,
                    if (healthMemoTableRefs) db.healthMemoTable,
                    if (routineTableRefs) db.routineTable,
                    if (routineLogTableRefs) db.routineLogTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (weightTableRefs)
                        await $_getPrefetchedData<
                          PetTableData,
                          $PetTableTable,
                          WeightTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PetTableTableReferences
                              ._weightTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PetTableTableReferences(
                                db,
                                table,
                                p0,
                              ).weightTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.petId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (feedingTableRefs)
                        await $_getPrefetchedData<
                          PetTableData,
                          $PetTableTable,
                          FeedingTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PetTableTableReferences
                              ._feedingTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PetTableTableReferences(
                                db,
                                table,
                                p0,
                              ).feedingTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.petId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (healthMemoTableRefs)
                        await $_getPrefetchedData<
                          PetTableData,
                          $PetTableTable,
                          HealthMemoTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PetTableTableReferences
                              ._healthMemoTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PetTableTableReferences(
                                db,
                                table,
                                p0,
                              ).healthMemoTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.petId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (routineTableRefs)
                        await $_getPrefetchedData<
                          PetTableData,
                          $PetTableTable,
                          RoutineTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PetTableTableReferences
                              ._routineTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PetTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routineTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.petId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (routineLogTableRefs)
                        await $_getPrefetchedData<
                          PetTableData,
                          $PetTableTable,
                          RoutineLogTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PetTableTableReferences
                              ._routineLogTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PetTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routineLogTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.petId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PetTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PetTableTable,
      PetTableData,
      $$PetTableTableFilterComposer,
      $$PetTableTableOrderingComposer,
      $$PetTableTableAnnotationComposer,
      $$PetTableTableCreateCompanionBuilder,
      $$PetTableTableUpdateCompanionBuilder,
      (PetTableData, $$PetTableTableReferences),
      PetTableData,
      PrefetchHooks Function({
        bool weightTableRefs,
        bool feedingTableRefs,
        bool healthMemoTableRefs,
        bool routineTableRefs,
        bool routineLogTableRefs,
      })
    >;
typedef $$WeightTableTableCreateCompanionBuilder =
    WeightTableCompanion Function({
      Value<int> id,
      required int petId,
      required double weightG,
      required DateTime measuredAt,
      Value<String> source,
      Value<String?> memo,
      Value<DateTime?> deletedAt,
      Value<int> syncVersion,
      Value<String?> clientId,
      Value<String?> clientChangeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$WeightTableTableUpdateCompanionBuilder =
    WeightTableCompanion Function({
      Value<int> id,
      Value<int> petId,
      Value<double> weightG,
      Value<DateTime> measuredAt,
      Value<String> source,
      Value<String?> memo,
      Value<DateTime?> deletedAt,
      Value<int> syncVersion,
      Value<String?> clientId,
      Value<String?> clientChangeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$WeightTableTableReferences
    extends BaseReferences<_$AppDatabase, $WeightTableTable, WeightTableData> {
  $$WeightTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PetTableTable _petIdTable(_$AppDatabase db) => db.petTable
      .createAlias($_aliasNameGenerator(db.weightTable.petId, db.petTable.id));

  $$PetTableTableProcessedTableManager get petId {
    final $_column = $_itemColumn<int>('pet_id')!;

    final manager = $$PetTableTableTableManager(
      $_db,
      $_db.petTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_petIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeightTableTableFilterComposer
    extends Composer<_$AppDatabase, $WeightTableTable> {
  $$WeightTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightG => $composableBuilder(
    column: $table.weightG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PetTableTableFilterComposer get petId {
    final $$PetTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableFilterComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightTableTable> {
  $$WeightTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightG => $composableBuilder(
    column: $table.weightG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PetTableTableOrderingComposer get petId {
    final $$PetTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableOrderingComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightTableTable> {
  $$WeightTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weightG =>
      $composableBuilder(column: $table.weightG, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PetTableTableAnnotationComposer get petId {
    final $$PetTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableAnnotationComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightTableTable,
          WeightTableData,
          $$WeightTableTableFilterComposer,
          $$WeightTableTableOrderingComposer,
          $$WeightTableTableAnnotationComposer,
          $$WeightTableTableCreateCompanionBuilder,
          $$WeightTableTableUpdateCompanionBuilder,
          (WeightTableData, $$WeightTableTableReferences),
          WeightTableData,
          PrefetchHooks Function({bool petId})
        > {
  $$WeightTableTableTableManager(_$AppDatabase db, $WeightTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> petId = const Value.absent(),
                Value<double> weightG = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientChangeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WeightTableCompanion(
                id: id,
                petId: petId,
                weightG: weightG,
                measuredAt: measuredAt,
                source: source,
                memo: memo,
                deletedAt: deletedAt,
                syncVersion: syncVersion,
                clientId: clientId,
                clientChangeId: clientChangeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int petId,
                required double weightG,
                required DateTime measuredAt,
                Value<String> source = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientChangeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WeightTableCompanion.insert(
                id: id,
                petId: petId,
                weightG: weightG,
                measuredAt: measuredAt,
                source: source,
                memo: memo,
                deletedAt: deletedAt,
                syncVersion: syncVersion,
                clientId: clientId,
                clientChangeId: clientChangeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeightTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({petId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (petId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.petId,
                                referencedTable: $$WeightTableTableReferences
                                    ._petIdTable(db),
                                referencedColumn: $$WeightTableTableReferences
                                    ._petIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WeightTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightTableTable,
      WeightTableData,
      $$WeightTableTableFilterComposer,
      $$WeightTableTableOrderingComposer,
      $$WeightTableTableAnnotationComposer,
      $$WeightTableTableCreateCompanionBuilder,
      $$WeightTableTableUpdateCompanionBuilder,
      (WeightTableData, $$WeightTableTableReferences),
      WeightTableData,
      PrefetchHooks Function({bool petId})
    >;
typedef $$FeedingTableTableCreateCompanionBuilder =
    FeedingTableCompanion Function({
      Value<int> id,
      required int petId,
      Value<int?> routineId,
      required String foodType,
      Value<double?> amount,
      Value<String?> unit,
      Value<String?> feedResponse,
      required DateTime fedAt,
      Value<String?> memo,
      Value<DateTime?> deletedAt,
      Value<int> syncVersion,
      Value<String?> clientId,
      Value<String?> clientChangeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$FeedingTableTableUpdateCompanionBuilder =
    FeedingTableCompanion Function({
      Value<int> id,
      Value<int> petId,
      Value<int?> routineId,
      Value<String> foodType,
      Value<double?> amount,
      Value<String?> unit,
      Value<String?> feedResponse,
      Value<DateTime> fedAt,
      Value<String?> memo,
      Value<DateTime?> deletedAt,
      Value<int> syncVersion,
      Value<String?> clientId,
      Value<String?> clientChangeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$FeedingTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $FeedingTableTable, FeedingTableData> {
  $$FeedingTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PetTableTable _petIdTable(_$AppDatabase db) => db.petTable
      .createAlias($_aliasNameGenerator(db.feedingTable.petId, db.petTable.id));

  $$PetTableTableProcessedTableManager get petId {
    final $_column = $_itemColumn<int>('pet_id')!;

    final manager = $$PetTableTableTableManager(
      $_db,
      $_db.petTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_petIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FeedingTableTableFilterComposer
    extends Composer<_$AppDatabase, $FeedingTableTable> {
  $$FeedingTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodType => $composableBuilder(
    column: $table.foodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedResponse => $composableBuilder(
    column: $table.feedResponse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fedAt => $composableBuilder(
    column: $table.fedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PetTableTableFilterComposer get petId {
    final $$PetTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableFilterComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedingTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedingTableTable> {
  $$FeedingTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodType => $composableBuilder(
    column: $table.foodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedResponse => $composableBuilder(
    column: $table.feedResponse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fedAt => $composableBuilder(
    column: $table.fedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PetTableTableOrderingComposer get petId {
    final $$PetTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableOrderingComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedingTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedingTableTable> {
  $$FeedingTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get foodType =>
      $composableBuilder(column: $table.foodType, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get feedResponse => $composableBuilder(
    column: $table.feedResponse,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fedAt =>
      $composableBuilder(column: $table.fedAt, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PetTableTableAnnotationComposer get petId {
    final $$PetTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableAnnotationComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedingTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedingTableTable,
          FeedingTableData,
          $$FeedingTableTableFilterComposer,
          $$FeedingTableTableOrderingComposer,
          $$FeedingTableTableAnnotationComposer,
          $$FeedingTableTableCreateCompanionBuilder,
          $$FeedingTableTableUpdateCompanionBuilder,
          (FeedingTableData, $$FeedingTableTableReferences),
          FeedingTableData,
          PrefetchHooks Function({bool petId})
        > {
  $$FeedingTableTableTableManager(_$AppDatabase db, $FeedingTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedingTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedingTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedingTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> petId = const Value.absent(),
                Value<int?> routineId = const Value.absent(),
                Value<String> foodType = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> feedResponse = const Value.absent(),
                Value<DateTime> fedAt = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientChangeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FeedingTableCompanion(
                id: id,
                petId: petId,
                routineId: routineId,
                foodType: foodType,
                amount: amount,
                unit: unit,
                feedResponse: feedResponse,
                fedAt: fedAt,
                memo: memo,
                deletedAt: deletedAt,
                syncVersion: syncVersion,
                clientId: clientId,
                clientChangeId: clientChangeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int petId,
                Value<int?> routineId = const Value.absent(),
                required String foodType,
                Value<double?> amount = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> feedResponse = const Value.absent(),
                required DateTime fedAt,
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> clientChangeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FeedingTableCompanion.insert(
                id: id,
                petId: petId,
                routineId: routineId,
                foodType: foodType,
                amount: amount,
                unit: unit,
                feedResponse: feedResponse,
                fedAt: fedAt,
                memo: memo,
                deletedAt: deletedAt,
                syncVersion: syncVersion,
                clientId: clientId,
                clientChangeId: clientChangeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FeedingTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({petId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (petId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.petId,
                                referencedTable: $$FeedingTableTableReferences
                                    ._petIdTable(db),
                                referencedColumn: $$FeedingTableTableReferences
                                    ._petIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FeedingTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedingTableTable,
      FeedingTableData,
      $$FeedingTableTableFilterComposer,
      $$FeedingTableTableOrderingComposer,
      $$FeedingTableTableAnnotationComposer,
      $$FeedingTableTableCreateCompanionBuilder,
      $$FeedingTableTableUpdateCompanionBuilder,
      (FeedingTableData, $$FeedingTableTableReferences),
      FeedingTableData,
      PrefetchHooks Function({bool petId})
    >;
typedef $$HealthMemoTableTableCreateCompanionBuilder =
    HealthMemoTableCompanion Function({
      Value<int> id,
      required int petId,
      Value<String?> symptom,
      Value<String?> treatment,
      Value<String?> memo,
      required DateTime recordedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$HealthMemoTableTableUpdateCompanionBuilder =
    HealthMemoTableCompanion Function({
      Value<int> id,
      Value<int> petId,
      Value<String?> symptom,
      Value<String?> treatment,
      Value<String?> memo,
      Value<DateTime> recordedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$HealthMemoTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $HealthMemoTableTable,
          HealthMemoTableData
        > {
  $$HealthMemoTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PetTableTable _petIdTable(_$AppDatabase db) =>
      db.petTable.createAlias(
        $_aliasNameGenerator(db.healthMemoTable.petId, db.petTable.id),
      );

  $$PetTableTableProcessedTableManager get petId {
    final $_column = $_itemColumn<int>('pet_id')!;

    final manager = $$PetTableTableTableManager(
      $_db,
      $_db.petTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_petIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HealthMemoTableTableFilterComposer
    extends Composer<_$AppDatabase, $HealthMemoTableTable> {
  $$HealthMemoTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptom => $composableBuilder(
    column: $table.symptom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treatment => $composableBuilder(
    column: $table.treatment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PetTableTableFilterComposer get petId {
    final $$PetTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableFilterComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HealthMemoTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthMemoTableTable> {
  $$HealthMemoTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptom => $composableBuilder(
    column: $table.symptom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treatment => $composableBuilder(
    column: $table.treatment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PetTableTableOrderingComposer get petId {
    final $$PetTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableOrderingComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HealthMemoTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthMemoTableTable> {
  $$HealthMemoTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symptom =>
      $composableBuilder(column: $table.symptom, builder: (column) => column);

  GeneratedColumn<String> get treatment =>
      $composableBuilder(column: $table.treatment, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PetTableTableAnnotationComposer get petId {
    final $$PetTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableAnnotationComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HealthMemoTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthMemoTableTable,
          HealthMemoTableData,
          $$HealthMemoTableTableFilterComposer,
          $$HealthMemoTableTableOrderingComposer,
          $$HealthMemoTableTableAnnotationComposer,
          $$HealthMemoTableTableCreateCompanionBuilder,
          $$HealthMemoTableTableUpdateCompanionBuilder,
          (HealthMemoTableData, $$HealthMemoTableTableReferences),
          HealthMemoTableData,
          PrefetchHooks Function({bool petId})
        > {
  $$HealthMemoTableTableTableManager(
    _$AppDatabase db,
    $HealthMemoTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthMemoTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthMemoTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthMemoTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> petId = const Value.absent(),
                Value<String?> symptom = const Value.absent(),
                Value<String?> treatment = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HealthMemoTableCompanion(
                id: id,
                petId: petId,
                symptom: symptom,
                treatment: treatment,
                memo: memo,
                recordedAt: recordedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int petId,
                Value<String?> symptom = const Value.absent(),
                Value<String?> treatment = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                required DateTime recordedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HealthMemoTableCompanion.insert(
                id: id,
                petId: petId,
                symptom: symptom,
                treatment: treatment,
                memo: memo,
                recordedAt: recordedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HealthMemoTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({petId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (petId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.petId,
                                referencedTable:
                                    $$HealthMemoTableTableReferences
                                        ._petIdTable(db),
                                referencedColumn:
                                    $$HealthMemoTableTableReferences
                                        ._petIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HealthMemoTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthMemoTableTable,
      HealthMemoTableData,
      $$HealthMemoTableTableFilterComposer,
      $$HealthMemoTableTableOrderingComposer,
      $$HealthMemoTableTableAnnotationComposer,
      $$HealthMemoTableTableCreateCompanionBuilder,
      $$HealthMemoTableTableUpdateCompanionBuilder,
      (HealthMemoTableData, $$HealthMemoTableTableReferences),
      HealthMemoTableData,
      PrefetchHooks Function({bool petId})
    >;
typedef $$RoutineTableTableCreateCompanionBuilder =
    RoutineTableCompanion Function({
      Value<int> id,
      required int petId,
      required String routineType,
      required String title,
      required int cycleDays,
      Value<String?> alarmTime,
      Value<bool> isAlarmEnabled,
      Value<DateTime?> lastExecutedAt,
      Value<DateTime?> nextDueAt,
      Value<bool> isActive,
      Value<String?> memo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$RoutineTableTableUpdateCompanionBuilder =
    RoutineTableCompanion Function({
      Value<int> id,
      Value<int> petId,
      Value<String> routineType,
      Value<String> title,
      Value<int> cycleDays,
      Value<String?> alarmTime,
      Value<bool> isAlarmEnabled,
      Value<DateTime?> lastExecutedAt,
      Value<DateTime?> nextDueAt,
      Value<bool> isActive,
      Value<String?> memo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$RoutineTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $RoutineTableTable, RoutineTableData> {
  $$RoutineTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PetTableTable _petIdTable(_$AppDatabase db) => db.petTable
      .createAlias($_aliasNameGenerator(db.routineTable.petId, db.petTable.id));

  $$PetTableTableProcessedTableManager get petId {
    final $_column = $_itemColumn<int>('pet_id')!;

    final manager = $$PetTableTableTableManager(
      $_db,
      $_db.petTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_petIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RoutineLogTableTable, List<RoutineLogTableData>>
  _routineLogTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.routineLogTable,
    aliasName: $_aliasNameGenerator(
      db.routineTable.id,
      db.routineLogTable.routineId,
    ),
  );

  $$RoutineLogTableTableProcessedTableManager get routineLogTableRefs {
    final manager = $$RoutineLogTableTableTableManager(
      $_db,
      $_db.routineLogTable,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _routineLogTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoutineTableTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineTableTable> {
  $$RoutineTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineType => $composableBuilder(
    column: $table.routineType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleDays => $composableBuilder(
    column: $table.cycleDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alarmTime => $composableBuilder(
    column: $table.alarmTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlarmEnabled => $composableBuilder(
    column: $table.isAlarmEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastExecutedAt => $composableBuilder(
    column: $table.lastExecutedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PetTableTableFilterComposer get petId {
    final $$PetTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableFilterComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> routineLogTableRefs(
    Expression<bool> Function($$RoutineLogTableTableFilterComposer f) f,
  ) {
    final $$RoutineLogTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineLogTable,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineLogTableTableFilterComposer(
            $db: $db,
            $table: $db.routineLogTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutineTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineTableTable> {
  $$RoutineTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineType => $composableBuilder(
    column: $table.routineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleDays => $composableBuilder(
    column: $table.cycleDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarmTime => $composableBuilder(
    column: $table.alarmTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlarmEnabled => $composableBuilder(
    column: $table.isAlarmEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastExecutedAt => $composableBuilder(
    column: $table.lastExecutedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PetTableTableOrderingComposer get petId {
    final $$PetTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableOrderingComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineTableTable> {
  $$RoutineTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routineType => $composableBuilder(
    column: $table.routineType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get cycleDays =>
      $composableBuilder(column: $table.cycleDays, builder: (column) => column);

  GeneratedColumn<String> get alarmTime =>
      $composableBuilder(column: $table.alarmTime, builder: (column) => column);

  GeneratedColumn<bool> get isAlarmEnabled => $composableBuilder(
    column: $table.isAlarmEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastExecutedAt => $composableBuilder(
    column: $table.lastExecutedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextDueAt =>
      $composableBuilder(column: $table.nextDueAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PetTableTableAnnotationComposer get petId {
    final $$PetTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableAnnotationComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> routineLogTableRefs<T extends Object>(
    Expression<T> Function($$RoutineLogTableTableAnnotationComposer a) f,
  ) {
    final $$RoutineLogTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routineLogTable,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineLogTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routineLogTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutineTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineTableTable,
          RoutineTableData,
          $$RoutineTableTableFilterComposer,
          $$RoutineTableTableOrderingComposer,
          $$RoutineTableTableAnnotationComposer,
          $$RoutineTableTableCreateCompanionBuilder,
          $$RoutineTableTableUpdateCompanionBuilder,
          (RoutineTableData, $$RoutineTableTableReferences),
          RoutineTableData,
          PrefetchHooks Function({bool petId, bool routineLogTableRefs})
        > {
  $$RoutineTableTableTableManager(_$AppDatabase db, $RoutineTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> petId = const Value.absent(),
                Value<String> routineType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> cycleDays = const Value.absent(),
                Value<String?> alarmTime = const Value.absent(),
                Value<bool> isAlarmEnabled = const Value.absent(),
                Value<DateTime?> lastExecutedAt = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineTableCompanion(
                id: id,
                petId: petId,
                routineType: routineType,
                title: title,
                cycleDays: cycleDays,
                alarmTime: alarmTime,
                isAlarmEnabled: isAlarmEnabled,
                lastExecutedAt: lastExecutedAt,
                nextDueAt: nextDueAt,
                isActive: isActive,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int petId,
                required String routineType,
                required String title,
                required int cycleDays,
                Value<String?> alarmTime = const Value.absent(),
                Value<bool> isAlarmEnabled = const Value.absent(),
                Value<DateTime?> lastExecutedAt = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineTableCompanion.insert(
                id: id,
                petId: petId,
                routineType: routineType,
                title: title,
                cycleDays: cycleDays,
                alarmTime: alarmTime,
                isAlarmEnabled: isAlarmEnabled,
                lastExecutedAt: lastExecutedAt,
                nextDueAt: nextDueAt,
                isActive: isActive,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoutineTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({petId = false, routineLogTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (routineLogTableRefs) db.routineLogTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (petId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.petId,
                                    referencedTable:
                                        $$RoutineTableTableReferences
                                            ._petIdTable(db),
                                    referencedColumn:
                                        $$RoutineTableTableReferences
                                            ._petIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (routineLogTableRefs)
                        await $_getPrefetchedData<
                          RoutineTableData,
                          $RoutineTableTable,
                          RoutineLogTableData
                        >(
                          currentTable: table,
                          referencedTable: $$RoutineTableTableReferences
                              ._routineLogTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoutineTableTableReferences(
                                db,
                                table,
                                p0,
                              ).routineLogTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routineId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RoutineTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineTableTable,
      RoutineTableData,
      $$RoutineTableTableFilterComposer,
      $$RoutineTableTableOrderingComposer,
      $$RoutineTableTableAnnotationComposer,
      $$RoutineTableTableCreateCompanionBuilder,
      $$RoutineTableTableUpdateCompanionBuilder,
      (RoutineTableData, $$RoutineTableTableReferences),
      RoutineTableData,
      PrefetchHooks Function({bool petId, bool routineLogTableRefs})
    >;
typedef $$RoutineLogTableTableCreateCompanionBuilder =
    RoutineLogTableCompanion Function({
      Value<int> id,
      required int routineId,
      required int petId,
      required DateTime executedAt,
      Value<String?> extraData,
      Value<String?> memo,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$RoutineLogTableTableUpdateCompanionBuilder =
    RoutineLogTableCompanion Function({
      Value<int> id,
      Value<int> routineId,
      Value<int> petId,
      Value<DateTime> executedAt,
      Value<String?> extraData,
      Value<String?> memo,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$RoutineLogTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RoutineLogTableTable,
          RoutineLogTableData
        > {
  $$RoutineLogTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RoutineTableTable _routineIdTable(_$AppDatabase db) =>
      db.routineTable.createAlias(
        $_aliasNameGenerator(db.routineLogTable.routineId, db.routineTable.id),
      );

  $$RoutineTableTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$RoutineTableTableTableManager(
      $_db,
      $_db.routineTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PetTableTable _petIdTable(_$AppDatabase db) =>
      db.petTable.createAlias(
        $_aliasNameGenerator(db.routineLogTable.petId, db.petTable.id),
      );

  $$PetTableTableProcessedTableManager get petId {
    final $_column = $_itemColumn<int>('pet_id')!;

    final manager = $$PetTableTableTableManager(
      $_db,
      $_db.petTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_petIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoutineLogTableTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineLogTableTable> {
  $$RoutineLogTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraData => $composableBuilder(
    column: $table.extraData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutineTableTableFilterComposer get routineId {
    final $$RoutineTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routineTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineTableTableFilterComposer(
            $db: $db,
            $table: $db.routineTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PetTableTableFilterComposer get petId {
    final $$PetTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableFilterComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineLogTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineLogTableTable> {
  $$RoutineLogTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraData => $composableBuilder(
    column: $table.extraData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutineTableTableOrderingComposer get routineId {
    final $$RoutineTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routineTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineTableTableOrderingComposer(
            $db: $db,
            $table: $db.routineTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PetTableTableOrderingComposer get petId {
    final $$PetTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableOrderingComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineLogTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineLogTableTable> {
  $$RoutineLogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get executedAt => $composableBuilder(
    column: $table.executedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extraData =>
      $composableBuilder(column: $table.extraData, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RoutineTableTableAnnotationComposer get routineId {
    final $$RoutineTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routineTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutineTableTableAnnotationComposer(
            $db: $db,
            $table: $db.routineTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PetTableTableAnnotationComposer get petId {
    final $$PetTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.petTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetTableTableAnnotationComposer(
            $db: $db,
            $table: $db.petTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutineLogTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineLogTableTable,
          RoutineLogTableData,
          $$RoutineLogTableTableFilterComposer,
          $$RoutineLogTableTableOrderingComposer,
          $$RoutineLogTableTableAnnotationComposer,
          $$RoutineLogTableTableCreateCompanionBuilder,
          $$RoutineLogTableTableUpdateCompanionBuilder,
          (RoutineLogTableData, $$RoutineLogTableTableReferences),
          RoutineLogTableData,
          PrefetchHooks Function({bool routineId, bool petId})
        > {
  $$RoutineLogTableTableTableManager(
    _$AppDatabase db,
    $RoutineLogTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineLogTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineLogTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineLogTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<int> petId = const Value.absent(),
                Value<DateTime> executedAt = const Value.absent(),
                Value<String?> extraData = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineLogTableCompanion(
                id: id,
                routineId: routineId,
                petId: petId,
                executedAt: executedAt,
                extraData: extraData,
                memo: memo,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int routineId,
                required int petId,
                required DateTime executedAt,
                Value<String?> extraData = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoutineLogTableCompanion.insert(
                id: id,
                routineId: routineId,
                petId: petId,
                executedAt: executedAt,
                extraData: extraData,
                memo: memo,
                deletedAt: deletedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoutineLogTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routineId = false, petId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (routineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.routineId,
                                referencedTable:
                                    $$RoutineLogTableTableReferences
                                        ._routineIdTable(db),
                                referencedColumn:
                                    $$RoutineLogTableTableReferences
                                        ._routineIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (petId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.petId,
                                referencedTable:
                                    $$RoutineLogTableTableReferences
                                        ._petIdTable(db),
                                referencedColumn:
                                    $$RoutineLogTableTableReferences
                                        ._petIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RoutineLogTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineLogTableTable,
      RoutineLogTableData,
      $$RoutineLogTableTableFilterComposer,
      $$RoutineLogTableTableOrderingComposer,
      $$RoutineLogTableTableAnnotationComposer,
      $$RoutineLogTableTableCreateCompanionBuilder,
      $$RoutineLogTableTableUpdateCompanionBuilder,
      (RoutineLogTableData, $$RoutineLogTableTableReferences),
      RoutineLogTableData,
      PrefetchHooks Function({bool routineId, bool petId})
    >;
typedef $$PendingOpTableTableCreateCompanionBuilder =
    PendingOpTableCompanion Function({
      Value<int> id,
      required String targetTable,
      required int recordId,
      required String operation,
      required String payload,
      required String clientChangeId,
      Value<int> retryCount,
      Value<DateTime> createdAt,
    });
typedef $$PendingOpTableTableUpdateCompanionBuilder =
    PendingOpTableCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<int> recordId,
      Value<String> operation,
      Value<String> payload,
      Value<String> clientChangeId,
      Value<int> retryCount,
      Value<DateTime> createdAt,
    });

class $$PendingOpTableTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOpTableTable> {
  $$PendingOpTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOpTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOpTableTable> {
  $$PendingOpTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOpTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOpTableTable> {
  $$PendingOpTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get clientChangeId => $composableBuilder(
    column: $table.clientChangeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingOpTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOpTableTable,
          PendingOpTableData,
          $$PendingOpTableTableFilterComposer,
          $$PendingOpTableTableOrderingComposer,
          $$PendingOpTableTableAnnotationComposer,
          $$PendingOpTableTableCreateCompanionBuilder,
          $$PendingOpTableTableUpdateCompanionBuilder,
          (
            PendingOpTableData,
            BaseReferences<
              _$AppDatabase,
              $PendingOpTableTable,
              PendingOpTableData
            >,
          ),
          PendingOpTableData,
          PrefetchHooks Function()
        > {
  $$PendingOpTableTableTableManager(
    _$AppDatabase db,
    $PendingOpTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOpTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOpTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOpTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<int> recordId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> clientChangeId = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingOpTableCompanion(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                payload: payload,
                clientChangeId: clientChangeId,
                retryCount: retryCount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String targetTable,
                required int recordId,
                required String operation,
                required String payload,
                required String clientChangeId,
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingOpTableCompanion.insert(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                operation: operation,
                payload: payload,
                clientChangeId: clientChangeId,
                retryCount: retryCount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOpTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOpTableTable,
      PendingOpTableData,
      $$PendingOpTableTableFilterComposer,
      $$PendingOpTableTableOrderingComposer,
      $$PendingOpTableTableAnnotationComposer,
      $$PendingOpTableTableCreateCompanionBuilder,
      $$PendingOpTableTableUpdateCompanionBuilder,
      (
        PendingOpTableData,
        BaseReferences<_$AppDatabase, $PendingOpTableTable, PendingOpTableData>,
      ),
      PendingOpTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PetTableTableTableManager get petTable =>
      $$PetTableTableTableManager(_db, _db.petTable);
  $$WeightTableTableTableManager get weightTable =>
      $$WeightTableTableTableManager(_db, _db.weightTable);
  $$FeedingTableTableTableManager get feedingTable =>
      $$FeedingTableTableTableManager(_db, _db.feedingTable);
  $$HealthMemoTableTableTableManager get healthMemoTable =>
      $$HealthMemoTableTableTableManager(_db, _db.healthMemoTable);
  $$RoutineTableTableTableManager get routineTable =>
      $$RoutineTableTableTableManager(_db, _db.routineTable);
  $$RoutineLogTableTableTableManager get routineLogTable =>
      $$RoutineLogTableTableTableManager(_db, _db.routineLogTable);
  $$PendingOpTableTableTableManager get pendingOpTable =>
      $$PendingOpTableTableTableManager(_db, _db.pendingOpTable);
}
