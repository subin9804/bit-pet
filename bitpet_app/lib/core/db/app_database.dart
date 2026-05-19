import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/pet_table.dart';
import 'tables/weight_table.dart';
import 'tables/feeding_table.dart';
import 'tables/health_memo_table.dart';
import 'tables/routine_table.dart';
import 'tables/routine_log_table.dart';
import 'tables/pending_op_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  PetTable,
  WeightTable,
  FeedingTable,
  HealthMemoTable,
  RoutineTable,
  RoutineLogTable,
  PendingOpTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
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
