import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/community/data/post_repository.dart';
import '../../features/community/data/models/post_models.dart';
import '../../features/notification/data/notification_repository.dart';
import '../../features/notification/data/models/notification_models.dart';
import '../../features/pet/data/pet_repository.dart';
import '../../features/pet/data/models/pet_models.dart';
import '../../features/pet/data/models/photo_models.dart';
import '../../features/pet/data/photo_repository.dart';
import '../../features/record/data/record_repository.dart';
import '../../features/record/data/models/record_models.dart';
import '../../features/routine/data/routine_repository.dart';
import '../../features/routine/data/models/routine_models.dart';
import '../auth/token_storage.dart';

// ────────────────────────────────────────────────────────────────────
// 샘플 데이터
// ────────────────────────────────────────────────────────────────────

const _mockUser = UserProfile(
  id: 1,
  email: 'mock@bitpet.io',
  name: '테스트',
  userType: 'GENERAL',
);

final _mockPets = [
  Pet(
    id: 1,
    serialNo: 'ABC123',
    speciesId: 1,
    speciesName: '볼파이톤',
    name: '까망이',
    gender: 'MALE',
    colorCode: '#3D2B1F',
    latestWeightG: 320.0,
  ),
  Pet(
    id: 2,
    serialNo: 'DEF456',
    speciesId: 2,
    speciesName: '레오파드게코',
    name: '노을이',
    gender: 'FEMALE',
    colorCode: '#E8A87C',
    latestWeightG: 58.5,
    adoptionDate: DateTime(2025, 3, 15),
  ),
  Pet(
    id: 3,
    serialNo: 'GHI789',
    speciesId: 3,
    speciesName: '콘스네이크',
    name: '하양이',
    gender: 'UNKNOWN',
    colorCode: '#F5E6CA',
    latestWeightG: 145.0,
  ),
];

final _mockTodayRoutines = [
  TodayRoutine(
    id: 1,
    title: '주 2회 피딩',
    routineType: RoutineType.FEEDING,
    alarmTime: '09:00',
    isAlarmEnabled: true,
    totalPetCount: 2,
    completedPetCount: 0,
    petStatuses: [
      TodayPetStatus(
        petId: 1,
        petName: '까망이',
        speciesName: '볼파이톤',
        colorCode: '#3D2B1F',
        isCompleted: false,
      ),
      TodayPetStatus(
        petId: 2,
        petName: '노을이',
        speciesName: '레오파드게코',
        colorCode: '#E8A87C',
        isCompleted: false,
      ),
    ],
  ),
  TodayRoutine(
    id: 2,
    title: '케이지 청소',
    routineType: RoutineType.CLEANING,
    alarmTime: '14:00',
    isAlarmEnabled: false,
    totalPetCount: 1,
    completedPetCount: 1,
    petStatuses: [
      TodayPetStatus(
        petId: 3,
        petName: '하양이',
        speciesName: '콘스네이크',
        colorCode: '#F5E6CA',
        isCompleted: true,
      ),
    ],
  ),
];

final _now = DateTime.now();

final _mockRecentRecords = [
  RecentRecord(
    id: 1,
    petName: '까망이',
    colorCode: '#3D2B1F',
    recordType: 'FEEDING',
    summary: '냉동 마우스 1마리 급여 — COMPLETE',
    createdAt: _now.subtract(const Duration(hours: 2)),
  ),
  RecentRecord(
    id: 2,
    petName: '노을이',
    colorCode: '#E8A87C',
    recordType: 'WEIGHT',
    summary: '체중 58.5g',
    createdAt: _now.subtract(const Duration(hours: 5)),
  ),
  RecentRecord(
    id: 3,
    petName: '하양이',
    colorCode: '#F5E6CA',
    recordType: 'CLEANING',
    summary: '전체 청소 완료',
    createdAt: _now.subtract(const Duration(days: 1)),
  ),
];

