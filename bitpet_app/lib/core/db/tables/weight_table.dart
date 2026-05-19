import 'package:drift/drift.dart';
import 'pet_table.dart';

class WeightTable extends Table {
  @override
  String get tableName => 'weight_dtl';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(PetTable, #id)();
  RealColumn get weightG => real()();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get source =>
      text().withDefault(const Constant('MANUAL'))();
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
