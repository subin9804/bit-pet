import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/month_grid_calendar.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/record_models.dart';
import '../data/record_repository.dart';
import '../providers/record_provider.dart';
import '../../pet/providers/pet_provider.dart';

const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

// ── 타입 메타 ──────────────────────────────────────────────────
class _TypeMeta {
  final String label;
  final String calendarCat;
  final Color accent;
  final IconData icon;
  const _TypeMeta(this.label, this.calendarCat, this.accent, this.icon);
}

const _typeMeta = {
  'cleaning': _TypeMeta('청소 기록',  'CLEANING', AppColors.petSky,    Icons.cleaning_services_outlined),
  'memo':     _TypeMeta('메모',       'MEMO',     AppColors.petLilac,  Icons.note_alt_outlined),
  'mating':   _TypeMeta('교배 기록',  'MATING',   AppColors.petCoral,  Icons.favorite_outline),
  'laying':   _TypeMeta('산란 기록',  'LAYING',   AppColors.petSage,   Icons.egg_outlined),
};

// ── 통합 기록 엔트리 ────────────────────────────────────────────
class RecordEntry {
  final int id;
  final String dateStr;   // YYYY-MM-DD
  final String timeStr;   // HH:mm
  final String summary;
  final dynamic raw;
  // false면 수정/삭제 불가 (예: 루틴 완료로 자동 생성된 합성 메모)
  final bool editable;

  const RecordEntry({
    required this.id,
    required this.dateStr,
    required this.timeStr,
    required this.summary,
    required this.raw,
    this.editable = true,
  });
}

// ── 에디터 상태 ─────────────────────────────────────────────────
class _EditorState {
  final bool isEdit;
  final int? editId;
  final String dateStr;
  final Map<String, dynamic> form;

  const _EditorState({
    required this.isEdit,
    required this.editId,
    required this.dateStr,
    required this.form,
  });

  _EditorState copyWith({String? dateStr, Map<String, dynamic>? form}) =>
      _EditorState(
        isEdit: isEdit, editId: editId,
        dateStr: dateStr ?? this.dateStr,
        form: form ?? this.form,
      );
}

// ── 메인 화면 ────────────────────────────────────────────────────
class RecordDetailScreen extends ConsumerStatefulWidget {
  final int petId;
  final String recordType; // cleaning, memo, mating, laying

  const RecordDetailScreen({
    super.key,
    required this.petId,
    required this.recordType,
  });

