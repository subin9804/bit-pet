import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/pet_table.dart';
import 'tables/weight_table.dart';
import 'tables/feeding_table.dart';
import 'tables/memo_table.dart';
import 'tables/routine_table.dart';
import 'tables/routine_log_table.dart';
import 'tables/pending_op_table.dart';
import 'tables/feed_recent_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  PetTable,
  WeightTable,
  FeedingTable,
  MemoTable,
  RoutineTable,
  RoutinePetTable,
  RoutineLogTable,
  PendingOpTable,
  FeedRecentTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: RoutinePetTable 신설 + RoutineLogTable.status 컬럼 추가
          if (from < 2) {
            await m.createTable(routinePetTable);
            await m.addColumn(routineLogTable, routineLogTable.status);
          }
          // v2 → v3: health_memo_dtl → memo_dtl (v5 서버 마이그레이션 V15 대응)
          if (from < 3) {
            await customStatement('DROP TABLE IF EXISTS health_memo_dtl');
            await m.createTable(memoTable);
          }
          // v3 → v4: memo_dtl.routine_id 추가 (서버 V36 마이그레이션 대응)
          if (from < 4) {
            await customStatement('ALTER TABLE memo_dtl ADD COLUMN routine_id INTEGER');
          }
          // v4 → v5: feed_recent_dtl 신설 (개체별 최근 급여 조합 — 기기 로컬 캐시).
          // 서버 스키마와 무관하다. 기록이 아니라 단축키라서 마이그레이션에서
          // 채워넣을 과거 데이터도 없다 — 빈 테이블로 시작해 쓰는 대로 쌓인다.
          if (from < 5) {
            await m.createTable(feedRecentTable);
          }
        },
        beforeOpen: (details) async {
          // SQLite 외래키 제약 활성화
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'bitpet.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// main.dart에서 ProviderScope override로 주입
final dbProvider = Provider<AppDatabase>((_) => throw UnimplementedError());
