import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/community/data/models/post_models.dart';
import 'package:bitpet_app/features/community/data/post_repository.dart';
import 'package:bitpet_app/features/community/presentation/community_feed_screen.dart';
import 'package:bitpet_app/features/community/presentation/post_detail_screen.dart';
import 'fakes.dart';
import 'harness.dart';

const _cats = [
  PostCategory(id: 5, code: 'NOTICE', nameKo: '공지사항', displayOrder: 0),
  PostCategory(id: 1, code: 'FREE', nameKo: '자유게시판', displayOrder: 1),
  PostCategory(id: 2, code: 'QNA', nameKo: 'QnA', displayOrder: 2),
];

final _now = DateTime.now();

Post _post(int id, int cat, String title, String author,
        {int likes = 0, int comments = 0, int views = 0, bool pinned = false,
        String? thumb, String content = '', Duration ago = const Duration(hours: 1)}) =>
    Post(
      id: id, userId: id + 10, authorName: author, categoryId: cat,
      title: title, content: content, viewCount: views, likeCount: likes,
      commentCount: comments, isLiked: false, isPinned: pinned,
      thumbnailUrl: thumb, createdAt: _now.subtract(ago),
    );

final _feed = [
  _post(1, 5, 'tailog 정식 오픈 안내', '운영자', pinned: true, views: 812, ago: const Duration(days: 2)),
  _post(2, 1, '오늘 탈피 완벽하게 했어요', '게코하우스', likes: 24, comments: 6, views: 151,
      thumb: 'https://example.invalid/a.jpg', ago: const Duration(minutes: 12)),
  _post(3, 2, '크레스티드 게코 슈푸 급여 주기 질문드려요', '초보집사', likes: 3, comments: 8, views: 97,
      ago: const Duration(hours: 2)),
  _post(4, 1, '새 사육장 세팅 완료! 바이오액티브 도전기', '렙타일러버', likes: 41, comments: 12, views: 320,
      thumb: 'https://example.invalid/b.jpg', ago: const Duration(hours: 5)),
  _post(5, 2, '볼파이톤 거식 3주째인데 괜찮을까요?', '볼파볼파', likes: 2, comments: 4, views: 66,
      ago: const Duration(hours: 9)),
  _post(6, 1, '레오파드 게코 체중 60g 돌파 기념', '루나맘', likes: 18, comments: 3, views: 88,
      ago: const Duration(days: 1)),
];

void main() {
  testWidgets('커뮤니티 피드', (t) async {
    await shot(t, 'community_feed', const CommunityFeedScreen(), overrides: [
      ...loggedIn(),
      postRepositoryProvider.overrideWithValue(
          FakePostRepo(categories: _cats, feed: _feed)),
    ]);
  });

  testWidgets('글 상세 — 댓글 없음', (t) async {
    await shot(t, 'post_detail_no_comments', const PostDetailScreen(postId: 3), pushed: true, overrides: [
      ...loggedIn(),
      postRepositoryProvider.overrideWithValue(FakePostRepo(
        categories: _cats,
        posts: {
          3: _post(3, 2, '크레스티드 게코 슈푸 급여 주기 질문드려요', '초보집사',
              views: 97, ago: const Duration(hours: 2),
              content: '입양한 지 2주 된 크레스티드 게코예요.\n'
                  '슈푸는 이틀에 한 번 주고 있는데 너무 적은 걸까요?\n'
                  '먹는 양이 들쭉날쭉해서 기록해 보고 있어요.'),
        },
      )),
    ]);
  });
}
