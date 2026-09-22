import 'package:drift/drift.dart';

/// 개체별 최근 급여 조합 — **이 기기에만 있는 캐시다.**
///
/// 기록 원본이 아니다. 지워져도 잃는 건 "지난번에 뭘 줬더라"의 단축키뿐이고,
/// 급여 기록 자체는 서버(`feeding_dtl`)에 있다. 그래서 동기화 대상이 아니고
/// `sync_version` / `client_id` 같은 컬럼도 없다.
///
/// ⛔ 개체(`pet_mst`)로 FK 를 걸지 말 것. `PRAGMA foreign_keys = ON` 인데 로컬
/// `pet_mst` 는 오프라인 캐시라 비어 있을 수 있다 — 걸어두면 개체가 로컬에
/// 없는 상태에서 급여를 담을 때마다 INSERT 가 터진다.
class FeedRecentTable extends Table {
  @override
  String get tableName => 'feed_recent_dtl';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId => integer()();

  /// 같은 조합인지 판정하는 키. 아래 값들을 이어붙인 문자열이다.
  /// 이게 같으면 새 행을 만들지 않고 [lastUsedAt] 만 올린다 — 같은 걸 열 번 줬다고
  /// 최근 칩 세 칸이 같은 먹이로 채워지면 칩의 값어치가 없다.
  TextColumn get signature => text().withLength(max: 200)();

  TextColumn get foodType => text().withLength(max: 50)();
  IntColumn get feedCount => integer().nullable()();
  TextColumn get sizeLabel => text().nullable()();
  RealColumn get mlAmount => real().nullable()();
  BoolColumn get useMl => boolean().withDefault(const Constant(false))();
  BoolColumn get useCustomAmount => boolean().withDefault(const Constant(false))();
  TextColumn get customText => text().nullable()();
  TextColumn get supplement => text().nullable()();

  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {petId, signature},
      ];
}
