import 'package:drift/drift.dart';

class PetTable extends Table {
  @override
  String get tableName => 'pet_mst';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get serialNo => text().withLength(min: 6, max: 8)();
  IntColumn get userId => integer()();
  IntColumn get speciesId => integer()();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get gender =>
      text().withDefault(const Constant('UNKNOWN'))();
  IntColumn get morphId => integer().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get colorCode => text().nullable()();
  TextColumn get environmentMemo => text().nullable()();
  DateTimeColumn get breedingDate => dateTime().nullable()();
  DateTimeColumn get hatchingDate => dateTime().nullable()();
  DateTimeColumn get adoptionDate => dateTime().nullable()();
  IntColumn get profilePhotoId => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncVersion =>
      integer().withDefault(const Constant(1))();
  TextColumn get clientId => text().nullable()();
  TextColumn get clientChangeId => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
