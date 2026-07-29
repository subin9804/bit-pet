import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../router/app_router.dart';
import 'device_token_repository.dart';

/// AndroidManifest 의 default_notification_channel_id, 서버 FcmProperties.androidChannelId 와 동일해야 함
const String kDefaultChannelId = 'bitpet_default_channel';
const String _kChannelName = '비트펫 알림';
const String _kChannelDescription = '루틴 알람, 댓글·좋아요 등 비트펫 알림';

final _localNotifications = FlutterLocalNotificationsPlugin();

/// 앱이 종료/백그라운드 상태일 때 도착한 메시지 핸들러.
/// 별도 isolate 에서 실행되므로 Firebase 를 다시 초기화해야 한다.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // notification 페이로드가 있으면 OS가 알아서 트레이에 띄우므로 여기서 별도 처리는 하지 않는다.
  debugPrint('[FCM] background message: ${message.messageId}');
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

/// FCM 초기화 · 디바이스 토큰 등록 · 포그라운드 알림 표시 · 알림 탭 라우팅을 담당한다.
class PushService {
  final Ref _ref;
  PushService(this._ref);

  bool _initialized = false;
  String? _currentToken;

  /// 로그인 이후 호출. 권한 요청 → 채널 생성 → 토큰 등록 → 리스너 연결.
  Future<void> initialize() async {
    if (_initialized) {
      await registerToken();
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] 알림 권한 거부됨 — 푸시 표시 불가 (토큰 등록은 계속 진행)');
    }

    await _setupLocalNotifications();

    // 포그라운드: OS가 알림을 띄우지 않으므로 로컬 알림으로 직접 표시
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // 백그라운드 상태에서 알림 탭으로 앱 복귀
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 종료 상태에서 알림 탭으로 앱 시작
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    messaging.onTokenRefresh.listen(_sendTokenToServer);

    _initialized = true;
    await registerToken();
  }

  /// 현재 기기의 FCM 토큰을 서버에 등록
  Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint('[FCM] 토큰 등록 실패: $e');
    }
  }

  /// 로그아웃 시 호출 — 서버에서 토큰 삭제 후 로컬 토큰도 폐기해 다음 로그인 때 새로 발급받는다.
  Future<void> unregisterToken() async {
    final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _ref.read(deviceTokenRepositoryProvider).unregister(token);
    } catch (e) {
      debugPrint('[FCM] 토큰 해제 실패: $e');
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[FCM] 토큰 삭제 실패: $e');
    }
    _currentToken = null;
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _ref.read(deviceTokenRepositoryProvider).register(
            deviceToken: token,
            platform: Platform.isIOS ? 'IOS' : 'ANDROID',
            deviceInfo: _deviceInfo(),
          );
      _currentToken = token;
      debugPrint('[FCM] 디바이스 토큰 등록 완료');
    } catch (e) {
      debugPrint('[FCM] 디바이스 토큰 서버 등록 실패: $e');
    }
  }

  String _deviceInfo() {
    final info = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    return info.length > 255 ? info.substring(0, 255) : info;
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _routeToTarget(
          Map<String, dynamic>.from(jsonDecode(payload) as Map),
        );
      },
    );

    const channel = AndroidNotificationChannel(
      kDefaultChannelId,
      _kChannelName,
      description: _kChannelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kDefaultChannelId,
          _kChannelName,
          channelDescription: _kChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageTap(RemoteMessage message) => _routeToTarget(message.data);

  /// 서버 FcmSender.buildData() 가 실어 보낸 type/참조 ID 로 이동 대상을 결정한다.
  void _routeToTarget(Map<String, dynamic> data) {
    final router = _ref.read(routerProvider);
    final type = data['type'] as String?;

    switch (type) {
      case 'ROUTINE_ALARM':
        router.go('/routines');
      case 'COMMUNITY_LIKE':
        // referenceId = postId
        final postId = data['referenceId'];
        router.go(postId != null ? '/community/$postId' : '/notifications');
      case 'AI_CONSULTING':
        final petId = data['petId'];
        router.go(petId != null ? '/pets/$petId' : '/notifications');
      // COMMUNITY_COMMENT 는 referenceId 가 commentId 라 게시글을 특정할 수 없음 → 알림함으로
      default:
        router.go('/notifications');
    }
  }
}