final _mockRoutines = [
  Routine(
    id: 1,
    userId: 1,
    routineType: RoutineType.FEEDING,
    title: '주 2회 피딩',
    cycleDays: 3,
    alarmTime: '09:00',
    isAlarmEnabled: true,
    isActive: true,
    petIds: [1, 2],
    petCount: 2,
  ),
  Routine(
    id: 2,
    userId: 1,
    routineType: RoutineType.CLEANING,
    title: '케이지 청소',
    cycleDays: 7,
    isAlarmEnabled: false,
    isActive: true,
    petIds: [3],
    petCount: 1,
  ),
  Routine(
    id: 3,
    userId: 1,
    routineType: RoutineType.WEIGHT,
    title: '월 1회 체중 측정',
    cycleDays: 30,
    alarmTime: '10:00',
    isAlarmEnabled: true,
    isActive: true,
    petIds: [1, 2, 3],
    petCount: 3,
  ),
];

final _mockSpecies = [
  Species(id: 1, code: 'BALL_PYTHON', category: '뱀', nameKo: '볼파이톤', nameEn: 'Ball Python'),
  Species(id: 2, code: 'LEOPARD_GECKO', category: '도마뱀', nameKo: '레오파드게코', nameEn: 'Leopard Gecko'),
  Species(id: 3, code: 'CORN_SNAKE', category: '뱀', nameKo: '콘스네이크', nameEn: 'Corn Snake'),
  Species(id: 4, code: 'BEARDED_DRAGON', category: '도마뱀', nameKo: '수염도마뱀', nameEn: 'Bearded Dragon'),
  Species(id: 5, code: 'BLUE_TONGUE_SKINK', category: '도마뱀', nameKo: '블루텅스킨크', nameEn: 'Blue-tongue Skink'),
];

// ────────────────────────────────────────────────────────────────────
// Auth
// ────────────────────────────────────────────────────────────────────

class MockAuthRepository extends AuthRepository {
  MockAuthRepository()
      : super(dio: Dio(), tokenStorage: TokenStorage());

  @override
  Future<bool> get isLoggedIn async => true;

  @override
  Future<UserProfile> login(LoginRequest request) async => _mockUser;

  @override
  Future<UserProfile> signup(SignupRequest request) async => _mockUser;

  @override
  Future<void> logout() async {}

  @override
  Future<void> withdraw() async {}
}

// AuthNotifier를 상속해 곧바로 로그인 상태로 시작
class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier() : super(MockAuthRepository()) {
    // super 생성자의 _init()은 비동기로 state를 null로 설정하므로,
    // 이벤트 루프 다음 틱에 mock 유저로 덮어씀
    Future.delayed(Duration.zero, () {
      if (mounted) state = const AsyncValue.data(_mockUser);
    });
  }
}

// ────────────────────────────────────────────────────────────────────
// Pet
// ────────────────────────────────────────────────────────────────────

class MockPetRepository extends PetRepository {
  MockPetRepository() : super(Dio());

  @override
  Future<List<Pet>> getMyPets() async => List.from(_mockPets);

  @override
  Future<Pet> getPet(int id) async =>
      _mockPets.firstWhere((p) => p.id == id, orElse: () => _mockPets.first);

  @override
  Future<Pet> createPet(CreatePetRequest request) async => Pet(
        id: 99,
        serialNo: 'MOCK01',
        speciesId: request.speciesId,
        speciesName: _mockSpecies
            .firstWhere((s) => s.id == request.speciesId,
                orElse: () => _mockSpecies.first)
            .nameKo,
        name: request.name,
        gender: request.gender,
        colorCode: request.colorCode,
      );

  @override
  Future<Pet> updatePet(int id, Map<String, dynamic> data) async =>
      getPet(id);

  @override
  Future<void> deletePet(int id) async {}

  @override
  Future<List<Species>> getSpecies() async => List.from(_mockSpecies);
}

// ────────────────────────────────────────────────────────────────────
// Record
// ────────────────────────────────────────────────────────────────────

class MockRecordRepository extends RecordRepository {
  MockRecordRepository() : super(Dio());

