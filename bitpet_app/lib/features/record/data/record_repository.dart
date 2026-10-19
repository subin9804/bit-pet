import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/record_models.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(ref.watch(dioProvider));
});

/// 목록 응답에서 항목 배열만 꺼낸다.
///
/// 기록 목록 응답에서 배열을 꺼낸다.
///
/// 서버는 이제 **전부 배열을 그대로** 준다(`ApiResponse<List<X>>`). 예전엔 세 모양으로
/// 갈려 있었다 — 배열(weights·cleanings), 직접 만든 래퍼 `{items, totalElements}`
/// (memos·matings), 스프링 `Page` 를 흘린 것 `{content, ...}` (layings). 앱이
/// `as List` 로 단정하는 바람에 뒤 두 경우가 캐스팅에서 터졌고, 그 예외가 화면 전체를
/// 에러 문자열로 덮었다(메이팅·산란 상세가 이 상태였다).
///
/// 서버를 모았으니 첫 분기만으로 충분하지만, 나머지 분기는 **방어막으로 남겨둔다** —
/// 구버전 서버에 붙은 앱이 화면째 깨지는 것보다 조용히 읽히는 쪽이 낫고 비용이 0이다.
List<dynamic> unwrapList(dynamic d) {
  if (d is List) return d;
  if (d is Map<String, dynamic>) {
    final items = d['items'] ?? d['content'];
    if (items is List) return items;
  }
  return const [];
}

class RecordRepository {
  final Dio _dio;
  RecordRepository(this._dio);

  // ── 체중 ──────────────────────────────────────────────────

