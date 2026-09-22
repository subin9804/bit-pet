// 개체별 최근 급여 조합 — 기기 로컬 캐시(`feed_recent_dtl`).
//
// 사육은 같은 걸 반복해서 준다. 어제 준 걸 오늘도 주는 게 보통인데, 그때마다
// 모달을 열어 종류 → 사이즈 → 마릿수를 다시 고르게 하는 건 이미 아는 답을 다시
// 묻는 것이다. 최근 조합을 칩으로 내주면 그 경로가 **한 번의 탭**으로 끝난다.
//
// ⛔ 서버에 묻지 않는다. 이건 기록이 아니라 단축키라서, 왕복이 필요한 순간
// (시트가 열리는 바로 그 순간) 값이 늦게 오면 칩이 뒤늦게 튀어나와 레이아웃이
// 흔들린다. 기기에만 두면 즉시 그릴 수 있고, 지워져도 잃는 게 없다.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'food_catalog.dart';

/// 최근 칩에 몇 개를 보여줄지. 세 개는 한 줄에 들어가는 최대치이기도 하다 —
/// 최근 조합이 두 줄을 먹으면 그게 목록처럼 읽혀서 "고르는 자리"가 두 개가 된다.
const int kRecentFeedLimit = 3;

class FeedRecentRepository {
  final AppDatabase _db;
  FeedRecentRepository(this._db);

  /// 같은 조합인지 판정하는 키. 메모·거식은 들어가지 않는다 —
  /// 메모는 매번 다른 내용이고, 거식은 먹이 조합이 아예 없는 기록이다.
  static String signatureOf(FeedFormData f) => [
        f.foodType?.code ?? '',
        f.sizeLabel ?? '',
        f.count?.toString() ?? '',
        f.mlAmount?.toString() ?? '',
        f.useMl ? '1' : '0',
        f.useCustomAmount ? '1' : '0',
        f.customText?.trim() ?? '',
        f.supplement?.name ?? '',
      ].join('|');

  Future<List<FeedFormData>> recent(int petId) async {
    final rows = await (_db.select(_db.feedRecentTable)
          ..where((t) => t.petId.equals(petId))
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])
          ..limit(kRecentFeedLimit))
        .get();
    return rows.map(_toForm).toList();
  }

  /// 담긴 조합을 기억한다. 같은 조합이면 새 행 대신 시각만 올린다.
  ///
  /// 거식과 유효하지 않은 폼은 무시한다 — 거식은 "무엇을 줬나"가 없어서
  /// 칩으로 다시 꺼낼 게 없고, 그 자리는 세그먼트가 이미 한 번의 탭으로 준다.
  Future<void> remember(int petId, FeedFormData form) async {
    if (form.isRefused || !form.isValid || form.foodType == null) return;

    final sig = signatureOf(form);
    final now = DateTime.now();

    await _db.into(_db.feedRecentTable).insert(
          FeedRecentTableCompanion.insert(
            petId: petId,
            signature: sig,
            foodType: form.foodType!.code,
            feedCount: Value(form.count),
            sizeLabel: Value(form.sizeLabel),
            mlAmount: Value(form.mlAmount),
            useMl: Value(form.useMl),
            useCustomAmount: Value(form.useCustomAmount),
            customText: Value(form.customText),
            supplement: Value(form.supplement?.name),
            lastUsedAt: now,
          ),
          // (petId, signature) 유니크에 걸리면 시각만 갱신한다.
          onConflict: DoUpdate(
            (_) => FeedRecentTableCompanion(lastUsedAt: Value(now)),
            target: [_db.feedRecentTable.petId, _db.feedRecentTable.signature],
          ),
        );

    await _trim(petId);
  }

  /// 개체당 보관 수를 제한한다. 안 하면 조합이 바뀔 때마다 행이 무한히 쌓인다
  /// (보이는 건 3개뿐이라 커지는 게 눈에 띄지도 않는다).
  /// 보여주는 것보다 넉넉히 두는 건, 어제 조합이 오늘 하루치에 밀려 사라지지 않게 하려는 것이다.
  static const int _keep = 12;

  Future<void> _trim(int petId) async {
    final rows = await (_db.select(_db.feedRecentTable)
          ..where((t) => t.petId.equals(petId))
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)]))
        .get();
    if (rows.length <= _keep) return;
    final doomed = rows.skip(_keep).map((r) => r.id).toList();
    await (_db.delete(_db.feedRecentTable)..where((t) => t.id.isIn(doomed))).go();
  }

  FeedFormData _toForm(FeedRecentTableData r) => FeedFormData(
        foodType: FoodType.byCodeOrCustom(r.foodType),
        count: r.feedCount,
        sizeLabel: r.sizeLabel,
        mlAmount: r.mlAmount,
        useMl: r.useMl,
        useCustomAmount: r.useCustomAmount,
        customText: r.customText,
        supplement: _supplementOf(r.supplement),
      );

  /// 모르는 이름이면 null. 영양제 enum 이 줄어드는 일은 없겠지만, 캐시는 앱보다
  /// 오래 살아남는 데이터라 옛 값이 들어 있어도 터지지 않아야 한다.
  static FeedingSupplement? _supplementOf(String? name) {
    if (name == null) return null;
    for (final s in FeedingSupplement.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

final feedRecentRepositoryProvider = Provider<FeedRecentRepository>(
  (ref) => FeedRecentRepository(ref.watch(dbProvider)),
);

/// 개체별 최근 조합. 담을 때마다 `ref.invalidate` 로 다시 읽는다.
final recentFeedsProvider =
    FutureProvider.family<List<FeedFormData>, int>((ref, petId) {
  return ref.watch(feedRecentRepositoryProvider).recent(petId);
});
