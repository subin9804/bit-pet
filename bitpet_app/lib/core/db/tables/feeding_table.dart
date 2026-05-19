import 'package:drift/drift.dart';
import 'pet_table.dart';

class FeedingTable extends Table {
  @override
  String get tableName => 'feeding_dtl';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(PetTable, #id)();
  IntColumn get routineId => integer().nullable()();
  TextColumn get foodType => text().withLength(max: 50)();
  RealColumn get amount => real().nullable()();
  TextColumn get unit => text().nullable()();
  // COMPLETE / PARTIAL / REFUSED
  TextColumn get feedResponse => text().nullable()();
  DateTimeColumn get fedAt => dateTime()();
  TextColumn get memo => text().nullable()();
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