  @override
  Future<List<WeightRecord>> getWeights(int petId) async => [
        WeightRecord(
          id: 1,
          petId: petId,
          weightG: 320.0,
          measuredAt: _now.subtract(const Duration(days: 3)),
          source: 'MANUAL',
        ),
        WeightRecord(
          id: 2,
          petId: petId,
          weightG: 310.0,
          measuredAt: _now.subtract(const Duration(days: 10)),
          source: 'MANUAL',
        ),
      ];

  @override
  Future<WeightRecord> addWeight(
          int petId, double weightG, DateTime measuredAt, String? memo) async =>
      WeightRecord(
          id: 100,
          petId: petId,
          weightG: weightG,
          measuredAt: measuredAt,
          source: 'MANUAL',
          memo: memo);

  @override
  Future<void> deleteWeight(int id) async {}

  @override
  Future<List<FeedingRecord>> getFeedings(int petId) async => [
        FeedingRecord(
          id: 1,
          petId: petId,
          foodType: '냉동 마우스',
          amount: 1,
          unit: '마리',
          feedResponse: FeedResponse.COMPLETE,
          fedAt: _now.subtract(const Duration(days: 2)),
        ),
      ];

  @override
  Future<FeedingRecord> addFeeding(int petId, Map<String, dynamic> data) async =>
      FeedingRecord(
        id: 100,
        petId: petId,
        foodType: data['foodType'] as String? ?? '기타',
        fedAt: DateTime.now(),
      );

  @override
  Future<List<CleaningRecord>> getCleanings(int petId) async => [
        CleaningRecord(
          id: 1,
          petId: petId,
          cleaningType: CleaningType.FULL,
          cleanedAt: _now.subtract(const Duration(days: 5)),
          createdAt: _now.subtract(const Duration(days: 5)),
        ),
      ];

  @override
  Future<CleaningRecord> addCleaning(
          int petId, CleaningType type, DateTime cleanedAt, String? memo) async =>
      CleaningRecord(
          id: 100,
          petId: petId,
          cleaningType: type,
          cleanedAt: cleanedAt,
          createdAt: DateTime.now());

  @override
  Future<List<MemoTag>> getMemoTags() async => [
        const MemoTag(code: 'VET', labelKo: '병원', displayOrder: 1),
        const MemoTag(code: 'SHED', labelKo: '탈피', displayOrder: 2),
        const MemoTag(code: 'BEHAVIOR', labelKo: '행동', displayOrder: 3),
        const MemoTag(code: 'ETC', labelKo: '기타', displayOrder: 4),
      ];

  @override
  Future<List<Memo>> getMemos(int petId, {int page = 0, int size = 20}) async =>
      [
        Memo(
          id: 1,
          petId: petId,
          content: '탈피 시작한 것 같음. 눈이 뿌옇게 변했어요.',
          loggedAt: _now.subtract(const Duration(days: 2)),
          tags: ['SHED'],
          createdAt: _now.subtract(const Duration(days: 2)),
          updatedAt: _now.subtract(const Duration(days: 2)),
        ),
      ];

