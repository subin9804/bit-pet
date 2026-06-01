// 급여 기록 Repository — 추상 인터페이스 + 로컬 Mock 구현
// 추후 DioFeedRepository(Dio) 로 교체

import 'models/feed_models.dart';

abstract class FeedRepository {
  Future<List<FeedSession>> getSessions(int petId);
  Future<FeedSession> addSession(int petId, FeedSession session);
  Future<FeedSession> updateSession(int petId, FeedSession session);
  Future<void> deleteSession(int petId, String sessionId);
}

// ── 로컬 Mock (feed-data.json 의 37개 세션 하드코딩) ──────────
class MockFeedRepository implements FeedRepository {
  // feed-data.json 의 sessions 배열 복사 (godo pet 기준)
  static final List<FeedSession> _seed = [
    FeedSession(id:'s37',date:'2025-12-24',time:'21:30',items:[const FeedItem(food:'귀뚜라미',amt:3)],memo:'2마리 남김 · 식욕 떨어짐'),
    FeedSession(id:'s36',date:'2025-12-21',time:'21:10',items:[const FeedItem(food:'귀뚜라미',amt:4)],memo:''),
    FeedSession(id:'s35',date:'2025-12-18',time:'20:50',items:[const FeedItem(food:'슈퍼웜',amt:3)],memo:''),
    FeedSession(id:'s34',date:'2025-12-15',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:4),const FeedItem(food:'버터웜',amt:1)],memo:'칼슘 더스팅'),
    FeedSession(id:'s33',date:'2025-12-11',time:'20:40',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:''),
    FeedSession(id:'s32',date:'2025-12-08',time:'21:20',items:[const FeedItem(food:'밀웜',amt:6)],memo:'완식'),
    FeedSession(id:'s31',date:'2025-12-04',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:''),
    FeedSession(id:'s30',date:'2025-12-01',time:'20:30',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:'완식'),
    FeedSession(id:'s29',date:'2025-11-27',time:'21:10',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:''),
    FeedSession(id:'s28',date:'2025-11-23',time:'20:50',items:[const FeedItem(food:'슈퍼웜',amt:3)],memo:''),
    FeedSession(id:'s27',date:'2025-11-19',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:6),const FeedItem(food:'버터웜',amt:1)],memo:'더스팅'),
    FeedSession(id:'s26',date:'2025-11-15',time:'20:40',items:[const FeedItem(food:'버터웜',amt:4)],memo:''),
    FeedSession(id:'s25',date:'2025-11-11',time:'21:20',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:'완식'),
    FeedSession(id:'s24',date:'2025-11-07',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:''),
    FeedSession(id:'s23',date:'2025-11-03',time:'20:30',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:'완식'),
    FeedSession(id:'s22',date:'2025-10-29',time:'21:10',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:''),
    FeedSession(id:'s21',date:'2025-10-25',time:'20:50',items:[const FeedItem(food:'귀뚜라미',amt:6),const FeedItem(food:'슈퍼웜',amt:1)],memo:''),
    FeedSession(id:'s20',date:'2025-10-21',time:'21:00',items:[const FeedItem(food:'버터웜',amt:4)],memo:'더스팅'),
    FeedSession(id:'s19',date:'2025-10-17',time:'20:40',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:''),
    FeedSession(id:'s18',date:'2025-10-13',time:'21:20',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:'완식'),
    FeedSession(id:'s17',date:'2025-10-09',time:'21:00',items:[const FeedItem(food:'슈퍼웜',amt:3)],memo:''),
    FeedSession(id:'s16',date:'2025-10-05',time:'20:30',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:''),
    FeedSession(id:'s15',date:'2025-10-01',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:'완식'),
    FeedSession(id:'s14',date:'2025-09-27',time:'21:10',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:''),
    FeedSession(id:'s13',date:'2025-09-23',time:'20:50',items:[const FeedItem(food:'밀웜',amt:5)],memo:''),
    FeedSession(id:'s12',date:'2025-09-19',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:6),const FeedItem(food:'버터웜',amt:1)],memo:'더스팅'),
    FeedSession(id:'s11',date:'2025-09-15',time:'20:40',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:''),
    FeedSession(id:'s10',date:'2025-09-11',time:'21:20',items:[const FeedItem(food:'슈퍼웜',amt:3)],memo:'완식'),
    FeedSession(id:'s9', date:'2025-09-07',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:''),
    FeedSession(id:'s8', date:'2025-09-03',time:'20:30',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:'완식'),
    FeedSession(id:'s7', date:'2025-08-30',time:'21:10',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:''),
    FeedSession(id:'s6', date:'2025-08-26',time:'20:50',items:[const FeedItem(food:'버터웜',amt:4)],memo:''),
    FeedSession(id:'s5', date:'2025-08-22',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:'완식'),
    FeedSession(id:'s4', date:'2025-08-18',time:'20:40',items:[const FeedItem(food:'슈퍼웜',amt:3)],memo:''),
    FeedSession(id:'s3', date:'2025-08-14',time:'21:20',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:''),
    FeedSession(id:'s2', date:'2025-08-10',time:'21:00',items:[const FeedItem(food:'귀뚜라미',amt:6)],memo:'완식'),
    FeedSession(id:'s1', date:'2025-08-06',time:'20:30',items:[const FeedItem(food:'귀뚜라미',amt:5)],memo:''),
  ];

  // petId 무관하게 동일 mock 데이터 반환 (현재는 godo 단일 pet 기준)
  final Map<int, List<FeedSession>> _store = {};
  int _nextSeq = 1000;

  @override
  Future<List<FeedSession>> getSessions(int petId) async {
    _store.putIfAbsent(petId, () => List.from(_seed));
    return List.from(_store[petId]!);
  }

  @override
  Future<FeedSession> addSession(int petId, FeedSession session) async {
    await getSessions(petId); // ensure initialized
    final newSession = FeedSession(
      id: 's${_nextSeq++}',
      date: session.date, time: session.time,
      items: session.items, memo: session.memo,
    );
    _store[petId]!.add(newSession);
    return newSession;
  }

  @override
  Future<FeedSession> updateSession(int petId, FeedSession session) async {
    await getSessions(petId);
    final idx = _store[petId]!.indexWhere((s) => s.id == session.id);
    if (idx >= 0) _store[petId]![idx] = session;
    return session;
  }

  @override
  Future<void> deleteSession(int petId, String sessionId) async {
    await getSessions(petId);
    _store[petId]!.removeWhere((s) => s.id == sessionId);
  }
}
