import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'food_catalog.dart';
import 'models/feed_models.dart';
import 'models/record_models.dart';

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

// ── 실서버 구현 ───────────────────────────────────────────────
// 백엔드 feeding_dtl (1행 = 1먹이)을 FeedSession (1세션 = N먹이)으로 매핑.
// 현재 백엔드가 단일 foodType 구조이므로 각 레코드를 단일-아이템 세션으로 변환.
class DioFeedRepository implements FeedRepository {
  final Dio _dio;
  DioFeedRepository(this._dio);

  // FeedingRecord → FeedSession 변환
  static FeedSession _toSession(FeedingRecord r) {
    final dt = r.fedAt;
    return FeedSession(
      id: r.id.toString(),
      date: '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
      time: '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
      items: [FeedItem(food: FoodType.labelForCode(r.foodType), amt: r.amount?.toInt() ?? 1)],
      memo: r.memo ?? '',
    );
  }

  @override
  Future<List<FeedSession>> getSessions(int petId) async {
    final res = await _dio.get('/pets/$petId/feedings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => FeedingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return (apiRes.data ?? []).map(_toSession).toList();
  }

  @override
  Future<FeedSession> addSession(int petId, FeedSession session) async {
    // 다중 아이템일 경우 첫 번째 아이템으로 대표 등록
    // TODO: 백엔드가 멀티 아이템 지원 시 반복 POST 또는 스키마 변경
    final item = session.items.isNotEmpty
        ? session.items.first
        : const FeedItem(food: '귀뚜라미', amt: 1);
    final fedAt = DateTime.parse(
        '${session.date}T${session.time.length == 5 ? "${session.time}:00" : session.time}');
    final res = await _dio.post('/pets/$petId/feedings', data: {
      'foodType': FoodType.codeForLabel(item.food),
      'amount': item.amt.toDouble(),
      'unit': '마리',
      'fedAt': fedAt.toIso8601String(),
      if (session.memo.isNotEmpty) 'memo': session.memo,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => FeedingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '급여 기록 실패');
    }
    return _toSession(apiRes.data!);
  }

  @override
  Future<FeedSession> updateSession(int petId, FeedSession session) async {
    final item = session.items.isNotEmpty ? session.items.first : const FeedItem(food: '귀뚜라미', amt: 1);
    final fedAt = DateTime.parse(
        '${session.date}T${session.time.length == 5 ? "${session.time}:00" : session.time}');
    final res = await _dio.patch('/feedings/${session.id}', data: {
      'foodType': FoodType.codeForLabel(item.food),
      'amount': item.amt.toDouble(),
      'fedAt': fedAt.toIso8601String(),
      'memo': session.memo,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => FeedingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '급여 수정 실패');
    }
    return _toSession(apiRes.data!);
  }

  @override
  Future<void> deleteSession(int petId, String sessionId) async {
    await _dio.delete('/feedings/$sessionId');
  }
}