  @override
  Future<Memo> addMemo(int petId, Map<String, dynamic> data) async => Memo(
        id: 100,
        petId: petId,
        content: data['content'] as String? ?? '',
        loggedAt: DateTime.now(),
        tags: (data['tags'] as List?)?.cast<String>() ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  @override
  Future<Memo> updateMemo(int memoId, Map<String, dynamic> data) async =>
      addMemo(0, data);

  @override
  Future<void> deleteMemo(int memoId) async {}

  @override
  Future<List<MatingRecord>> getMatings(int petId) async => [];

  @override
  Future<MatingRecord> addMating(
          int petId, Map<String, dynamic> data) async =>
      MatingRecord(id: 100, triedAt: DateTime.now(), createdAt: DateTime.now());

  @override
  Future<void> deleteMating(int matingId) async {}

  @override
  Future<List<LayingRecord>> getLayings(int petId) async => [];

  @override
  Future<LayingRecord> addLaying(
          int petId, Map<String, dynamic> data) async =>
      LayingRecord(
          id: 100,
          petId: petId,
          laidAt: DateTime.now(),
          totalCount: 0,
          hatches: [],
          createdAt: DateTime.now());

  @override
  Future<void> deleteLaying(int layingId) async {}

  @override
  Future<List<CalendarDay>> getCalendar(
      int petId, String yearMonth, List<String> categories) async {
    // 이번 달 mock 달력 데이터
    final now = DateTime.now();
    final ym  = '${now.year}-${now.month.toString().padLeft(2,'0')}';
    if (yearMonth != ym) return [];
    String dayStr(int d) => d.clamp(1, 28).toString().padLeft(2, '0');
    return [
      CalendarDay(date: '$ym-${dayStr(now.day - 4)}',
          categories: ['WEIGHT', 'FEEDING']),
      CalendarDay(date: '$ym-${dayStr(now.day - 1)}',
          categories: ['FEEDING']),
      CalendarDay(date: '$ym-${dayStr(now.day)}',
          categories: ['WEIGHT', 'FEEDING', 'CLEANING']),
    ];
  }

  @override
  Future<List<TimelineItem>> getTimeline(int petId,
      {String? from, String? to, List<String>? categories, int limit = 20}) async {
    final now = DateTime.now();
    // 선택일 필터 (from == to일 때 당일 기록만)
    if (from != null && from == to) {
      final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
      if (from != todayStr) return [];
      return [
        TimelineItem(id: 1, category: 'WEIGHT',
            summary: '${_mockPets[1].latestWeightG?.toStringAsFixed(0)}g 측정',
            recordedAt: now.subtract(const Duration(hours: 3))),
        TimelineItem(id: 2, category: 'FEEDING',
            summary: '귀뚜라미 5마리 · 완식',
            recordedAt: now.subtract(const Duration(hours: 1))),
      ];
    }
    // 요약 카드용 최근 기록
    return [
      TimelineItem(id: 1, category: 'WEIGHT',
          summary: '320g', recordedAt: now.subtract(const Duration(days: 3))),
      TimelineItem(id: 2, category: 'FEEDING',
          summary: '냉동 마우스 1마리', recordedAt: now.subtract(const Duration(days: 2))),
      TimelineItem(id: 3, category: 'CLEANING',
          summary: '전체 청소', recordedAt: now.subtract(const Duration(days: 5))),
      TimelineItem(id: 4, category: 'MEMO',
          summary: '탈피 시작한 것 같음', recordedAt: now.subtract(const Duration(days: 2))),
    ];
  }

  @override
  Future<List<RecentRecord>> getRecentRecords({int limit = 5}) async =>
      List.from(_mockRecentRecords);
}

// ────────────────────────────────────────────────────────────────────
// Routine
// ────────────────────────────────────────────────────────────────────

class MockRoutineRepository extends RoutineRepository {
  MockRoutineRepository() : super(Dio());

  @override
  Future<List<Routine>> getRoutines() async => List.from(_mockRoutines);

  @override
  Future<Routine> getRoutine(int routineId) async =>
      _mockRoutines.firstWhere((r) => r.id == routineId,
          orElse: () => _mockRoutines.first);

  @override
  Future<Routine> createRoutine(CreateRoutineRequest request) async => Routine(
        id: 99,
        userId: 1,
        routineType: request.routineType,
        title: request.title,
        cycleDays: request.cycleDays,
        alarmTime: request.alarmTime,
        isAlarmEnabled: request.alarmEnabled,
        isActive: true,
        petIds: request.petIds,
        petCount: request.petIds.length,
      );

  @override
  Future<Routine> updateRoutine(int routineId, Map<String, dynamic> body) async =>
      getRoutine(routineId);

  @override
  Future<void> deleteRoutine(int routineId) async {}

  @override
  Future<void> subscribePet(int routineId, int petId) async {}

  @override
  Future<void> unsubscribePet(int routineId, int petId) async {}

  @override
  Future<List<int>> getSubscribedPetIds(int routineId) async =>
      _mockRoutines
          .firstWhere((r) => r.id == routineId,
              orElse: () => _mockRoutines.first)
          .petIds;

