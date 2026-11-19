// 알림함 삭제 시뮬레이션 — 알림 10개, 서버 지연·실패를 흉내 낸 가짜 저장소.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/notification/data/models/notification_models.dart';
import 'package:bitpet_app/features/notification/data/notification_repository.dart';
import 'package:bitpet_app/features/notification/presentation/notification_list_screen.dart';

class FakeRepo extends NotificationRepository {
  FakeRepo(int n)
      : server = [
          for (var i = 1; i <= n; i++)
            NotificationLog(
              id: i,
              notificationType: NotificationType.SYSTEM,
              title: '알림 $i',
              body: '본문 $i',
              sentAt: DateTime.now().subtract(Duration(minutes: i)),
              status: i.isEven ? NotificationStatus.READ : NotificationStatus.SENT,
            ),
        ],
        super(Dio());

  final List<NotificationLog> server;
  Duration latency = const Duration(milliseconds: 300);
  final failDeleteIds = <int>{};
  bool failGet = false;
  int gets = 0;
  final log = <String>[];

  @override
  Future<List<NotificationLog>> getNotifications() async {
    gets++;
    final snapshot = List.of(server); // 요청 시점의 서버 상태
    await Future.delayed(latency);
    if (failGet) throw Exception('GET 실패');
    return snapshot;
  }

  @override
  Future<void> delete(int id) async {
    await Future.delayed(latency);
    if (failDeleteIds.contains(id)) throw Exception('삭제 실패');
    if (!server.any((n) => n.id == id)) throw Exception('404 NOT_FOUND');
    server.removeWhere((n) => n.id == id);
    log.add('del $id');
  }

  @override
  Future<void> deleteAll() async {
    await Future.delayed(latency);
    server.clear();
    log.add('delAll');
  }

  @override
  Future<NotificationLog> markRead(int id) async {
    await Future.delayed(latency);
    return server.firstWhere((n) => n.id == id);
  }

  @override
  Future<void> markAllRead() async => Future.delayed(latency);
}

Future<FakeRepo> pump(WidgetTester t, [int n = 10]) async {
  t.view.physicalSize = const Size(1080, 4000); // 10개가 한 화면에 다 보이게
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final repo = FakeRepo(n);
  await t.pumpWidget(ProviderScope(
    overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: NotificationListScreen()),
  ));
  await t.pump(const Duration(milliseconds: 400));
  await t.pumpAndSettle();
  return repo;
}

List<String> titles(WidgetTester t) => t
    .widgetList<Text>(find.textContaining(RegExp(r'^알림 \d+$')))
    .map((w) => w.data!)
    .toList();

/// 가짜 서버 지연이 끝나도록 흘려보낸다 (안 하면 테스트 끝에 타이머가 남았다고 실패)
Future<void> drain(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(seconds: 1));
  }
}

Future<void> swipe(WidgetTester t, String title) async {
  await t.drag(find.text(title), const Offset(-600, 0));
  await t.pump(); // 밀림
  await t.pump(const Duration(milliseconds: 400)); // 접힘 애니메이션
}

Future<void> tapX(WidgetTester t, String title) async {
  final card = find.ancestor(of: find.text(title), matching: find.byType(Dismissible));
  await t.tap(find.descendant(of: card, matching: find.byIcon(Icons.close)));
  await t.pump();
  await t.pump(const Duration(milliseconds: 300)); // 접힘 애니메이션
}

