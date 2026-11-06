import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

import 'nfc_reader.dart';

/// 태그 한 장을 처리한 결과. 화면은 이걸 보고 코드를 소모할지 정한다.
enum TagWriteOutcome {
  /// 새로 구웠다 — 코드 소모
  written,

  /// 이미 우리 코드가 들어 있다 — 건너뛴다 (같은 태그를 두 번 댄 경우가 대부분)
  alreadyOurs,

  /// 쓰기 잠긴 남의 태그 / NDEF 를 못 쓰는 칩
  notWritable,

  /// 쓰는 도중 실패 — 반쯤 써졌을 수 있다
  failed,
}

/// 한 장 처리 결과 + iOS 시트에 띄울 문구
class TagWriteResult {
  final TagWriteOutcome outcome;

  /// alreadyOurs 일 때 태그에 들어 있던 코드
  final String? existingCode;

  /// 굽기는 됐는데 잠금만 실패한 경우
  final bool lockFailed;

  const TagWriteResult(this.outcome, {this.existingCode, this.lockFailed = false});
}

/// 관리자 연속 굽기용 NFC 라이터 (2026-11-06).
///
/// CLAUDE.md 의 "앱은 태그에 쓰지 않는다" 원칙의 **유일한 예외**다. 일반 사용자 경로에서는
/// 절대 쓰지 않는다 — 관리자 화면(TagWriterScreen)에서만 연다.
///
/// ## iOS 는 태그마다 세션을 새로 연다
/// nfc_manager 3.x 는 `invalidateAfterFirstRead: false` 일 때 Dart 콜백이 끝나기를
/// 기다리지 않고 **곧바로 `restartPolling()` 을 불러 태그 연결을 끊는다** — 그 상태로
/// write 하면 실패한다. 그래서 기본값(true)으로 열어 한 장 쓰고 세션을 닫은 뒤
/// 잠깐 쉬었다 다시 연다. 시트가 ✓ 를 보여 주고 다시 뜨는 데 1초 남짓 걸린다.
///
/// Android 는 리더 모드가 계속 켜져 있어 세션 하나로 끝까지 간다.
/// 같은 태그를 대고 있어도 태그가 장(field)을 벗어났다 들어와야 다시 잡히고,
/// 다시 잡혀도 [TagWriteOutcome.alreadyOurs] 로 걸러진다.
class NfcTagWriter {
  bool _active = false;

  /// 세션 세대. 닫힌 세션의 늦은 콜백이 새 세션 상태를 건드리지 못하게 한다.
  int _gen = 0;

  bool get isActive => _active;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  /// 연속 굽기 시작.
  ///
  /// [onTag] 가 태그 한 장을 처리하고 iOS 시트 문구를 돌려준다 (null 이면 기본 문구).
  /// [promptBuilder] 는 다음 세션 시트 문구 — "다음 코드 · n장 완료" 같은 것.
  /// [onStopped] 는 사용자가 iOS 시트를 닫았거나 시간이 초과돼 멈췄을 때.
  Future<void> start({
    required Future<String?> Function(NfcTag tag) onTag,
    required String Function() promptBuilder,
    required void Function(String reason) onStopped,
  }) async {
    if (_active) return;
    _active = true;
    await _open(onTag, promptBuilder, onStopped);
  }

  Future<void> _open(
    Future<String?> Function(NfcTag tag) onTag,
    String Function() promptBuilder,
    void Function(String reason) onStopped, {
    int attempt = 0,
  }) async {
    final gen = ++_gen;
    try {
      await NfcManager.instance.startSession(
        alertMessage: promptBuilder(),
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (tag) async {
          if (!_active || gen != _gen) return;
          final message = await onTag(tag);
          if (!_isIos || !_active || gen != _gen) return;
          // iOS: 한 장 끝 → 세션 닫고 다시 연다 (클래스 주석 참고)
          _gen++;
          try {
            await NfcManager.instance.stopSession(alertMessage: message ?? '완료');
          } catch (e) {
            debugPrint('[NFC-W] 세션 종료 실패(무시): $e');
          }
          await Future<void>.delayed(const Duration(milliseconds: 1100));
          if (_active) await _open(onTag, promptBuilder, onStopped);
        },
        onError: (error) async {
          if (!_active || gen != _gen) return;
          _active = false;
          onStopped(switch (error.type) {
            NfcErrorType.sessionTimeout => '시간이 지나 멈췄어요',
            NfcErrorType.userCanceled => '굽기를 멈췄어요',
            _ => 'NFC 세션이 끊겼어요',
          });
        },
      );
    } catch (e) {
      // 직전 세션이 아직 닫히는 중이면 거절될 수 있다 — 조금 더 기다렸다 재시도
      if (_active && attempt < 3) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        return _open(onTag, promptBuilder, onStopped, attempt: attempt + 1);
      }
      _active = false;
      onStopped('NFC 세션을 열지 못했어요');
    }
  }

  /// 종료. 여러 번 불러도 안전하다. 시작한 쪽이 반드시 부른다 (Android 딥링크 선점 해제).
  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    _gen++;
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      debugPrint('[NFC-W] 세션 종료 실패(무시): $e');
    }
  }

  /// 태그 한 장에 [url] 을 굽는다. 이미 우리 코드가 있으면 건드리지 않는다.
  ///
  /// [lock] 은 **되돌릴 수 없다** — 잠근 태그는 다시는 못 쓴다.
  static Future<TagWriteResult> writeUrl(
    NfcTag tag,
    String url, {
    bool lock = false,
  }) async {
    final existing = NfcReader.readTagCode(tag);
    if (existing != null) {
      return TagWriteResult(TagWriteOutcome.alreadyOurs, existingCode: existing);
    }

    final message = NdefMessage([NdefRecord.createUri(Uri.parse(url))]);
    final ndef = Ndef.from(tag);

    if (ndef == null) {
      // 공장 출하 상태라 NDEF 포맷이 안 된 칩 — Android 만 포맷할 수 있다
      final formatable = NdefFormatable.from(tag);
      if (formatable == null) {
        return const TagWriteResult(TagWriteOutcome.notWritable);
      }
      try {
        await (lock
            ? formatable.formatReadOnly(message)
            : formatable.format(message));
        return const TagWriteResult(TagWriteOutcome.written);
      } catch (e) {
        debugPrint('[NFC-W] 포맷 실패: $e');
        return const TagWriteResult(TagWriteOutcome.failed);
      }
    }

    if (!ndef.isWritable) return const TagWriteResult(TagWriteOutcome.notWritable);
    if (ndef.maxSize > 0 && message.byteLength > ndef.maxSize) {
      return const TagWriteResult(TagWriteOutcome.notWritable);
    }

    try {
      await ndef.write(message);
    } catch (e) {
      debugPrint('[NFC-W] 쓰기 실패: $e');
      return const TagWriteResult(TagWriteOutcome.failed);
    }

    if (!lock) return const TagWriteResult(TagWriteOutcome.written);
    try {
      await ndef.writeLock();
      return const TagWriteResult(TagWriteOutcome.written);
    } catch (e) {
      debugPrint('[NFC-W] 잠금 실패: $e');
      return const TagWriteResult(TagWriteOutcome.written, lockFailed: true);
    }
  }
}