  @override
  Future<List<RoutineWithSubscription>> getRoutinesForPet(int petId) async =>
      _mockRoutines
          .map((r) => RoutineWithSubscription(
              routine: r, subscribed: r.petIds.contains(petId)))
          .toList();

  @override
  Future<List<RoutineLog>> completeBatch(
          int routineId, RoutineCompleteBatchRequest request) async =>
      [];

  @override
  Future<RoutineLog?> completeIndividual(
          int routineId, RoutineCompleteIndividualRequest request) async =>
      null;

  @override
  Future<List<TodayRoutine>> getTodayRoutines() async =>
      List.from(_mockTodayRoutines);

  @override
  Future<TodayRoutine?> getTodayStatus(int routineId) async =>
      _mockTodayRoutines
          .cast<TodayRoutine?>()
          .firstWhere((r) => r?.id == routineId, orElse: () => null);

  @override
  Future<void> completeAllPetsToday(int routineId) async {}

  @override
  Future<List<RoutineLog>> getLogs(int routineId) async {
    final now = DateTime.now();
    DateTime ago(int days, int hour, int min) =>
        DateTime(now.year, now.month, now.day - days, hour, min);

    // 루틴 id별 현실감 있는 mock 로그 (최신순)
    final logs = <int, List<RoutineLog>>{
      1: [ // 주 2회 피딩
        RoutineLog(id:11, routineId:1, petId:1, status:RoutineLogStatus.COMPLETED, executedAt:ago(2,9,32), memo:'귀뚜라미 5마리 · 완식', createdAt:ago(2,9,32)),
        RoutineLog(id:12, routineId:1, petId:1, status:RoutineLogStatus.COMPLETED, executedAt:ago(5,9,28), memo:'귀뚜라미 5마리 · 1마리 남김', createdAt:ago(5,9,28)),
        RoutineLog(id:13, routineId:1, petId:1, status:RoutineLogStatus.REFUSED,   executedAt:ago(8,9,15), memo:'거부 · 다음날 재시도', createdAt:ago(8,9,15)),
        RoutineLog(id:14, routineId:1, petId:1, status:RoutineLogStatus.COMPLETED, executedAt:ago(12,9,40), memo:'귀뚜라미 5마리 · 완식', createdAt:ago(12,9,40)),
        RoutineLog(id:15, routineId:1, petId:1, status:RoutineLogStatus.COMPLETED, executedAt:ago(15,9,55), memo:'슈퍼웜 2 · 귀뚜라미 3', createdAt:ago(15,9,55)),
      ],
      2: [ // 케이지 청소
        RoutineLog(id:21, routineId:2, petId:3, status:RoutineLogStatus.COMPLETED, executedAt:ago(3,11,20), memo:'바닥재 전체 교체 · 환기', createdAt:ago(3,11,20)),
        RoutineLog(id:22, routineId:2, petId:3, status:RoutineLogStatus.COMPLETED, executedAt:ago(10,11,5), memo:'바닥재 교체', createdAt:ago(10,11,5)),
        RoutineLog(id:23, routineId:2, petId:3, status:RoutineLogStatus.COMPLETED, executedAt:ago(17,11,32), memo:'부분 청소만', createdAt:ago(17,11,32)),
      ],
      3: [ // 월 1회 체중 측정
        RoutineLog(id:31, routineId:3, petId:1, status:RoutineLogStatus.COMPLETED, executedAt:ago(7,19,4), memo:'76g · 전주 대비 +1g', createdAt:ago(7,19,4)),
        RoutineLog(id:32, routineId:3, petId:1, status:RoutineLogStatus.COMPLETED, executedAt:ago(14,19,10), memo:'75g', createdAt:ago(14,19,10)),
        RoutineLog(id:33, routineId:3, petId:2, status:RoutineLogStatus.COMPLETED, executedAt:ago(7,19,8), memo:'320g', createdAt:ago(7,19,8)),
      ],
    };
    return logs[routineId] ?? [];
  }