void main() {
  testWidgets('① 5개 연달아 밀어서 삭제 (서버 300ms)', (t) async {
    final repo = await pump(t);
    for (final i in [1, 2, 3, 4, 5]) {
      await swipe(t, '알림 $i');
      print('  밀기 $i 직후 화면: ${titles(t).length}개');
    }
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    print('① 최종 화면 ${titles(t)} / 서버 ${repo.server.length}개 / GET ${repo.gets}회');
    expect(titles(t).length, 5);
    expect(t.takeException(), isNull);
    await drain(t);
  });

  testWidgets('② ✕ 버튼으로 5개 빠르게 삭제', (t) async {
    final repo = await pump(t);
    for (final i in [1, 2, 3, 4, 5]) {
      await tapX(t, '알림 $i');
      print('  ✕ $i 직후 화면: ${titles(t).length}개');
    }
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    print('② 최종 화면 ${titles(t)} / GET ${repo.gets}회');
    expect(titles(t).length, 5);
    await drain(t);
  });

  testWidgets('③ 하나 삭제 실패 → 원래 자리로 복귀', (t) async {
    final repo = await pump(t);
    repo.failDeleteIds.add(3);
    await swipe(t, '알림 3');
    print('  실패 전 화면: ${titles(t)}');
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    print('③ 실패 후 화면: ${titles(t)}');
    print('   토스트: ${find.text('알림을 지우지 못했어요').evaluate().isNotEmpty}');
    expect(t.takeException(), isNull);
    await drain(t);
  });

  testWidgets('④ 개별 삭제 응답 오기 전 전체 삭제', (t) async {
    final repo = await pump(t);
    repo.latency = const Duration(milliseconds: 600);
    await swipe(t, '알림 1'); // 600ms 걸리는 개별 삭제 시작
    // 전체 삭제는 더 빨리 끝나게
    repo.latency = const Duration(milliseconds: 100);
    await t.tap(find.byIcon(Icons.more_vert));
    await t.pumpAndSettle();
    await t.tap(find.text('전체 삭제'));
    await t.pump();
    for (var ms = 0; ms <= 1500; ms += 100) {
      await t.pump(const Duration(milliseconds: 100));
      final s = titles(t);
      if (s.isNotEmpty) print('  ${ms}ms: 화면에 다시 보임 $s');
    }
    await t.pumpAndSettle();
    print('④ 최종 화면 ${titles(t)} / 서버 로그 ${repo.log}');
    print('   잘못된 실패 토스트: ${find.text('알림을 지우지 못했어요').evaluate().isNotEmpty}');
    await drain(t);
  });

  testWidgets('⑤ 삭제 뒤 목록 재조회가 실패하면', (t) async {
    final repo = await pump(t);
    repo.failGet = true;
    await swipe(t, '알림 1');
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    print('⑤ 화면 알림 ${titles(t).length}개 / 오류화면: '
        '${find.text('알림을 불러오지 못했어요').evaluate().isNotEmpty}');
    await drain(t);
  });

  testWidgets('⑥ 삭제 진행 중 당겨서 새로고침', (t) async {
    final repo = await pump(t);
    repo.latency = const Duration(milliseconds: 800);
    await swipe(t, '알림 1'); // 800ms 걸리는 삭제
    // 새로고침은 금방 끝난다 (삭제 전 서버 상태를 받아 옴)
    repo.latency = const Duration(milliseconds: 100);
    await t.fling(find.text('알림 2'), const Offset(0, 600), 1000);
    for (var ms = 0; ms <= 1500; ms += 100) {
      await t.pump(const Duration(milliseconds: 100));
      if (titles(t).contains('알림 1')) print('  ${ms}ms: 지운 알림 1이 다시 보임');
    }
    await t.pumpAndSettle();
    print('⑥ 최종 화면 ${titles(t).length}개, 알림1 있음: ${titles(t).contains('알림 1')}');
    await drain(t);
  });

  testWidgets('⑦ 10개 전부 하나씩 지우기 → 빈 화면', (t) async {
    final repo = await pump(t);
    for (var i = 1; i <= 10; i++) {
      await swipe(t, '알림 $i');
    }
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    print('⑦ 남은 ${titles(t).length}개, 빈 안내: ${find.text('새 알림이 없어요').evaluate().isNotEmpty}, GET ${repo.gets}회');
    expect(t.takeException(), isNull);
    await drain(t);
  });

  testWidgets('⑧ ✕ 삭제 실패 → 접혔던 카드가 제자리에 다시 펼쳐짐', (t) async {
    final repo = await pump(t);
    repo.failDeleteIds.add(4);
    final card = find.ancestor(
        of: find.text('알림 4'), matching: find.byType(Dismissible));
    final before = t.getSize(card).height;
    await t.tap(find.descendant(of: card, matching: find.byIcon(Icons.close)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 110)); // 접히는 중간
    final mid = t.getSize(find.byKey(const ValueKey(4))).height;
    for (var k = 0; k < 6; k++) {
      await t.pump(const Duration(milliseconds: 100));
      print('  +${210 + k * 100}ms: ${titles(t).length}개, 토스트 ${find.text('알림을 지우지 못했어요').evaluate().length}');
    }
    await t.pump(const Duration(milliseconds: 400)); // 서버 실패 응답
    await t.pumpAndSettle();
    print('⑧ 높이 ${before.toStringAsFixed(0)} → 중간 ${mid.toStringAsFixed(0)} → '
        '복귀 후 화면 ${titles(t)}');
    expect(mid, lessThan(before));
    expect(titles(t)[3], '알림 4');
    expect(t.takeException(), isNull);
    await drain(t);
  });
}
