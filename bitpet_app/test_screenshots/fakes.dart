// 스크린샷용 가짜 저장소 — 서버·기기 저장소 없이 화면이 뜨도록 응답을 고정한다.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bitpet_app/core/api/api_client.dart';
import 'package:bitpet_app/core/auth/token_storage.dart';
import 'package:bitpet_app/core/db/ui_prefs.dart';
import 'package:bitpet_app/core/push/push_service.dart';
import 'package:bitpet_app/core/upload/image_upload.dart';
import 'package:bitpet_app/features/auth/data/auth_repository.dart';
import 'package:bitpet_app/features/auth/data/models/auth_models.dart';
import 'package:bitpet_app/features/community/data/models/post_models.dart';
import 'package:bitpet_app/features/community/data/post_repository.dart';
import 'package:bitpet_app/features/notification/providers/notification_provider.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/data/pet_repository.dart';

const kMe = UserProfile(
  id: 1,
  email: 'me@tailog.app',
  name: '도마뱀집사',
  userType: 'USER',
);

class FakeAuthRepo extends AuthRepository {
  FakeAuthRepo()
      : super(dio: Dio(), tokenStorage: TokenStorage(), uploader: ImageUploadService());

  @override
  Future<bool> get isLoggedIn async => true;

  @override
  Future<UserProfile> getMe() async => kMe;

  @override
  Future<({bool needs, bool ageUnchecked})> needsAgreement() async =>
      (needs: false, ageUnchecked: false);
}

class FakePush extends PushService {
  FakePush(super.ref);
  @override
  Future<void> initialize() async {}
}

class FakePostRepo extends PostRepository {
  final List<PostCategory> categories;
  final List<Post> feed;
  final Map<int, Post> posts;
  final Map<int, List<PostComment>> comments;

  FakePostRepo({
    this.categories = const [],
    this.feed = const [],
    this.posts = const {},
    this.comments = const {},
  }) : super(Dio(), ImageUploadService());

  @override
  Future<List<PostCategory>> getCategories() async => categories;

  @override
  Future<FeedPage> getFeed({int? categoryId, int? cursor, int size = 20}) async =>
      FeedPage(
        items: categoryId == null
            ? feed
            : feed.where((p) => p.categoryId == categoryId).toList(),
        nextCursor: null,
      );

  @override
  Future<Post> getPost(int id) async => posts[id]!;

  @override
  Future<List<PostComment>> getComments(int postId) async =>
      comments[postId] ?? const [];
}

class FakePetRepo extends PetRepository {
  final List<Pet> pets;
  FakePetRepo(this.pets) : super(Dio());

  @override
  Future<List<Pet>> getMyPets() async => pets;
}

class FakeUiPrefs implements UiPrefs {
  final _m = <String, String>{};
  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
  @override
  Future<bool?> readBool(String key) async {
    final v = _m[key];
    return v == null ? null : v == '1';
  }
  @override
  Future<void> writeBool(String key, bool value) => write(key, value ? '1' : '0');
}

/// 로그인된 '나' + 알림 없음 + 기기 저장소 없음
List<Override> loggedIn() => [
      authRepositoryProvider.overrideWithValue(FakeAuthRepo()),
      pushServiceProvider.overrideWith((ref) => FakePush(ref)),
      unreadNotificationCountProvider.overrideWithValue(0),
      uiPrefsProvider.overrideWithValue(FakeUiPrefs()),
      dioProvider.overrideWithValue(offlineDio),
    ];

/// 가짜로 바꾸지 않은 저장소가 서버를 부르면 바로 실패시킨다 — 화면은 각자의 오류/빈 상태로 그려진다.
final offlineDio = Dio()
  ..interceptors.add(InterceptorsWrapper(
    onRequest: (o, h) => h.reject(DioException(requestOptions: o, message: 'offline')),
  ));