  @override
  Future<void> deleteLog(int logId) async {}
}

// ────────────────────────────────────────────────────────────────────
// Notification
// ────────────────────────────────────────────────────────────────────

class MockNotificationRepository extends NotificationRepository {
  MockNotificationRepository() : super(Dio());

  @override
  Future<List<NotificationLog>> getNotifications() async => [];

  @override
  Future<NotificationLog> markRead(int notificationId) async =>
      throw UnimplementedError();
}

// ────────────────────────────────────────────────────────────────────
// Community
// ────────────────────────────────────────────────────────────────────

final _mockPosts = [
  Post(
    id: 1,
    userId: 2,
    authorName: '파충류러버',
    categoryCode: 'FREE',
    title: '볼파이톤 처음 키우는데 온도 세팅 어떻게 하시나요?',
    content: '핫스팟 32도, 쿨사이드 26도 정도로 맞추고 있는데 적당한가요?',
    viewCount: 42,
    likeCount: 8,
    commentCount: 3,
    isLiked: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  Post(
    id: 2,
    userId: 3,
    authorName: '레오게코마스터',
    categoryCode: 'SHARE',
    title: '레오파드게코 탈피 성공했어요! 🦎',
    content: '습식 은신처 덕분에 이번에 완벽하게 탈피했습니다. 모두 공유하고 싶었어요.',
    viewCount: 120,
    likeCount: 31,
    commentCount: 7,
    isLiked: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
];

class MockPostRepository extends PostRepository {
  MockPostRepository() : super(Dio());

  @override
  Future<List<Post>> getFeed({String? categoryCode, String? cursor}) async =>
      List.from(_mockPosts);

  @override
  Future<Post> getPost(int id) async =>
      _mockPosts.firstWhere((p) => p.id == id, orElse: () => _mockPosts.first);

  @override
  Future<Post> createPost(CreatePostRequest request) async => Post(
        id: 99,
        userId: 1,
        authorName: '테스트',
        categoryCode: request.categoryCode,
        title: request.title,
        content: request.content,
        viewCount: 0,
        likeCount: 0,
        commentCount: 0,
        isLiked: false,
        createdAt: DateTime.now(),
      );

  @override
  Future<void> deletePost(int id) async {}

  @override
  Future<void> toggleLike(int id, bool currentlyLiked) async {}

  @override
  Future<List<PostComment>> getComments(int postId) async => [
        PostComment(
          id: 1,
          postId: postId,
          userId: 2,
          authorName: '파충류러버',
          content: '저도 비슷하게 세팅했어요. 잘 될 거예요!',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

  @override
  Future<PostComment> addComment(int postId, String content,
          {int? parentCommentId}) async =>
      PostComment(
        id: 99,
        postId: postId,
        userId: 1,
        authorName: '테스트',
        content: content,
        createdAt: DateTime.now(),
      );
}

// ────────────────────────────────────────────────────────────────────
// Photo Mock
// ────────────────────────────────────────────────────────────────────

class MockPhotoRepository extends PhotoRepository {
  MockPhotoRepository() : super(Dio());

  @override
  Future<List<PetPhoto>> getPhotos({
    required String entityType,
    required int entityId,
  }) async => []; // 목 모드에서는 빈 갤러리 표시

  @override
  Future<PetPhoto> uploadPhoto({
    required String entityType,
    required int entityId,
    required String uploadUrl,
    required String key,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deletePhoto(int photoId) async {}
}

// ────────────────────────────────────────────────────────────────────
// Riverpod overrides — main.dart에서 사용
// ────────────────────────────────────────────────────────────────────

List<Override> buildMockOverrides() => [
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      authStateProvider.overrideWith((ref) => MockAuthNotifier()),
      petRepositoryProvider.overrideWithValue(MockPetRepository()),
      recordRepositoryProvider.overrideWithValue(MockRecordRepository()),
      routineRepositoryProvider.overrideWithValue(MockRoutineRepository()),
      notificationRepositoryProvider
          .overrideWithValue(MockNotificationRepository()),
      postRepositoryProvider.overrideWithValue(MockPostRepository()),
      photoRepositoryProvider.overrideWithValue(MockPhotoRepository()),
    ];
