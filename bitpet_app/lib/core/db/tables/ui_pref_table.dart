import 'package:drift/drift.dart';

/// 화면 설정 — **이 기기에만 있는 값이다.**
///
/// 목록을 1열로 볼지 2열로 볼지 같은, "이 사람이 이 폰에서 어떻게 보기로 했는지"가
/// 들어간다. 계정에 묶인 설정이 아니라서 서버로 올리지 않는다 — 태블릿에서 2열,
/// 폰에서 1열이 **정상**이고, 동기화하면 그게 서로를 덮어쓴다.
///
/// 지워져도 잃는 건 마지막으로 고른 보기 방식뿐이고 기본값으로 돌아갈 뿐이다.
/// 그래서 `sync_version` / `client_id` 같은 동기화 컬럼이 없다 (`feed_recent_dtl` 과 같다).
///
/// ⛔ 여기에 토큰·동의 여부처럼 **잃으면 안 되는 것**을 넣지 말 것.
/// 토큰은 `TokenStorage`(flutter_secure_storage), 법적 동의는 서버 원장이 단일 소스다.
class UiPrefTable extends Table {
  @override
  String get tableName => 'ui_pref_dtl';

  /// 설정 키. 값을 꺼낼 때 오타가 나도 조용히 null 이 되므로 상수로만 쓸 것
  /// (`UiPrefKeys`).
  TextColumn get key => text().withLength(max: 100)();

  /// 값은 전부 문자열로 둔다. 타입별 컬럼을 만들면 설정 하나 늘 때마다
  /// 마이그레이션을 쓰게 된다 — 불리언은 `'1'`/`'0'` 으로 적는다.
  TextColumn get value => text().withLength(max: 500)();

  @override
  Set<Column> get primaryKey => {key};
}
