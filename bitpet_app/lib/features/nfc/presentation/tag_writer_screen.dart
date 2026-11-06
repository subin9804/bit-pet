import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../../core/api/api_response.dart';
import '../../../core/nfc/nfc_reader.dart';
import '../../../core/nfc/nfc_writer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/toast_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/tag_repository.dart';

/// 굽는 URL. 서버 tagCd 형식·tag_url.dart 의 kTagHosts 와 맞아야 한다.
String _tagUrl(String code) => 'https://tailog.me/t/$code';

/// 이번 화면에서 처리한 태그 한 줄
class _LogEntry {
  final String code;
  final TagWriteOutcome outcome;
  final DateTime at;
  final bool locked;
  final bool lockFailed;

  _LogEntry(this.code, this.outcome, {this.locked = false, this.lockFailed = false})
      : at = DateTime.now();
}

/// [관리자] 이름표 연속 굽기 (2026-11-06).
///
/// 굽기 모드를 켜고 빈 태그를 하나씩 대면, 서버에서 받아 둔 다음 코드를
/// `https://tailog.me/t/{code}` 로 굽고 곧바로 그다음 코드를 받아 둔다.
///
/// 코드는 **한 장씩** 발급한다(미리 1장만 받아 둠). 많이 받아 두면 굽지 않은 코드가
/// 재고(STOCK)로 남는다 — 해롭진 않지만 통계가 지저분해진다. 쓰다 실패한 코드는
/// 반쯤 써졌을 수 있어 **재사용하지 않고 버린다** (같은 코드 두 장이 더 나쁘다).
///
/// 메뉴는 관리자에게만 보이지만, 서버도 `/admin/tags/issue` 에서 AdminGuard 로 다시 막는다.
class TagWriterScreen extends ConsumerStatefulWidget {
  const TagWriterScreen({super.key});

  @override
  ConsumerState<TagWriterScreen> createState() => _TagWriterScreenState();
}

class _TagWriterScreenState extends ConsumerState<TagWriterScreen> {
  static const _chipTypes = ['NTAG213', 'NTAG215', 'NTAG216'];

  final _writer = NfcTagWriter();
  late final TextEditingController _batchCtrl;
  String _chipType = _chipTypes.first;
  bool _lock = false;

  /// 다음 태그에 구울 코드 (미리 받아 둔 1장)
  String? _nextCode;
  Future<String>? _fetching;
  bool _busy = false;

  final List<_LogEntry> _log = [];
  String? _status;

  int get _writtenCount =>
      _log.where((e) => e.outcome == TagWriteOutcome.written).length;

  @override
  void initState() {
    super.initState();
    _batchCtrl = TextEditingController(
        text: 'W${DateFormat('yyyyMMdd').format(DateTime.now())}');
  }

  @override
  void dispose() {
    // 시작한 쪽이 끝낸다 — 안 끄면 Android 딥링크 선점이 남는다
    _writer.stop();
    _batchCtrl.dispose();
    super.dispose();
  }