  @override
  ConsumerState<RecordDetailScreen> createState() =>
      _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen> {
  int _tabIndex = 0;
  _EditorState? _editor;

  _TypeMeta get _meta => _typeMeta[widget.recordType]!;

  // 각 타입 provider → RecordEntry 리스트
  AsyncValue<List<RecordEntry>> get _entriesAsync {
    switch (widget.recordType) {
      case 'cleaning':
        return ref.watch(cleaningListProvider(widget.petId)).whenData(
            (l) => l.map(_fromCleaning).toList());
      case 'memo':
        return ref.watch(memoListProvider(widget.petId)).whenData(
            (l) => l.map(_fromMemo).toList());
      case 'mating':
        return ref.watch(matingListProvider(widget.petId)).whenData(
            (l) => l.map(_fromMating).toList());
      case 'laying':
        return ref.watch(layingListProvider(widget.petId)).whenData(
            (l) => l.map(_fromLaying).toList());
      default:
        return const AsyncData([]);
    }
  }

  void _invalidate() {
    switch (widget.recordType) {
      case 'cleaning': ref.invalidate(cleaningListProvider(widget.petId));
      case 'memo':     ref.invalidate(memoListProvider(widget.petId));
      case 'mating':   ref.invalidate(matingListProvider(widget.petId));
      case 'laying':   ref.invalidate(layingListProvider(widget.petId));
    }
    ref.invalidate(petCalendarProvider(
        PetYearMonth(widget.petId, _currentYearMonth())));
  }

  String _currentYearMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _openAdd(String? dateStr) {
    setState(() {
      _editor = _EditorState(
        isEdit: false, editId: null,
        dateStr: dateStr ?? _todayStr(),
        form: _defaultForm(),
      );
    });
  }

  void _openEdit(RecordEntry entry) {
    if (!entry.editable) {
      // 루틴 완료로 자동 생성된 기록 — 실제 메모가 아니라 수정/삭제 불가
      showToast(context, '루틴 완료로 기록된 항목은 수정할 수 없어요.',
          type: ToastType.info);
      return;
    }
    setState(() {
      _editor = _EditorState(
        isEdit: true, editId: entry.id,
        dateStr: entry.dateStr,
        form: _entryToForm(entry),
      );
    });
  }

  Future<void> _save() async {
    final e = _editor;
    if (e == null) return;
    final repo = ref.read(recordRepositoryProvider);
    try {
      final dateTime = DateTime.parse(e.dateStr).toUtc().toIso8601String();
      if (widget.recordType == 'cleaning') {
        final ct = e.form['cleaningType'] as CleaningType;
        final memo = (e.form['memo'] as String).trim();
        if (e.isEdit && e.editId != null) {
          await repo.updateCleaning(e.editId!, {
            'cleaningType': ct.name,
            'cleanedAt': dateTime,
            if (memo.isNotEmpty) 'memo': memo,
          });
        } else {
          await repo.addCleaning(widget.petId, ct, DateTime.parse(e.dateStr),
              memo.isEmpty ? null : memo);
        }
      } else if (widget.recordType == 'memo') {
        final tags = List<String>.from(e.form['tags'] as List? ?? const []);
        final rawContent = (e.form['content'] as String).trim();
        // 내용이 없어도 분류를 골랐으면 그 라벨로 저장 (FAB 메모 폼과 동일)
        final tagMatches = tags.isEmpty
            ? const <MemoTag>[]
            : (ref.read(memoTagsProvider).valueOrNull ?? const <MemoTag>[])
                .where((t) => t.code == tags.first)
                .toList();
        final tagLabel = tagMatches.isEmpty ? null : tagMatches.first.labelKo;
        final content = rawContent.isNotEmpty ? rawContent : (tagLabel ?? '');
        if (content.isEmpty) {
          showToast(context, '내용을 입력하거나 분류를 선택하세요',
              type: ToastType.error);
          return;
        }
        final data = <String, dynamic>{
          'content': content,
          'loggedAt': dateTime,
          'tags': tags, // PUT은 태그 전체 교체 — 항상 전송해야 기존 태그가 보존됨
        };
        // VET 태그 메모는 vetExt 필수 (기존 값 보존, 없으면 빈 객체)
        if (tags.contains('VET')) {
          final vetExt = e.form['vetExt'] as MemoVetExt?;
          data['vetExt'] = {
            'clinicName': vetExt?.clinicName,
            'cost': vetExt?.cost,
            'nextVisitAt': vetExt?.nextVisitAt?.toUtc().toIso8601String(),
          };
        }
        if (e.isEdit && e.editId != null) {
          await repo.updateMemo(e.editId!, data);
        } else {
          await repo.addMemo(widget.petId, data);
        }
      } else if (widget.recordType == 'mating') {
        final memo = (e.form['memo'] as String).trim();
        final data = {
          'triedAt': dateTime,
          if (e.form['isSuccessful'] != null)
            'isSuccessful': e.form['isSuccessful'],
          if (memo.isNotEmpty) 'memo': memo,
        };
        if (e.isEdit && e.editId != null) {
          await repo.updateMating(e.editId!, data);
        } else {
          await repo.addMating(widget.petId, data);
        }
      } else if (widget.recordType == 'laying') {
        final cnt = e.form['totalCount'] as int;
        final memo = (e.form['memo'] as String).trim();
        final data = {
          'laidAt': dateTime,
          'totalCount': cnt,
          if (memo.isNotEmpty) 'memo': memo,
        };
        if (e.isEdit && e.editId != null) {
          await repo.updateLaying(e.editId!, data);
        } else {
          await repo.addLaying(widget.petId, data);
        }
      }
      _invalidate();
      if (mounted) {
        setState(() => _editor = null);
        showToast(context, e.isEdit ? '수정되었습니다.' : '기록이 추가되었습니다.',
            type: ToastType.success);
      }
    } catch (err) {
      if (mounted) showToast(context, err.toString(), type: ToastType.error);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await ConfirmModal.show(
      context,
      title: '기록 삭제',
      message: '이 기록을 삭제할까요?\n삭제하면 복구할 수 없습니다.',
      confirmLabel: '삭제',
      isDangerous: true,
    );
    if (!ok) return;
    final repo = ref.read(recordRepositoryProvider);
    try {
      switch (widget.recordType) {
        case 'cleaning': await repo.deleteCleaning(id);
        case 'memo':     await repo.deleteMemo(id);
        case 'mating':   await repo.deleteMating(id);
        case 'laying':   await repo.deleteLaying(id);
      }
      _invalidate();
      if (mounted) {
        setState(() => _editor = null);
        showToast(context, '기록이 삭제되었습니다.', type: ToastType.info);
      }
    } catch (err) {
      if (mounted) showToast(context, err.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petDetailProvider(widget.petId));
    final petName = petAsync.whenOrNull(data: (p) => p.name) ?? '';

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: _TopBar(
                  onBack: () => context.pop(),
                  title: _meta.label,
                  petName: petName,
                  onAdd: () => _openAdd(null),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 2, 22, 12),
                child: _Segment(
                  index: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ),
              Expanded(
                child: _entriesAsync.when(
                  loading: () => const SkeletonCardList(),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (entries) => _tabIndex == 0
                      ? _CalendarView(
                          petId: widget.petId,
                          recordType: widget.recordType,
                          calendarCat: _meta.calendarCat,
                          accentColor: _meta.accent,
                          entries: entries,
                          onEdit: _openEdit,
                          onAdd: _openAdd,
                        )
                      : _RecordListView(
                          recordType: widget.recordType,
                          accentColor: _meta.accent,
                          entries: entries,
                          onEdit: _openEdit,
                        ),
                ),
              ),
            ],
          ),
          if (_editor != null)
            _EditorSheet(
              recordType: widget.recordType,
              editor: _editor!,
              accentColor: _meta.accent,
              onChanged: (e) => setState(() => _editor = e),
              onSave: _save,
              onDelete: _delete,
              onClose: () => setState(() => _editor = null),
            ),
        ],
      ),
    );
  }

  // ── 변환 헬퍼 ────────────────────────────────────────────────
  RecordEntry _fromCleaning(CleaningRecord r) {
    final label = switch (r.cleaningType) {
      CleaningType.FULL => '전체 청소',
      CleaningType.PARTIAL => '부분 청소',
      CleaningType.WATER_CHANGE => '물 교체',
    };
    return RecordEntry(
      id: r.id, dateStr: _dateStr(r.cleanedAt),
      timeStr: _timeStr(r.cleanedAt), summary: label, raw: r);
  }

  RecordEntry _fromMemo(Memo r) => RecordEntry(
    id: r.id, dateStr: _dateStr(r.loggedAt),
    timeStr: _timeStr(r.loggedAt), summary: r.displayContent, raw: r,
    editable: r.editable);

  RecordEntry _fromMating(MatingRecord r) {
    final label = r.isSuccessful == true
        ? '성공'
        : r.isSuccessful == false ? '실패' : '결과 미정';
    return RecordEntry(
      id: r.id, dateStr: _dateStr(r.triedAt),
      timeStr: _timeStr(r.triedAt), summary: label, raw: r);
  }

  RecordEntry _fromLaying(LayingRecord r) => RecordEntry(
    id: r.id, dateStr: _dateStr(r.laidAt),
    timeStr: _timeStr(r.laidAt), summary: '${r.totalCount}개', raw: r);

  Map<String, dynamic> _defaultForm() => switch (widget.recordType) {
    'cleaning' => {'cleaningType': CleaningType.FULL, 'memo': ''},
    'memo'     => {'content': '', 'tags': <String>[], 'memo': ''},
    'mating'   => {'isSuccessful': null, 'memo': ''},
    'laying'   => {'totalCount': 1, 'memo': ''},
    _ => {},
  };

  Map<String, dynamic> _entryToForm(RecordEntry entry) {
    switch (widget.recordType) {
      case 'cleaning':
        final r = entry.raw as CleaningRecord;
        return {'cleaningType': r.cleaningType, 'memo': r.memo ?? ''};
      case 'memo':
        final r = entry.raw as Memo;
        // VET 태그·vetExt는 이 폼에서 편집하지 않지만 저장 시 보존해야 함
        return {
          'content': r.content,
          'tags': List<String>.from(r.tags),
          'vetExt': r.vetExt,
          'memo': '',
        };
      case 'mating':
        final r = entry.raw as MatingRecord;
        return {'isSuccessful': r.isSuccessful, 'memo': r.memo ?? ''};
      case 'laying':
        final r = entry.raw as LayingRecord;
        return {'totalCount': r.totalCount, 'memo': r.memo ?? ''};
      default:
        return {};
    }
  }

  // 서버 시각은 UTC — 로컬(KST) 벽시계로 변환해 표시 (이미 로컬이면 무해)
  static String _dateStr(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _timeStr(DateTime dt) {
    final d = dt.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _todayStr() => _dateStr(DateTime.now());
}

// ── TopBar ────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String petName;
  final VoidCallback onAdd;

  const _TopBar({required this.onBack, required this.title,
      required this.petName, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: AppColors.primary),
          ),
        ),
        const Spacer(),
        Column(children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -0.2)),
          if (petName.isNotEmpty)
            Text(petName.toUpperCase(), style: AppTextStyles.monoXs),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(children: [
              const Icon(Icons.add, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text('기록', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.paleBg)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── 세그먼트 ────────────────────────────────────────────────────
class _Segment extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _Segment({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.paleBgAlt,
          borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _SegTab(label: '캘린더', icon: Icons.calendar_today_outlined,
            active: index == 0, onTap: () => onChanged(0)),
        const SizedBox(width: 4),
        _SegTab(label: '리스트', icon: Icons.list_outlined,
            active: index == 1, onTap: () => onChanged(1)),
      ]),
    );
  }
}

