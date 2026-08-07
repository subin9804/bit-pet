import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'tag_url.dart';

/// NDEF(URL) 읽기 전용 NFC 리더.
///
/// **UID는 쓰지 않는다.** 태그 하나하나가 굽힌 URL로 자기를 식별하고, UID는 칩 세대마다
/// 길이·포맷이 달라 신뢰할 수 없다. NDEF 텍스트만 읽어 [parseTagCode]에 넘긴다.
///
/// ## 세션이 곧 포그라운드 선점이다
/// Android에서 `NfcManager.startSession` 은 내부적으로 `enableReaderMode` 를 켠다.
/// 이게 켜져 있는 동안 OS는 태그를 App Link 인텐트로 디스패치하지 않고 이 콜백으로만
/// 보낸다 — 스캔 시트를 띄운 채 태그를 탭했을 때 현재 화면이 개체 상세로 갈아엎히는 문제가
/// 여기서 막힌다. 그래서 [stop]을 빠뜨리면 시트를 닫은 뒤에도 딥링크가 죽어 있게 된다.
/// **시작한 쪽이 반드시 끝낸다.**
class NfcReader {
  bool _sessionActive = false;

  bool get isSessionActive => _sessionActive;

  /// 이 기기에서 NFC를 쓸 수 있는지 (미탑재이거나 설정에서 꺼둔 경우 false)
  static Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('[NFC] 가용성 확인 실패: $e');
      return false;
    }
  }

  /// 태그 폴링 시작.
  ///
  /// [onTagCode]  : 우리 태그를 읽었을 때 (대문자 정규화된 코드)
  /// [onForeignTag]: NDEF는 읽혔지만 우리 태그가 아닐 때 — 안내를 띄우려고 따로 받는다
  Future<void> start({
    required void Function(String tagCd) onTagCode,
    void Function()? onForeignTag,
  }) async {
    if (_sessionActive) return;
    _sessionActive = true;
    try {
      await NfcManager.instance.startSession(
        // iOS에서만 보이는 시스템 시트 문구. Android는 무시한다
        alertMessage: '이름표에 휴대폰을 가까이 대주세요',
        onDiscovered: (NfcTag tag) async {
          final code = _readTagCode(tag);
          if (code != null) {
            onTagCode(code);
          } else {
            onForeignTag?.call();
          }
        },
      );
    } catch (e) {
      _sessionActive = false;
      rethrow;
    }
  }

  /// 세션 종료. 여러 번 불러도 안전하다 — 시트 dispose 와 스캔 성공 양쪽에서 호출된다.
  Future<void> stop() async {
    if (!_sessionActive) return;
    _sessionActive = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // 이미 끊긴 세션을 닫는 경우가 대부분이다. 사용자에게 알릴 일이 아니다
      debugPrint('[NFC] 세션 종료 실패(무시): $e');
    }
  }

  /// NDEF 레코드에서 URL을 꺼내 태그 코드로 환원. 못 읽으면 null.
  String? _readTagCode(NfcTag tag) {
    final ndef = Ndef.from(tag);
    final message = ndef?.cachedMessage;
    if (message == null) return null;

    for (final record in message.records) {
      final url = _decodeUri(record);
      final code = parseTagCode(url);
      if (code != null) return code;
    }
    return null;
  }

  /// NDEF 레코드 payload → 문자열.
  ///
  /// URI 레코드는 payload 첫 바이트가 **접두사 코드**다 (0x03 = `http://`, 0x04 = `https://`).
  /// 그대로 UTF-8 로 읽으면 제어문자 하나가 앞에 붙어 URL 파싱이 어긋난다.
  ///
  /// 레코드 타입(`typeNameFormat`/`type`)으로 분기하지 않고 첫 바이트 값만 본다.
  /// 접두사 코드 범위(0x00~0x04)는 URL 문자열의 첫 글자와 겹칠 수 없어서 오판할 여지가 없고,
  /// 태그를 굽는 도구마다 레코드 타입을 다르게 쓰는 경우가 실제로 있다.
  String? _decodeUri(NdefRecord record) {
    final payload = record.payload;
    if (payload.isEmpty) return null;

    try {
      final prefix = _uriPrefixes[payload.first];
      if (prefix != null) {
        return prefix + utf8.decode(payload.sublist(1), allowMalformed: true);
      }
      // TEXT 레코드나 포맷 미상 — 통째로 읽어 파서에 맡긴다 (파서가 관대하다)
      return utf8.decode(payload, allowMalformed: true);
    } catch (e) {
      debugPrint('[NFC] NDEF 디코딩 실패: $e');
      return null;
    }
  }

  /// NFC Forum URI Record Type Definition 의 접두사 테이블 중 우리가 만날 수 있는 것만.
  static const Map<int, String> _uriPrefixes = {
    0x00: '',
    0x01: 'http://www.',
    0x02: 'https://www.',
    0x03: 'http://',
    0x04: 'https://',
  };
}
