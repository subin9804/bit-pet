import 'package:drift/drift.dart';
import 'pet_table.dart';

class RoutineTable extends Table {
  @override
  String get tableName => 'routine_mst';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()(); // v3.1: pet_id → user_id
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

// 루틴-개체 다대다 (routine_pet_rls)
class RoutinePetTable extends Table {
  @override
  String get tableName => 'routine_pet_rls';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer().references(RoutineTable, #id)();
  IntColumn get petId =>
      integer().references(PetTable, #id)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
