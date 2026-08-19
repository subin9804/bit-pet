import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../data/models/notification_models.dart';
import '../data/notification_repository.dart';

final notificationListProvider = FutureProvider<List<NotificationLog>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

/// 알림 수신 설정.
///
/// 토글을 누르면 먼저 화면을 바꾸고(낙관적 갱신) 서버에 보낸다. 스위치가 손가락을
/// 따라오지 않고 왕복 시간만큼 굳어 있으면 안 눌린 줄 알고 또 누르게 된다.
/// 실패하면 이전 값으로 되돌리고 이유를 알린다.
class NotificationPrefNotifier
    extends StateNotifier<AsyncValue<NotificationPref>> {
  final NotificationRepository _repo;

  NotificationPrefNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.getPref);
  }

  Future<String?> setRoutine(bool v) => _apply(
      optimistic: (p) => _copy(p, routine: v), send: () => _repo.updatePref(routine: v));

  Future<String?> setComment(bool v) => _apply(
      optimistic: (p) => _copy(p, comment: v), send: () => _repo.updatePref(comment: v));

  Future<String?> setPostLike(bool v) => _apply(
      optimistic: (p) => _copy(p, postLike: v), send: () => _repo.updatePref(postLike: v));

  Future<String?> setMarketing(bool v) => _apply(
      optimistic: (p) => _copy(p, marketing: v), send: () => _repo.updatePref(marketing: v));

  /// @return 실패 시 사용자에게 보여줄 메시지, 성공이면 null
  Future<String?> _apply({
    required NotificationPref Function(NotificationPref) optimistic,
    required Future<NotificationPref> Function() send,
  }) async {
    final before = state.valueOrNull;
    if (before == null) return null;

    state = AsyncValue.data(optimistic(before));
    try {
      state = AsyncValue.data(await send());
      return null;
    } catch (e) {
      state = AsyncValue.data(before);
      return e is ApiException ? e.message : '설정을 저장하지 못했어요';
    }
  }

  static NotificationPref _copy(
    NotificationPref p, {
    bool? routine,
    bool? comment,
    bool? postLike,
    bool? marketing,
  }) =>
      NotificationPref(
        routine: routine ?? p.routine,
        comment: comment ?? p.comment,
        postLike: postLike ?? p.postLike,
        system: p.system,
        marketing: marketing ?? p.marketing,
      );
}

final notificationPrefProvider = StateNotifierProvider.autoDispose<
    NotificationPrefNotifier, AsyncValue<NotificationPref>>((ref) {
  return NotificationPrefNotifier(ref.watch(notificationRepositoryProvider));
});

// 읽지 않은 알림 수 (배지 표시용)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationListProvider).whenOrNull(
        data: (logs) => logs.where((l) => !l.isRead).length,
      ) ?? 0;
});
