import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_models.dart';
import '../data/notification_repository.dart';

final notificationListProvider = FutureProvider<List<NotificationLog>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

// 읽지 않은 알림 수 (배지 표시용)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationListProvider).whenOrNull(
        data: (logs) => logs.where((l) => !l.isRead).length,
      ) ?? 0;
});