class _SegTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SegTab({required this.label, required this.icon,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.card : Colors.transparent,
            border: active ? Border.all(color: AppColors.paleLine) : null,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: active ? AppColors.primary : AppColors.paleInk3),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.paleInk2)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 기록 카드 ────────────────────────────────────────────────────
class _RecordCard extends StatelessWidget {
  final RecordEntry entry;
  final Color accentColor;
  final VoidCallback onEdit;
  final bool showDate;

  const _RecordCard({required this.entry, required this.accentColor,
      required this.onEdit, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDate)
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(entry.dateStr.substring(8), style: AppTextStyles.monoBody),
                  Text('${int.parse(entry.dateStr.substring(5, 7))}월',
                      style: AppTextStyles.monoXxs),
                  const SizedBox(height: 3),
                  Text(entry.timeStr, style: AppTextStyles.monoXxs),
                ],
              ),
            ),
          if (showDate) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: accentColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.summary,
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                // Memo line (if applicable)
                Builder(builder: (_) {
                  String? memo;
                  final raw = entry.raw;
                  if (raw is CleaningRecord && raw.memo != null) memo = raw.memo;
                  else if (raw is MatingRecord && raw.memo != null) memo = raw.memo;
                  else if (raw is LayingRecord && raw.memo != null) memo = raw.memo;
                  if (memo == null || memo.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(memo,
                        style: TextStyle(fontSize: 12,
                            color: AppColors.paleInk2),
                        overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppColors.paleBg,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 14, color: AppColors.paleInk2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 캘린더 뷰 ────────────────────────────────────────────────────
class _CalendarView extends ConsumerStatefulWidget {
  final int petId;
  final String recordType;
  final String calendarCat;
  final Color accentColor;
  final List<RecordEntry> entries;
  final ValueChanged<RecordEntry> onEdit;
  final ValueChanged<String?> onAdd;

  const _CalendarView({
    required this.petId, required this.recordType,
    required this.calendarCat, required this.accentColor,
    required this.entries, required this.onEdit, required this.onAdd,
  });

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  // 진입 시엔 항상 **이번 달 / 오늘** — 기록이 있는 마지막 달로 점프하지 않는다
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late String _selDate = todayIso();

  String get _ymStr =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  Map<String, List<RecordEntry>> get _byDate {
    final map = <String, List<RecordEntry>>{};
    for (final e in widget.entries) {
      if (e.dateStr.startsWith(_ymStr)) {
        map.putIfAbsent(e.dateStr, () => []).add(e);
      }
    }
    return map;
  }

  /// 셀 본문. 기록이 없으면 null.
  ///
  /// [catDays] 는 서버 월별 집계라 목록(entries)보다 넓을 수 있다.
  /// 집계에는 있는데 목록에 없는 날은 내용 대신 점만 찍어 "뭔가 있음"을 알린다.
  Widget? _cellContent(
      Map<String, List<RecordEntry>> byDate, Set<String> catDays, String date) {
    final recs = byDate[date];
    if (recs == null || recs.isEmpty) {
      if (!catDays.contains(date)) return null;
      return Padding(
        padding: const EdgeInsets.only(left: 2, top: 1),
        child: Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
              color: widget.accentColor, shape: BoxShape.circle),
        ),
      );
    }
    const maxLines = 3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in recs.take(maxLines))
          CalendarCellLine(
            dotColor: widget.accentColor,
            label: e.summary.isEmpty ? e.timeStr : e.summary,
          ),
        if (recs.length > maxLines) CalendarCellMore(recs.length - maxLines),
      ],
    );
  }

  void _openDaySheet(String date, List<RecordEntry> recs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _DaySheet(
        date: date,
        entries: recs,
        accentColor: widget.accentColor,
        // 편집 오버레이는 이 화면(Stack) 소유라, 시트를 먼저 닫고 띄운다
        onEdit: (e) {
          Navigator.pop(sheetCtx);
          widget.onEdit(e);
        },
        onAdd: () {
          Navigator.pop(sheetCtx);
          widget.onAdd(date);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(petCalendarProvider(PetYearMonth(widget.petId, _ymStr)));
    final byDate = _byDate;
    final monthCount = widget.entries.where((e) => e.dateStr.startsWith(_ymStr)).length;

    // calendar days with this category
    final catDays = <String>{};
    calAsync.whenOrNull(data: (days) {
      for (final d in days) {
        if (d.categories.contains(widget.calendarCat)) catDays.add(d.date);
      }
    });

    return MonthGridCalendar(
      month: _month,
      selectedDate: _selDate,
      monthSummary: '$monthCount건',
      accent: widget.accentColor,
      onMonthChanged: (m) => setState(() => _month = m),
      onDayTap: (ds) {
        setState(() => _selDate = ds);
        _openDaySheet(ds, byDate[ds] ?? const []);
      },
      cellBuilder: (ds) => _cellContent(byDate, catDays, ds),
    );
  }
}

// ── 날짜별 상세 바텀시트 ─────────────────────────────────────
class _DaySheet extends StatelessWidget {
  final String date;
  final List<RecordEntry> entries;
  final Color accentColor;
  final ValueChanged<RecordEntry> onEdit;
  final VoidCallback onAdd;

  const _DaySheet({
    required this.date,
    required this.entries,
    required this.accentColor,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: entries.isEmpty ? 0.34 : 0.55,
      minChildSize: 0.28,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.paleBg,
          border: Border(top: BorderSide(color: AppColors.paleLine, width: 1.5)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.paleLine,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(text: TextSpan(
                    style: AppTextStyles.paleSectionTitle,
                    children: [
                      TextSpan(text:
                        '${int.parse(date.substring(5, 7))}.${int.parse(date.substring(8))} '),
                      TextSpan(text: '(${_weekKo[DateTime.parse(date).weekday % 7]})',
                          style: const TextStyle(fontWeight: FontWeight.w600,
                              color: AppColors.paleInk2)),
                    ],
                  )),
                  Text('${entries.length}건', style: AppTextStyles.monoSm),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                children: [
                  if (entries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.paleLine, width: 1.5),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text('이 날의 기록이 없어요',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.paleInk3)),
                    )
                  else
                    ...entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecordCard(entry: e, accentColor: accentColor,
                              onEdit: () => onEdit(e), showDate: false),
                        )),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('이 날 기록 추가',
                              style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 리스트 뷰 ─────────────────────────────────────────────────
class _RecordListView extends StatefulWidget {
  final String recordType;
  final Color accentColor;
  final List<RecordEntry> entries;
  final ValueChanged<RecordEntry> onEdit;

  const _RecordListView({required this.recordType, required this.accentColor,
      required this.entries, required this.onEdit});

  @override
  State<_RecordListView> createState() => _RecordListViewState();
}

class _RecordListViewState extends State<_RecordListView> {
  static const _page = 8;
  int _count = _page;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      setState(() =>
          _count = (_count + _page).clamp(0, widget.entries.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.entries.take(_count).toList();
    final items = <({bool isMonth, String? monthKey, RecordEntry? entry})>[];
    String? lastMonth;
    for (final e in visible) {
      final mk = e.dateStr.substring(0, 7);
      if (mk != lastMonth) {
        items.add((isMonth: true, monthKey: mk, entry: null));
        lastMonth = mk;
      }
      items.add((isMonth: false, monthKey: null, entry: e));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('전체 기록', style: AppTextStyles.paleSectionTitle),
                Text('${widget.entries.length}건', style: AppTextStyles.monoSm),
              ],
            ),
          );
        }
        final item = items[i - 1];
        if (item.isMonth) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
            child: Row(children: [
              Text(item.monthKey!.replaceAll('-', '.'),
                  style: AppTextStyles.monoSm),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 1, color: AppColors.paleLineSoft)),
            ]),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecordCard(
            entry: item.entry!,
            accentColor: widget.accentColor,
            onEdit: () => widget.onEdit(item.entry!),
          ),
        );
      },
    );
  }
}

