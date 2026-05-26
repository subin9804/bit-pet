import 'package:drift/drift.dart';
import 'pet_table.dart';

/// 메모 기록 (서버 memo_dtl 대응 — v5 이후)
class MemoTable extends Table {
  @override
  String get tableName => 'memo_dtl';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId => integer().references(PetTable, #id)();
  TextColumn get content => text()();
  DateTimeColumn get loggedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