  String? get _batchNo {
    final v = _batchCtrl.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<String> _takeCode() {
    if (_nextCode != null) return Future.value(_nextCode!);
    return _fetching ??= ref
        .read(tagRepositoryProvider)
        .issueStock(count: 1, chipType: _chipType, batchNo: _batchNo)
        .then((codes) {
      _nextCode = codes.first;
      if (mounted) setState(() {});
      return codes.first;
    }).whenComplete(() => _fetching = null);
  }

  void _prefetch() => _takeCode().catchError((_) => '');

  Future<void> _start() async {
    if (!await NfcReader.isAvailable()) {
      if (mounted) showToast(context, 'NFC를 쓸 수 없는 기기이거나 꺼져 있어요', type: ToastType.error);
      return;
    }
    try {
      await _takeCode();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
      return;
    }
    setState(() => _status = '태그를 휴대폰 윗부분에 대주세요');
    await _writer.start(
      onTag: _handleTag,
      promptBuilder: () =>
          '다음 코드 ${_nextCode ?? '준비 중'} · $_writtenCount장 완료\n태그를 대주세요',
      onStopped: (reason) {
        if (mounted) setState(() => _status = reason);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _stop() async {
    await _writer.stop();
    if (mounted) setState(() => _status = '멈췄어요 · $_writtenCount장 구움');
  }

  /// 태그 한 장 처리. 돌려준 문구가 iOS 시트에 뜬다.
  Future<String?> _handleTag(NfcTag tag) async {
    if (_busy) return null;
    _busy = true;
    try {
      final String code;
      try {
        code = await _takeCode();
      } catch (_) {
        _setStatus('코드를 못 받았어요 — 네트워크 확인 후 다시 대주세요');
        return '코드 발급 실패';
      }

      final result = await NfcTagWriter.writeUrl(tag, _tagUrl(code), lock: _lock);
      switch (result.outcome) {
        case TagWriteOutcome.written:
          _nextCode = null;
          _log.insert(0, _LogEntry(code, result.outcome,
              locked: _lock && !result.lockFailed, lockFailed: result.lockFailed));
          HapticFeedback.mediumImpact();
          _setStatus(result.lockFailed
              ? '$code 구움 (잠금 실패) · 다음 태그를 대주세요'
              : '$code 구움 ✓ · 다음 태그를 대주세요');
          _prefetch();
          return '✓ $code ($_writtenCount장)';
        case TagWriteOutcome.alreadyOurs:
          _log.insert(0, _LogEntry(result.existingCode!, result.outcome));
          HapticFeedback.lightImpact();
          _setStatus('이미 구운 태그예요 (${result.existingCode}) · 건너뜀');
          return '이미 구운 태그 · ${result.existingCode}';
        case TagWriteOutcome.notWritable:
          HapticFeedback.heavyImpact();
          _setStatus('쓸 수 없는 태그예요 (잠겼거나 지원하지 않는 칩)');
          return '쓸 수 없는 태그';
        case TagWriteOutcome.failed:
          // 반쯤 써졌을 수 있다 — 이 코드는 버리고 새로 받는다
          _nextCode = null;
          _log.insert(0, _LogEntry(code, result.outcome));
          HapticFeedback.heavyImpact();
          _setStatus('굽다가 실패했어요 — 태그를 떼지 말고 다시 대주세요');
          _prefetch();
          return '실패 · 다시 대주세요';
      }
    } finally {
      _busy = false;
    }
  }

  void _setStatus(String s) {
    if (mounted) setState(() => _status = s);
  }

  Future<void> _toggleLock(bool v) async {
    if (v) {
      final ok = await ConfirmModal.show(
        context,
        title: '태그를 잠글까요?',
        message: '잠근 태그는 다시는 고쳐 쓸 수 없어요. 남이 덮어쓰는 걸 막아 주지만, '
            '잘못 구우면 그 태그는 버려야 해요.',
        confirmLabel: '잠그기',
        isDangerous: true,
      );
      if (!ok) return;
    }
    setState(() => _lock = v);
  }

  void _onSettingChanged() {
    // 받아 둔 코드는 이전 배치·칩으로 발급됐다 — 버리고 새로 받는다
    _nextCode = null;
  }

  Future<void> _copyLogCsv() async {
    final written = _log.where((e) => e.outcome == TagWriteOutcome.written).toList();
    if (written.isEmpty) {
      showToast(context, '아직 구운 태그가 없어요');
      return;
    }
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    final rows = [
      'tag_cd,url,batch_no,chip_type,locked,written_at',
      for (final e in written.reversed)
        '${e.code},${_tagUrl(e.code)},${_batchNo ?? ''},$_chipType,${e.locked},${fmt.format(e.at)}',
    ];
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (mounted) showToast(context, '${written.length}장 CSV를 복사했어요', type: ToastType.success);
  }

  /// 업체 인코딩용 — 코드만 대량 발급해 CSV 로 복사한다
  Future<void> _issueCsv() async {
    final count = await showDialog<int>(
      context: context,
      builder: (_) => const _IssueCountDialog(),
    );
    if (count == null || !mounted) return;
    try {
      final codes = await ref
          .read(tagRepositoryProvider)
          .issueStock(count: count, chipType: _chipType, batchNo: _batchNo);
      final rows = ['tag_cd,url', for (final c in codes) '$c,${_tagUrl(c)}'];
      await Clipboard.setData(ClipboardData(text: rows.join('\n')));
      if (mounted) {
        showToast(context, '${codes.length}개 발급 · CSV를 복사했어요', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).valueOrNull?.isAdmin ?? false;
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('이름표 굽기')),
        body: const Center(child: Text('관리자만 쓸 수 있어요')),
      );
    }

    final active = _writer.isActive;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('이름표 굽기'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'csv' ? _copyLogCsv() : _issueCsv(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('구운 목록 CSV 복사')),
              PopupMenuItem(value: 'issue', child: Text('코드만 발급 (업체용 CSV)')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(children: [
            Text('배치 번호', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: _batchCtrl,
              enabled: !active,
              onChanged: (_) => _onSettingChanged(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '불량 회수 단위 — 묶음마다 다르게',
              ),
            ),
            const SizedBox(height: 14),
            Text('칩 종류', style: AppTextStyles.label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _chipTypes)
                  ChoiceChip(
                    label: Text(c),
                    selected: _chipType == c,
                    onSelected: active
                        ? null
                        : (_) => setState(() {
                              _chipType = c;
                              _onSettingChanged();
                            }),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('굽고 나서 잠그기', style: AppTextStyles.body),
              subtitle: Text('되돌릴 수 없어요', style: AppTextStyles.caption),
              value: _lock,
              onChanged: active ? null : _toggleLock,
            ),
          ]),
          const SizedBox(height: 12),
          _Card(children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('다음 코드', style: AppTextStyles.caption),
                      Text(_nextCode ?? '—', style: AppTextStyles.mono(24, FontWeight.w700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('구운 태그', style: AppTextStyles.caption),
                    Text('$_writtenCount장', style: AppTextStyles.numHero),
                  ],
                ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 10),
              Text(_status!, style: AppTextStyles.sub),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: active ? AppColors.error : AppColors.brandAction,
                ),
                onPressed: active ? _stop : _start,
                child: Text(active ? '멈추기' : '굽기 시작', style: AppTextStyles.button),
              ),
            ),
          ]),
          if (_log.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(children: [
              for (final e in _log.take(50)) _LogRow(entry: e),
            ]),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _LogRow extends StatelessWidget {
  final _LogEntry entry;
  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (entry.outcome) {
      TagWriteOutcome.written => (
          entry.lockFailed ? '구움·잠금실패' : (entry.locked ? '구움·잠금' : '구움'),
          AppColors.success
        ),
      TagWriteOutcome.alreadyOurs => ('건너뜀', AppColors.ink3),
      TagWriteOutcome.failed => ('실패·폐기', AppColors.error),
      TagWriteOutcome.notWritable => ('쓰기 불가', AppColors.error),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(entry.code, style: AppTextStyles.mono(15, FontWeight.w600)),
          const SizedBox(width: 10),
          Text(DateFormat('HH:mm:ss').format(entry.at), style: AppTextStyles.caption),
          const Spacer(),
          Text(label, style: AppTextStyles.label.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _IssueCountDialog extends StatefulWidget {
  const _IssueCountDialog();

  @override
  State<_IssueCountDialog> createState() => _IssueCountDialogState();
}

class _IssueCountDialogState extends State<_IssueCountDialog> {
  final _ctrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = int.tryParse(_ctrl.text.trim());
    final valid = n != null && n >= 1 && n <= 1000;
    return AlertDialog(
      title: const Text('코드만 발급'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('업체에 인코딩을 맡길 때 쓰는 목록이에요. 발급한 코드는 바로 재고로 등록돼요.'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(suffixText: '개 (최대 1000)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        TextButton(
          onPressed: valid ? () => Navigator.pop(context, n) : null,
          child: const Text('발급'),
        ),
      ],
    );
  }
}