// ── 에디터 시트 ──────────────────────────────────────────────────
class _EditorSheet extends StatefulWidget {
  final String recordType;
  final _EditorState editor;
  final Color accentColor;
  final ValueChanged<_EditorState> onChanged;
  final VoidCallback onSave;
  final ValueChanged<int> onDelete;
  final VoidCallback onClose;

  const _EditorSheet({
    required this.recordType, required this.editor,
    required this.accentColor, required this.onChanged,
    required this.onSave, required this.onDelete, required this.onClose,
  });

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  late final TextEditingController _memoCtrl;
  late final TextEditingController _contentCtrl;
  late int _count;

  @override
  void initState() {
    super.initState();
    _memoCtrl = TextEditingController(
        text: widget.editor.form['memo'] as String? ?? '');
    _contentCtrl = TextEditingController(
        text: widget.editor.form['content'] as String? ?? '');
    _count = widget.editor.form['totalCount'] as int? ?? 1;
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _shiftDate(int days) {
    final parts = widget.editor.dateStr.split('-').map(int.parse).toList();
    final dt = DateTime(parts[0], parts[1], parts[2] + days);
    widget.onChanged(widget.editor.copyWith(
      dateStr: '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
    ));
  }

  void _updateForm(String key, dynamic value) {
    widget.onChanged(widget.editor.copyWith(
      form: {...widget.editor.form, key: value},
    ));
  }

  bool get _canSave {
    if (widget.recordType == 'memo') {
      // 내용을 적었거나, 분류를 하나 골랐으면 저장 가능 (FAB 메모 폼과 동일)
      final hasContent =
          (widget.editor.form['content'] as String? ?? '').trim().isNotEmpty;
      final hasTag =
          (widget.editor.form['tags'] as List? ?? const []).isNotEmpty;
      return hasContent || hasTag;
    }
    if (widget.recordType == 'laying') {
      return (_count) > 0;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.editor;
    final dt = DateTime.parse(e.dateStr);
    final title = e.isEdit ? '기록 수정' : '기록 추가';

    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0, top: 70,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) =>
                FractionalTranslation(translation: Offset(0, t), child: child),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.paleBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(children: [
              // drag handle
              Container(
                width: 44, height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                    color: AppColors.paleLine,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // 헤더 + 날짜 스테퍼
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 2, 22, 12),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: AppColors.primary, letterSpacing: -0.4)),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border.all(color: AppColors.paleLine),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 16, color: AppColors.paleInk2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 날짜 스테퍼
                  Row(children: [
                    AppNavButton(onTap: () => _shiftDate(-1)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.paleLine),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.dateStr.replaceAll('-', '.'),
                                style: AppTextStyles.mono(14, FontWeight.w700)),
                            const SizedBox(width: 6),
                            Text('(${_weekKo[dt.weekday % 7]})',
                                style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.paleInk2)),
                          ],
                        ),
                      ),
                    ),
                    AppNavButton(forward: true, onTap: () => _shiftDate(1)),
                  ]),
                ]),
              ),
              // 폼 본문
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 청소 종류 (FAB 기록 시트와 동일한 폼) ──
                      if (widget.recordType == 'cleaning') ...[
                        const Text('청소 종류',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            (CleaningType.FULL, '전체 청소',
                                Icons.cleaning_services_outlined),
                            (CleaningType.PARTIAL, '부분 청소',
                                Icons.brush_outlined),
                            (CleaningType.WATER_CHANGE, '물 교체',
                                Icons.water_drop_outlined),
                          ].map((t) {
                            final sel = e.form['cleaningType'] == t.$1;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _updateForm('cleaningType', t.$1),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: sel ? AppColors.petSky : AppColors.card,
                                      border: Border.all(
                                          color: sel
                                              ? AppColors.petSkyInk
                                              : AppColors.paleLine,
                                          width: sel ? 1.5 : 1),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(t.$3, size: 20,
                                            color: sel
                                                ? AppColors.petSkyInk
                                                : AppColors.paleInk2),
                                        const SizedBox(height: 5),
                                        Text(t.$2,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: sel
                                                    ? AppColors.petSkyInk
                                                    : AppColors.paleInk2)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // ── 메모(메모 기록) ───────────────────
                      if (widget.recordType == 'memo') ...[
                        // ── 분류 (병원/탈피/배변/행동/기타 — 단일 선택 라디오, FAB 메모 폼과 동일) ──
                        Row(children: [
                          const Text('분류',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(width: 6),
                          Text('OPTIONAL', style: AppTextStyles.monoXxs),
                        ]),
                        const SizedBox(height: 8),
                        Consumer(builder: (context, ref, _) {
                          final tags = ref.watch(memoTagsProvider).valueOrNull ??
                              const <MemoTag>[];
                          if (tags.isEmpty) return const SizedBox.shrink();
                          final selected = List<String>.from(
                              e.form['tags'] as List? ?? const []);
                          final selectedCode =
                              selected.isEmpty ? null : selected.first;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((t) {
                              final sel = selectedCode == t.code;
                              return GestureDetector(
                                onTap: () => _updateForm(
                                    'tags', sel ? <String>[] : [t.code]),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.petLilac
                                        : AppColors.card,
                                    border: Border.all(
                                        color: sel
                                            ? AppColors.petLilacInk
                                            : AppColors.paleLine,
                                        width: sel ? 1.5 : 1),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 라디오 원형 표시
                                      Container(
                                        width: 16, height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: sel
                                                  ? AppColors.petLilacInk
                                                  : AppColors.paleLine,
                                              width: 1.5),
                                        ),
                                        child: sel
                                            ? Center(
                                                child: Container(
                                                  width: 8, height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        AppColors.petLilacInk,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(t.labelKo,
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: sel
                                                  ? AppColors.petLilacInk
                                                  : AppColors.paleInk2)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 16),

                        const Text('내용',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentCtrl,
                          maxLines: 4,
                          onChanged: (v) => _updateForm('content', v),
                          decoration: AppInputStyles.textarea(
                            hintText: '관찰한 내용을 기록해요 (선택)',
                          ),
                        ),
                      ],

                      // ── 교배 ──────────────────────────────
                      if (widget.recordType == 'mating') ...[
                        const Text('결과',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: AppChip(
                                label: '미정',
                                selected: e.form['isSuccessful'] == null,
                                selectedColor: AppColors.paleBgAlt,
                                selectedBorderColor: AppColors.paleLine,
                                selectedTextColor: AppColors.paleInk2,
                                centered: true,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                onTap: () => _updateForm('isSuccessful', null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppChip(
                                label: '성공',
                                selected: e.form['isSuccessful'] == true,
                                selectedColor: AppColors.petSage,
                                selectedTextColor: AppColors.primary,
                                centered: true,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                onTap: () => _updateForm('isSuccessful', true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppChip(
                                label: '실패',
                                selected: e.form['isSuccessful'] == false,
                                selectedColor: AppColors.petCoral,
                                selectedTextColor: AppColors.primary,
                                centered: true,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                onTap: () => _updateForm('isSuccessful', false),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── 산란 ──────────────────────────────
                      if (widget.recordType == 'laying') ...[
                        const Text('산란 수',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.paleLine),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Row(children: [
                            AppStepperButton('−',
                                onTap: () => setState(() {
                                  _count = (_count - 1).clamp(1, 999);
                                  _updateForm('totalCount', _count);
                                })),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$_count', style: AppTextStyles.mono(20, FontWeight.w700)),
                                  const SizedBox(width: 6),
                                  Text('개', style: TextStyle(fontSize: 13, color: AppColors.paleInk2)),
                                ],
                              ),
                            ),
                            AppStepperButton('+',
                                onTap: () => setState(() {
                                  _count = (_count + 1).clamp(1, 999);
                                  _updateForm('totalCount', _count);
                                })),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, children: [1, 3, 5, 10, 20].map((n) {
                          final active = _count == n;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _count = n;
                              _updateForm('totalCount', n);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: active ? widget.accentColor : AppColors.paleBg,
                                border: Border.all(color: active ? Colors.transparent : AppColors.paleLine),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text('$n개', style: AppTextStyles.mono(11, FontWeight.w700)),
                            ),
                          );
                        }).toList()),
                      ],

                      // ── 공통 메모 (memo 타입 제외) ─────────
                      if (widget.recordType != 'memo') ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          const Text('메모',
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(width: 6),
                          Text('OPTIONAL', style: AppTextStyles.monoXxs),
                        ]),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _memoCtrl,
                          onChanged: (v) => _updateForm('memo', v),
                          maxLines: 2,
                          decoration: AppInputStyles.textarea(
                            hintText: '메모 (선택)',
                          ),
                        ),
                      ],

                      // 삭제 버튼
                      if (e.isEdit && e.editId != null) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => widget.onDelete(e.editId!),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0x66E53935)),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                SizedBox(width: 6),
                                Text('이 기록 삭제',
                                    style: TextStyle(fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // 푸터
              Container(
                padding: EdgeInsets.fromLTRB(
                    22, 12, 22, MediaQuery.of(context).padding.bottom + 12),
                decoration: const BoxDecoration(
                  color: AppColors.paleBg,
                  border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Text('취소',
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _canSave ? widget.onSave : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _canSave ? AppColors.primary : AppColors.paleLine,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 16,
                                color: _canSave ? AppColors.paleBg : AppColors.paleInk3),
                            const SizedBox(width: 8),
                            Text(e.isEdit ? '수정 완료' : '저장',
                                style: TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _canSave ? AppColors.paleBg : AppColors.paleInk3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
            ),
          ),
        ),
      ]),
    );
  }
}

