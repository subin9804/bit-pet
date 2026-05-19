import 'package:drift/drift.dart';
import 'pet_table.dart';

class RoutineTable extends Table {
  @override
  String get tableName => 'routine_mst';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(PetTable, #id)();
  // FEEDING / CLEANING / WEIGHT / CUSTOM
  TextColumn get routineType => text()();
  TextColumn get title => text().withLength(max: 100)();
  IntColumn get cycleDays => integer()();
  TextColumn get alarmTime => text().nullable()(); // HH:mm
  BoolColumn get isAlarmEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastExecutedAt => dateTime().nullable()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