  Future<List<WeightRecord>> getWeights(int petId) async {
    final res = await _dio.get('/pets/$petId/weights');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<WeightRecord> addWeight(
      int petId, double weightG, DateTime measuredAt, String? memo) async {
    final res = await _dio.post('/pets/$petId/weights', data: {
      'weightG': weightG,
      'measuredAt': measuredAt.toUtc().toIso8601String(),
      if (memo != null) 'memo': memo,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => WeightRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '체중 기록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteWeight(int id) async {
    await _dio.delete('/weights/$id');
  }

  // ── 급여 ──────────────────────────────────────────────────

  Future<List<FeedingRecord>> getFeedings(int petId) async {
    final res = await _dio.get('/pets/$petId/feedings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => FeedingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<FeedingRecord> addFeeding(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/feedings', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => FeedingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '급여 기록 실패');
    }
    return apiRes.data!;
  }

  // ── 청소 ──────────────────────────────────────────────────

  Future<List<CleaningRecord>> getCleanings(int petId) async {
    final res = await _dio.get('/pets/$petId/cleanings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => CleaningRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<void> deleteCleaning(int id) async {
    await _dio.delete('/cleanings/$id');
  }

  Future<CleaningRecord> updateCleaning(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/cleanings/$id', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => CleaningRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: apiRes.message ?? '청소 수정 실패');
    }
    return apiRes.data!;
  }

  Future<CleaningRecord> addCleaning(
      int petId, CleaningType type, DateTime cleanedAt, String? memo) async {
    final res = await _dio.post('/pets/$petId/cleanings', data: {
      'cleaningType': type.name,
      'cleanedAt': cleanedAt.toUtc().toIso8601String(),
      if (memo != null) 'memo': memo,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => CleaningRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '청소 기록 실패');
    }
    return apiRes.data!;
  }

  // ── 메모 (v5) ─────────────────────────────────────────────

  Future<List<MemoTag>> getMemoTags() async {
    final res = await _dio.get('/memo-tags');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => MemoTag.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  // 페이징 파라미터는 없다 — 서버가 전량을 배열로 준다. 예전엔 `page`/`size` 가
  // 있었고 기본이 20이라 메모 캘린더가 **최근 20건만** 들고 있었다(그 이전 달은
  // 기록이 있어도 빈 달로 보였다). 서버 쪽 페이징 자체를 걷어내면서 같이 없앴다.
  Future<List<Memo>> getMemos(int petId) async {
    final res = await _dio.get('/pets/$petId/memos');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => unwrapList(d)
          .map((e) => Memo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<Memo> addMemo(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/memos', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Memo.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '메모 저장 실패');
    }
    return apiRes.data!;
  }

  Future<Memo> updateMemo(int memoId, Map<String, dynamic> data) async {
    final res = await _dio.put('/memos/$memoId', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => Memo.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '메모 수정 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteMemo(int memoId) async {
    await _dio.delete('/memos/$memoId');
  }

  // ── 교배 (v5) ─────────────────────────────────────────────

  Future<List<MatingRecord>> getMatings(int petId) async {
    final res = await _dio.get('/pets/$petId/matings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => unwrapList(d)
          .map((e) => MatingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<MatingRecord> updateMating(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/matings/$id', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => MatingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: apiRes.message ?? '교배 수정 실패');
    }
    return apiRes.data!;
  }

  Future<MatingRecord> addMating(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/matings', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => MatingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '교배 기록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteMating(int matingId) async {
    await _dio.delete('/matings/$matingId');
  }

  // ── 산란 (v5) ─────────────────────────────────────────────

  Future<List<LayingRecord>> getLayings(int petId) async {
    final res = await _dio.get('/pets/$petId/layings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => unwrapList(d)
          .map((e) => LayingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<LayingRecord> updateLaying(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/layings/$id', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => LayingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: apiRes.message ?? '산란 수정 실패');
    }
    return apiRes.data!;
  }

  Future<LayingRecord> addLaying(int petId, Map<String, dynamic> data) async {
    final res = await _dio.post('/pets/$petId/layings', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => LayingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '산란 기록 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteLaying(int layingId) async {
    await _dio.delete('/layings/$layingId');
  }

  /// '내 개체 → 알' 탭 — 내가 돌보는 개체 전체의 클러치. 어미 이름·종·알 칸·메모가
  /// 한 번에 들어오므로 카드마다 개체를 따로 조회하지 않는다.
  Future<List<LayingRecord>> getMyLayings() async {
    final res = await _dio.get('/layings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => unwrapList(d)
          .map((e) => LayingRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<LayingRecord> getLaying(int layingId) async {
    final res = await _dio.get('/layings/$layingId');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => LayingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '클러치 조회 실패');
    }
    return apiRes.data!;
  }

  // ── 알 칸 (해칭) ───────────────────────────────────────────

  /// 알 칸을 누를 때마다 대기 → 부화 → 실패 → 대기 로 돌린다(서버가 돌리는
  /// 세 번째 칸은 SLUG 지만 화면 표기는 '실패' 하나로 합쳤다). 부화일은 서버가
  /// 누른 날로 적는다. 이미 개체로 등록된 알은 서버가 400 으로 막는다.
  Future<HatchRecord> cycleHatch(int layingId, int hatchId) async {
    final res =
        await _dio.post('/layings/$layingId/hatches/$hatchId/cycle');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => HatchRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '알 상태 변경 실패');
    }
    return apiRes.data!;
  }

  /// 롱프레스로 부화일·상태를 직접 고칠 때. [data] 는 `status`/`hatchedAt`/`memo`.
  Future<HatchRecord> updateHatch(
      int layingId, int hatchId, Map<String, dynamic> data) async {
    final res =
        await _dio.put('/layings/$layingId/hatches/$hatchId', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => HatchRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '알 수정 실패');
    }
    return apiRes.data!;
  }

  /// 알 칸은 산란 등록 시 알 개수만큼 서버가 만들어 두므로 보통 쓸 일이 없다.
  /// 나중에 알을 더 발견한 경우를 위해 남겨둔다.
  Future<HatchRecord> addHatch(int layingId, Map<String, dynamic> data) async {
    final res = await _dio.post('/layings/$layingId/hatches', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => HatchRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '알 추가 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteHatch(int layingId, int hatchId) async {
    await _dio.delete('/layings/$layingId/hatches/$hatchId');
  }

  /// 부화한 알을 개체로 등록한다. 이름·성별만 필수고 종·해칭일·부모는 서버가
  /// 클러치에서 채운다. [weightG] 를 보내면 해칭일자 체중 기록도 함께 생긴다.
  /// 반환값은 새 개체 id.
  Future<int> registerPetFromHatch(
    int layingId,
    int hatchId, {
    required String name,
    required String gender,
    double? weightG,
    int? morphId,
    String? memo,
  }) async {
    final res = await _dio.post(
      '/layings/$layingId/hatches/$hatchId/register-pet',
      data: {
        'name': name,
        'gender': gender,
        if (weightG != null) 'weightG': weightG,
        if (morphId != null) 'morphId': morphId,
        if (memo != null && memo.isNotEmpty) 'memo': memo,
      },
    );
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as Map<String, dynamic>)['id'] as int,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '개체 등록 실패');
    }
    return apiRes.data!;
  }

  // ── 클러치 관찰 메모 ──────────────────────────────────────

  Future<List<LayingNote>> getLayingNotes(int layingId) async {
    final res = await _dio.get('/layings/$layingId/notes');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => unwrapList(d)
          .map((e) => LayingNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<LayingNote> addLayingNote(
      int layingId, DateTime notedAt, String content) async {
    final res = await _dio.post('/layings/$layingId/notes', data: {
      'notedAt': _ymd(notedAt),
      'content': content,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => LayingNote.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '메모 저장 실패');
    }
    return apiRes.data!;
  }

  Future<LayingNote> updateLayingNote(
      int layingId, int noteId, DateTime notedAt, String content) async {
    final res = await _dio.put('/layings/$layingId/notes/$noteId', data: {
      'notedAt': _ymd(notedAt),
      'content': content,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => LayingNote.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0, message: apiRes.message ?? '메모 수정 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteLayingNote(int layingId, int noteId) async {
    await _dio.delete('/layings/$layingId/notes/$noteId');
  }

  /// 서버의 `notedAt` 은 `LocalDate` 다 — 타임존이 붙은 문자열을 보내면 날짜가
  /// 하루 밀린다.
  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── 급여 수정/삭제 ──────────────────────────────────────────

  Future<FeedingRecord> updateFeeding(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/feedings/$id', data: data);
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => FeedingRecord.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: apiRes.message ?? '급여 수정 실패');
    }
    return apiRes.data!;
  }

  Future<void> deleteFeeding(int id) async {
    await _dio.delete('/feedings/$id');
  }

  // ── 달력 (v5) ─────────────────────────────────────────────

  Future<List<CalendarDay>> getCalendar(
      int petId, String yearMonth, List<String> categories) async {
    final res = await _dio.get('/pets/$petId/calendar', queryParameters: {
      'yearMonth': yearMonth,
      if (categories.isNotEmpty) 'categories': categories.join(','),
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) {
        final map = d as Map<String, dynamic>;
        return (map['days'] as List)
            .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return apiRes.data ?? [];
  }

  Future<List<CalendarDay>> getHomeCalendar(String yearMonth) async {
    final res = await _dio.get('/calendar',
        queryParameters: {'yearMonth': yearMonth});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) {
        final map = d as Map<String, dynamic>;
        return (map['days'] as List)
            .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return apiRes.data ?? [];
  }

  // ── 타임라인 (v5) ─────────────────────────────────────────

  Future<List<TimelineItem>> getTimeline(
    int petId, {
    String? from,
    String? to,
    List<String>? categories,
    int limit = 20,
  }) async {
    final res = await _dio.get('/pets/$petId/records', queryParameters: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (categories != null && categories.isNotEmpty)
        'categories': categories.join(','),
      'limit': limit,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) {
        final raw = d is Map ? (d['items'] as List? ?? []) : d as List;
        return raw.map((e) => TimelineItem.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
    return apiRes.data ?? [];
  }

  // ── 홈 최근 기록 ──────────────────────────────────────────

  Future<List<RecentRecord>> getRecordsByDate(String date) async {
    final res = await _dio.get('/records', queryParameters: {'date': date});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => RecentRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  // ── 홈 캘린더 날짜 시트 — 일괄 작업 ─────────────────────────
  // 서버 한 트랜잭션이다: 하나라도 실패하면 아무것도 안 바뀐다.

  static List<Map<String, dynamic>> _bulkItems(Iterable<RecentRecord> recs) =>
      recs.map((r) => {'recordType': r.recordType, 'id': r.id}).toList();

  Future<void> bulkDeleteRecords(Iterable<RecentRecord> recs) async {
    await _dio.post('/records/bulk-delete', data: {'items': _bulkItems(recs)});
  }

  /// 날짜만 [date] 로 옮긴다. 기록한 시각은 서버가 그대로 둔다.
  Future<void> bulkMoveRecords(Iterable<RecentRecord> recs, DateTime date) async {
    await _dio.post('/records/bulk-move', data: {
      'items': _bulkItems(recs),
      'date': _ymd(date),
    });
  }

  Future<List<RecentRecord>> getRecentRecords({int limit = 5}) async {
    final res = await _dio.get('/records/recent',
        queryParameters: {'limit': limit});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => RecentRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }
}
