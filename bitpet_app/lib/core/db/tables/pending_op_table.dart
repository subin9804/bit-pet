import 'package:drift/drift.dart';

// 오프라인 sync 큐 — 서버에 아직 전송 안 된 변경 사항 보관
class PendingOpTable extends Table {
  @override
  String get tableName => '_pending_ops';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()(); // 대상 테이블명
  IntColumn get recordId => integer()();
  TextColumn get operation => text()(); // INSERT / UPDATE / DELETE
  TextColumn get payload => text()(); // JSON
  TextColumn get clientChangeId => text()();
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
