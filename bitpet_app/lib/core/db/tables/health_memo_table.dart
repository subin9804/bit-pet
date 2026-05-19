import 'package:drift/drift.dart';
import 'pet_table.dart';

class HealthMemoTable extends Table {
  @override
  String get tableName => 'health_memo_dtl';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(PetTable, #id)();
  TextColumn get symptom => text().nullable()();
  TextColumn get treatment => text().nullable()();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
