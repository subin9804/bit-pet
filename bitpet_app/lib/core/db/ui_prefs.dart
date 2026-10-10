import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// 설정 키 모음. 문자열을 호출부에 직접 적으면 오타가 **조용히 기본값으로 떨어진다**
/// (없는 키는 null 이고 null 은 기본값이라 아무도 눈치채지 못한다).
abstract final class UiPrefKeys {
  /// 내 개체 목록 보기 방식 — `'grid'`(2열) / `'list'`(1열).
  static const petListView = 'pet_list_view';

  /// 소개 3장을 봤는지. 기기에만 있으므로 **재설치하면 다시 본다** — 그래도
  /// 괜찮은 종류의 값이다 (동의 여부처럼 잃으면 안 되는 것은 여기 넣지 말 것).
  static const introSeen = 'intro_seen';
}

/// 화면 설정 읽기·쓰기. 값은 전부 문자열이다 (`ui_pref_dtl` 주석 참고).
class UiPrefs {
  final AppDatabase _db;

  UiPrefs(this._db);

  Future<String?> read(String key) async {
    final row = await (_db.select(_db.uiPrefTable)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) =>
      _db.into(_db.uiPrefTable).insertOnConflictUpdate(
            UiPrefTableData(key: key, value: value),
          );

  Future<bool?> readBool(String key) async {
    final v = await read(key);
    if (v == null) return null;
    return v == '1';
  }

  Future<void> writeBool(String key, bool value) =>
      write(key, value ? '1' : '0');
}

final uiPrefsProvider = Provider<UiPrefs>((ref) => UiPrefs(ref.watch(dbProvider)));

/// 기기에 남는 불리언 설정 하나를 들고 있는 상태.
///
/// **읽기는 비동기인데 화면은 지금 당장 그려야 한다.** 그래서 기본값으로 시작해
/// 저장된 값이 오면 갈아끼운다 — 목록이 한 프레임 동안 기본 보기로 보일 수 있지만,
/// 설정을 기다리느라 화면 전체를 로딩으로 덮는 것보다 낫다.
///
/// 쓰기는 **낙관적**이다. 화면을 먼저 바꾸고 저장은 뒤따라간다. 저장이 실패해도
/// 되돌리지 않는다 — 보기 방식은 다음에 다시 누르면 되는 값이고, 버튼을 눌렀는데
/// 화면이 안 바뀌는 쪽이 훨씬 나쁘다.
class UiBoolPref extends StateNotifier<bool> {
  final UiPrefs _prefs;
  final String _key;

  UiBoolPref(this._prefs, this._key, bool initial) : super(initial) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _prefs.readBool(_key);
    if (saved != null && saved != state) state = saved;
  }

  void set(bool value) {
    state = value;
    _prefs.writeBool(_key, value);
  }

  void toggle() => set(!state);
}

/// 내 개체 목록을 2열(`true`)로 볼지 1열(`false`)로 볼지.
///
/// 기본값은 2열이다 — 지금까지의 동작이라 처음 켠 사람에게는 달라지는 게 없다.
final petListGridProvider = StateNotifierProvider<UiBoolPref, bool>(
  (ref) => UiBoolPref(
    ref.watch(uiPrefsProvider),
    UiPrefKeys.petListView,
    true,
  ),
);
