import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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

  const RecordEntry({
    required this.id,
    required this.dateStr,
    required this.timeStr,
    required this.summary,
    required this.raw,
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
        final content = (e.form['content'] as String).trim();
        if (content.isEmpty) {
          showToast(context, '내용을 입력하세요', type: ToastType.error);
          return;
        }
        if (e.isEdit && e.editId != null) {
          await repo.updateMemo(e.editId!, {
            'content': content,
            'loggedAt': dateTime,
          });
        } else {
          await repo.addMemo(widget.petId, {
            'content': content,
            'loggedAt': dateTime,
          });
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
    timeStr: _timeStr(r.loggedAt), summary: r.content, raw: r);

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
    'memo'     => {'content': '', 'memo': ''},
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
        return {'content': r.content, 'memo': ''};
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

  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
              borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(12)),
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
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [const BoxShadow(color: Color(0x08000000),
                    blurRadius: 2, offset: Offset(0, 1))]
                : null,
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
        borderRadius: BorderRadius.circular(14),
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
                borderRadius: BorderRadius.circular(9),
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
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selDate;

  @override
  void initState() {
    super.initState();
    if (widget.entries.isNotEmpty) {
      final d = widget.entries.first.dateStr;
      _month = DateTime(int.parse(d.substring(0, 4)), int.parse(d.substring(5, 7)));
    }
  }

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

  String get _selOrLatest {
    if (_selDate != null && _selDate!.startsWith(_ymStr)) return _selDate!;
    final dates = _byDate.keys.toList()..sort();
    if (dates.isEmpty) return '$_ymStr-01';
    return dates.last;
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(petCalendarProvider(PetYearMonth(widget.petId, _ymStr)));
    final byDate = _byDate;
    final selDate = _selOrLatest;
    final selRecs = byDate[selDate] ?? [];
    final monthCount = widget.entries.where((e) => e.dateStr.startsWith(_ymStr)).length;
    final firstWD = DateTime(_month.year, _month.month, 1).weekday % 7;
    final dim = DateTime(_month.year, _month.month + 1, 0).day;

    // calendar days with this category
    final catDays = <String>{};
    calAsync.whenOrNull(data: (days) {
      for (final d in days) {
        if (d.categories.contains(widget.calendarCat)) catDays.add(d.date);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(children: [
              // 월 이동
              Row(children: [
                _NavBtn(onTap: () => setState(() =>
                    _month = DateTime(_month.year, _month.month - 1))),
                const Spacer(),
                Column(children: [
                  Text('${_month.year}.${_month.month.toString().padLeft(2, '0')}',
                      style: AppTextStyles.mono(15, FontWeight.w700)),
                  Text('$monthCount건', style: AppTextStyles.monoXxs),
                ]),
                const Spacer(),
                _NavBtn(forward: true, onTap: () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1))),
              ]),
              const SizedBox(height: 10),
              // 요일 헤더
              Row(children: List.generate(7, (i) => Expanded(
                child: Text(_weekKo[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: i == 0
                            ? AppColors.petCoralInk
                            : i == 6 ? AppColors.petSkyInk : AppColors.paleInk3)),
              ))),
              const SizedBox(height: 4),
              // 날짜 그리드
              ...() {
                final cells = [
                  ...List.generate(firstWD, (_) => null),
                  ...List.generate(dim, (i) => i + 1),
                ];
                return List.generate((cells.length / 7).ceil(), (r) => Row(
                  children: List.generate(7, (c) {
                    final idx = r * 7 + c;
                    if (idx >= cells.length || cells[idx] == null) {
                      return const Expanded(child: SizedBox(height: 42));
                    }
                    final d = cells[idx]!;
                    final ds = '$_ymStr-${d.toString().padLeft(2, '0')}';
                    final sel = ds == selDate;
                    final hasRec = catDays.contains(ds);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selDate = ds),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(children: [
                            Container(
                              width: 30, height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : hasRec ? AppColors.paleBgAlt : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text('$d',
                                  style: AppTextStyles.mono(
                                      13, sel ? FontWeight.w700 : FontWeight.w600,
                                      color: sel ? AppColors.paleBg : AppColors.primary)),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: 5,
                              child: hasRec
                                  ? Center(child: Container(
                                      width: 4, height: 4,
                                      decoration: BoxDecoration(
                                          color: widget.accentColor,
                                          shape: BoxShape.circle)))
                                  : null,
                            ),
                          ]),
                        ),
                      ),
                    );
                  }),
                ));
              }(),
            ]),
          ),
          const SizedBox(height: 20),

          // 선택일 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(text: TextSpan(
                style: AppTextStyles.paleSectionTitle,
                children: [
                  TextSpan(text:
                    '${int.parse(selDate.substring(5, 7))}.${int.parse(selDate.substring(8))} '),
                  TextSpan(text: '(${_weekKo[DateTime.parse(selDate).weekday % 7]})',
                      style: const TextStyle(fontWeight: FontWeight.w600,
                          color: AppColors.paleInk2)),
                ],
              )),
              Text('${selRecs.length}건', style: AppTextStyles.monoSm),
            ],
          ),
          const SizedBox(height: 10),

          // 선택일 기록 목록
          if (selRecs.isEmpty)
            GestureDetector(
              onTap: () => widget.onAdd(selDate),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.paleLine, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  Text('이 날의 기록이 없어요',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.paleInk3)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: AppColors.paleBgAlt,
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add, size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      const Text('기록 추가',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ]),
                  ),
                ]),
              ),
            )
          else ...[
            ...selRecs.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecordCard(entry: e, accentColor: widget.accentColor,
                  onEdit: () => widget.onEdit(e), showDate: false),
            )),
            GestureDetector(
              onTap: () => widget.onAdd(selDate),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.paleLine),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add, size: 16, color: AppColors.paleInk2),
                  const SizedBox(width: 6),
                  Text('이 날 기록 더 추가',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.paleInk2)),
                ]),
              ),
            ),
          ],
        ],
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
      return (widget.editor.form['content'] as String? ?? '').trim().isNotEmpty;
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
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.paleBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [BoxShadow(
                  color: Color(0x2D1C1610), blurRadius: 40, offset: Offset(0, -10))],
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
                    _NavBtn(onTap: () => _shiftDate(-1)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.paleLine),
                          borderRadius: BorderRadius.circular(10),
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
                    _NavBtn(forward: true, onTap: () => _shiftDate(1)),
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
                      // ── 청소 ──────────────────────────────
                      if (widget.recordType == 'cleaning') ...[
                        const Text('청소 종류',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 10),
                        SegmentedButton<CleaningType>(
                          segments: const [
                            ButtonSegment(value: CleaningType.FULL, label: Text('전체')),
                            ButtonSegment(value: CleaningType.PARTIAL, label: Text('부분')),
                            ButtonSegment(value: CleaningType.WATER_CHANGE, label: Text('물교체')),
                          ],
                          selected: {e.form['cleaningType'] as CleaningType},
                          onSelectionChanged: (s) => _updateForm('cleaningType', s.first),
                        ),
                      ],

                      // ── 메모(메모 기록) ───────────────────
                      if (widget.recordType == 'memo') ...[
                        const Text('내용',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentCtrl,
                          maxLines: 4,
                          onChanged: (v) => _updateForm('content', v),
                          decoration: InputDecoration(
                            hintText: '메모 내용을 입력하세요',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.paleLine)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.paleLine)),
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
                        SegmentedButton<bool?>(
                          segments: const [
                            ButtonSegment(value: null,  label: Text('미정')),
                            ButtonSegment(value: true,  label: Text('성공')),
                            ButtonSegment(value: false, label: Text('실패')),
                          ],
                          selected: {e.form['isSuccessful'] as bool?},
                          onSelectionChanged: (s) =>
                              _updateForm('isSuccessful', s.first),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            _StepperBtn(label: '−',
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
                            _StepperBtn(label: '+',
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
                                borderRadius: BorderRadius.circular(999),
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
                          decoration: InputDecoration(
                            hintText: '메모 (선택)',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.paleLine)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.paleLine)),
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
                              borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(14),
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
                          borderRadius: BorderRadius.circular(14),
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
      ]),
    );
  }
}

// ── 공유 서브 위젯 ────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool forward;
  const _NavBtn({required this.onTap, this.forward = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        margin: EdgeInsets.only(
            right: forward ? 0 : 8, left: forward ? 8 : 0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(forward ? Icons.chevron_right : Icons.chevron_left,
            size: 18, color: AppColors.primary),
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepperBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: label == '−'
                ? const BorderSide(color: AppColors.paleLine)
                : BorderSide.none,
            left: label == '+'
                ? const BorderSide(color: AppColors.paleLine)
                : BorderSide.none,
          ),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ),
    );
  }
}
