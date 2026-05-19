import 'package:drift/drift.dart';
import 'pet_table.dart';
import 'routine_table.dart';

class RoutineLogTable extends Table {
  @override
  String get tableName => 'routine_log_dtl';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer().references(RoutineTable, #id)();
  IntColumn get petId =>
      integer().references(PetTable, #id)();
  DateTimeColumn get executedAt => dateTime()();
  TextColumn get extraData => text().nullable()(); // JSON
  TextColumn get memo => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
