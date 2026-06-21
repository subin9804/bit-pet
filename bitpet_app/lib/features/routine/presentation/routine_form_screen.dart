import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';

// ════════════════════════════════════════════════════════════════
// 02ds · 루틴 등록 — 5단계 스텝 위저드
// 1) 타입+이름  2) 대상 개체  3) 반복 주기+시작일  4) 알림  5) 확인
// ════════════════════════════════════════════════════════════════

// ── 루틴 타입 색·라벨 ────────────────────────────────────────────────────────

const _rtypeBg = {
  RoutineType.FEEDING:  AppColors.petPeach,
  RoutineType.CLEANING: AppColors.petSky,
  RoutineType.WEIGHT:   AppColors.petSage,
  RoutineType.CUSTOM:   AppColors.petLilac,
};

const _rtypeInk = {
  RoutineType.FEEDING:  AppColors.petPeachInk,
  RoutineType.CLEANING: AppColors.petSkyInk,
  RoutineType.WEIGHT:   AppColors.petSageInk,
  RoutineType.CUSTOM:   AppColors.petLilacInk,
};

const _rtypeLabel = {
  RoutineType.FEEDING:  '피딩',
  RoutineType.CLEANING: '청소',
  RoutineType.WEIGHT:   '체중',
  RoutineType.CUSTOM:   '사용자 정의',
};

const _rtypeIcon = {
  RoutineType.FEEDING:  Icons.restaurant_outlined,
  RoutineType.CLEANING: Icons.cleaning_services_outlined,
  RoutineType.WEIGHT:   Icons.monitor_weight_outlined,
  RoutineType.CUSTOM:   Icons.star_outline,
};

const _rtypeDefaultTitle = {
  RoutineType.FEEDING:  '급여',
  RoutineType.CLEANING: '사육장 청소',
  RoutineType.WEIGHT:   '체중 측정',
  RoutineType.CUSTOM:   '',
};

// ── 반복 주기 모드 ────────────────────────────────────────────────────────────

enum _CycleMode { interval, weekday, monthday }

const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

const _intervalPresets = [
  (1, '매일'), (2, '2일'), (3, '3일'), (7, '주 1회'), (14, '2주'), (30, '월 1회'),
];

// ════════════════════════════════════════════════════════════════

class RoutineFormScreen extends ConsumerStatefulWidget {
  final Routine? initialRoutine;
  const RoutineFormScreen({super.key, this.initialRoutine});

  @override
  ConsumerState<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends ConsumerState<RoutineFormScreen> {
  // ── 상태 ────────────────────────────────────────────────────────────────────
  RoutineType _type = RoutineType.FEEDING;
  late final TextEditingController _titleCtrl;
  bool _titleEdited = false;

  Set<int> _petIds = {};
  String _petQuery = '';
  String _petFilter = 'all'; // all/gecko/snake/lizard

  _CycleMode _cycleMode = _CycleMode.interval;
  int _interval = 3;
  Set<int> _weekdays = {1, 3, 5}; // 0=일~6=토
  Set<int> _monthDays = {1}; // 1~31, 32=말일

  String _startDate = _todayIso();

  int _alarmHour   = 9;
  int _alarmMinute = 0;
  bool _alarmOn    = true;

  // ── 헬퍼 ─────────────────────────────────────────────────────────────────
  static String _todayIso() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  Color get _typeBg  => _rtypeBg[_type]!;
  Color get _typeInk => _rtypeInk[_type]!;

  String get _alarmTime =>
      '${_alarmHour.toString().padLeft(2,'0')}:${_alarmMinute.toString().padLeft(2,'0')}';

  String get _cycleSummaryFull {
    switch (_cycleMode) {
      case _CycleMode.interval:
        final preset = _intervalPresets.where((p) => p.$1 == _interval);
        return preset.isNotEmpty ? preset.first.$2 : '${_interval}일마다';
      case _CycleMode.weekday:
        if (_weekdays.isEmpty) return '요일 미선택';
        if (_weekdays.length == 7) return '매일';
        final sorted = _weekdays.toList()..sort();
        return sorted.map((d) => _weekKo[d]).join('·');
      case _CycleMode.monthday:
        if (_monthDays.isEmpty) return '날짜 미선택';
        final sorted = _monthDays.toList()..sort();
        return '매월 ${sorted.map((d) => d == 32 ? '말일' : '${d}일').join('·')}';
    }
  }

  int get _cycleDays {
    switch (_cycleMode) {
      case _CycleMode.interval: return _interval;
      case _CycleMode.weekday:  return 1;
      case _CycleMode.monthday: return 30;
    }
  }

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '—';
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final y = parts[0], m = parts[1], d = parts[2];
    final wd = _weekKo[DateTime(int.parse(y), int.parse(m), int.parse(d)).weekday % 7];
    return '$y.$m.$d ($wd)';
  }

  void _pickType(RoutineType ty) {
    setState(() {
      _type = ty;
      if (!_titleEdited) _titleCtrl.text = _rtypeDefaultTitle[ty]!;
    });
  }

  bool get _isEditing => widget.initialRoutine != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoutine;
    if (r != null) {
      _type        = r.routineType;
      _titleCtrl   = TextEditingController(text: r.title);
      _titleEdited = true;
      _petIds      = Set<int>.from(r.petIds);
      _interval    = r.cycleDays;
      if (r.alarmTime != null) {
        final parts = r.alarmTime!.split(':');
        if (parts.length == 2) {
          _alarmHour   = int.tryParse(parts[0]) ?? 9;
          _alarmMinute = int.tryParse(parts[1]) ?? 0;
        }
      }
      _alarmOn = r.isAlarmEnabled;
    } else {
      _titleCtrl = TextEditingController(text: '급여');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  // ── 제출 ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_isEditing) {
      await ref.read(routineRepositoryProvider).updateRoutine(
        widget.initialRoutine!.id,
        {
          'routineType': _type.name,
          'title': _titleCtrl.text.trim(),
          'cycleDays': _cycleDays,
          'alarmTime': _alarmOn ? _alarmTime : null,
          'alarmEnabled': _alarmOn,
          'petIds': _petIds.toList(),
        },
      );
    } else {
      await ref.read(routineRepositoryProvider).createRoutine(
        CreateRoutineRequest(
          routineType: _type,
          title: _titleCtrl.text.trim(),
          cycleDays: _cycleDays,
          alarmTime: _alarmOn ? _alarmTime : null,
          alarmEnabled: _alarmOn,
          petIds: _petIds.toList(),
        ),
      );
    }
    if (mounted) {
      ref.read(routineListProvider.notifier).load();
      ToastMessage.show(
        context,
        _isEditing ? '루틴이 수정되었습니다!' : '루틴이 등록되었습니다!',
        type: ToastType.success,
      );
      context.pop();
    }
  }

  // ── 스텝 ──────────────────────────────────────────────────────────────────
  List<StepConfig> get _steps => [
    // Step 1 · 타입+이름
    StepConfig(
      title: '어떤 루틴인가요?',
      desc: '종류를 고르고 이름을 정해요.',
      valid: () => _titleCtrl.text.trim().isNotEmpty,
      render: (_) => ListenableBuilder(
        listenable: _titleCtrl,
        builder: (_, __) => Column(
          children: [
            SField(
              label: '루틴 타입',
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.0,
                children: RoutineType.values.map((ty) {
                  final on = _type == ty;
                  return GestureDetector(
                    onTap: () => _pickType(ty),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: on ? _rtypeBg[ty]! : AppColors.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: on ? _rtypeInk[ty]! : AppColors.paleLine,
                          width: on ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: on ? AppColors.surface : _rtypeBg[ty]!,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(_rtypeIcon[ty]!, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _rtypeLabel[ty]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SField(
              label: '루틴 이름',
              child: PaleTextField(
                controller: _titleCtrl,
                placeholder: _type == RoutineType.CUSTOM ? '예: 탈피 체크' : _rtypeDefaultTitle[_type]!,
                onChanged: (v) => setState(() => _titleEdited = v.isNotEmpty),
              ),
            ),
          ],
        ),
      ),
    ),

    // Step 2 · 대상 개체
    StepConfig(
      title: '어떤 개체에 적용할까요?',
      desc: '여러 개체를 한 번에 선택할 수 있어요.',
      valid: () => _petIds.isNotEmpty,
      render: (_) => _PetSelectorStep(
        petIds: _petIds,
        petQuery: _petQuery,
        petFilter: _petFilter,
        onIdsChanged: (ids) => setState(() => _petIds = ids),
        onQueryChanged: (q) => setState(() => _petQuery = q),
        onFilterChanged: (f) => setState(() => _petFilter = f),
      ),
    ),

    // Step 3 · 반복 주기
    StepConfig(
      title: '얼마나 자주 반복할까요?',
      valid: () {
        if (!(_startDate.isNotEmpty)) return false;
        switch (_cycleMode) {
          case _CycleMode.interval:  return _interval >= 1;
          case _CycleMode.weekday:   return _weekdays.isNotEmpty;
          case _CycleMode.monthday:  return _monthDays.isNotEmpty;
        }
      },
      render: (_) => _CycleStep(
        cycleMode: _cycleMode,
        interval: _interval,
        weekdays: _weekdays,
        monthDays: _monthDays,
        startDate: _startDate,
        typeBg: _typeBg,
        onCycleModeChanged: (m) => setState(() => _cycleMode = m),
        onIntervalChanged: (v) => setState(() => _interval = v),
        onWeekdayToggled: (d) => setState(() {
          if (_weekdays.contains(d)) _weekdays.remove(d);
          else _weekdays.add(d);
        }),
        onMonthDayToggled: (d) => setState(() {
          if (_monthDays.contains(d)) _monthDays.remove(d);
          else _monthDays.add(d);
        }),
        onStartDateChanged: (iso) => setState(() => _startDate = iso),
        fmtDate: _fmtDate,
      ),
    ),

    // Step 4 · 알림
    StepConfig(
      title: '알림을 받을까요?',
      desc: '지정한 시간에 푸시로 알려드려요.',
      render: (_) => _AlarmStep(
        alarmHour: _alarmHour,
        alarmMinute: _alarmMinute,
        alarmOn: _alarmOn,
        typeBg: _typeBg,
        cycleSummary: _cycleSummaryFull,
        onTimeChanged: (h, m) => setState(() { _alarmHour = h; _alarmMinute = m; }),
        onAlarmToggled: () => setState(() => _alarmOn = !_alarmOn),
      ),
    ),

    // Step 5 · 확인
    StepConfig(
      title: '루틴을 확인하세요',
      desc: '"수정"으로 각 단계를 다시 고칠 수 있어요.',
      render: (ctx) => Column(
        children: [
          // 미리보기 카드
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.paleLine),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _typeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_rtypeIcon[_type]!, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCtrl.text.trim().isEmpty ? _rtypeLabel[_type]! : _titleCtrl.text.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_petIds.length}마리',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_cycleSummaryFull · $_alarmTime',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _typeInk),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StepSummary(
            goEdit: ctx.goEdit,
            groups: [
              StepSummaryGroup(label: '종류·이름', step: 0, rows: [
                StepSummaryRow(k: '타입', v: _rtypeLabel[_type]!),
                StepSummaryRow(k: '이름', v: _titleCtrl.text),
              ]),
              StepSummaryGroup(label: '대상 개체', step: 1, rows: [
                StepSummaryRow(k: '수', v: '${_petIds.length}마리'),
              ]),
              StepSummaryGroup(label: '반복 주기', step: 2, rows: [
                StepSummaryRow(k: '주기', v: _cycleSummaryFull),
                StepSummaryRow(k: '시작일', v: _fmtDate(_startDate)),
              ]),
              StepSummaryGroup(label: '알림', step: 3, rows: [
                StepSummaryRow(k: '시간', v: _alarmTime),
                StepSummaryRow(k: '알림', v: _alarmOn ? '켜짐' : '꺼짐', muted: !_alarmOn),
              ]),
            ],
          ),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        child: StepShell(
          headerTitle: _isEditing ? '루틴 수정' : '루틴 등록',
          accentInk: _typeInk,
          steps: _steps,
          doneLabel: _isEditing ? '수정 완료' : '루틴 저장',
          initialStep: _isEditing ? _steps.length - 1 : 0,
          alwaysCancel: _isEditing,
          onDone: _submit,
          onCancel: () => context.pop(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Step 2 · 개체 선택 위젯
// ════════════════════════════════════════════════════════════════

class _PetSelectorStep extends ConsumerWidget {
  final Set<int> petIds;
  final String petQuery;
  final String petFilter;
  final void Function(Set<int>) onIdsChanged;
  final void Function(String) onQueryChanged;
  final void Function(String) onFilterChanged;

  const _PetSelectorStep({
    required this.petIds,
    required this.petQuery,
    required this.petFilter,
    required this.onIdsChanged,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  static const _filters = [
    ('all',    '전체'),
    ('gecko',  '게코'),
    ('snake',  '뱀'),
    ('lizard', '도마뱀'),
  ];

  List<Pet> _filtered(List<Pet> pets) {
    final q = petQuery.toLowerCase();
    return pets.where((p) {
      final matchQ = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.speciesName.toLowerCase().contains(q);
      final matchF = petFilter == 'all' ? true :
          petFilter == 'gecko'  ? p.speciesName.contains('게코') :
          petFilter == 'snake'  ? p.speciesName.contains('뱀') || p.speciesName.contains('snake') :
          petFilter == 'lizard' ? p.speciesName.contains('도마뱀') || p.speciesName.contains('드래곤') :
          true;
      return matchQ && matchF;
    }).toList();
  }

  Color _petBg(Pet p) {
    if (p.colorCode == null) return AppColors.paleBgAlt;
    try { return Color(int.parse(p.colorCode!.replaceFirst('#', '0xFF'))); }
    catch (_) { return AppColors.paleBgAlt; }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);

    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        final visible = _filtered(all);
        final allOn = visible.isNotEmpty && visible.every((p) => petIds.contains(p.id));

        void togglePet(int id) {
          final next = Set<int>.from(petIds);
          if (next.contains(id)) next.remove(id);
          else next.add(id);
          onIdsChanged(next);
        }

        void toggleAll() {
          final next = Set<int>.from(petIds);
          if (allOn) {
            next.removeAll(visible.map((p) => p.id));
          } else {
            next.addAll(visible.map((p) => p.id));
          }
          onIdsChanged(next);
        }

        return SField(
          label: '대상 개체',
          hint: '${petIds.length} / ${all.length}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 검색창
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.paleLine),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.paleInk2, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: onQueryChanged,
                        style: const TextStyle(fontSize: 14, color: AppColors.primary),
                        decoration: const InputDecoration(
                          hintText: '이름 또는 종 검색…',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.paleInk3),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 종 필터 칩
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final (id, label) = f;
                    final active = petFilter == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 10),
                      child: GestureDetector(
                        onTap: () => onFilterChanged(id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: active ? null : Border.all(color: AppColors.paleLine),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? AppColors.paleBg : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // 전체 선택
              GestureDetector(
                onTap: visible.isEmpty ? null : toggleAll,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: allOn ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: allOn ? AppColors.primary : AppColors.paleLine,
                            width: 1.5,
                          ),
                        ),
                        child: allOn
                            ? const Icon(Icons.check, size: 12, color: AppColors.paleBg)
                            : null,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        petFilter == 'all' && petQuery.isEmpty ? '전체 선택' : '보이는 개체 모두 선택',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppColors.paleInk2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 개체 그리드
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('검색 결과가 없어요',
                        style: TextStyle(fontSize: 13, color: AppColors.paleInk3, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final p = visible[i];
                    final on = petIds.contains(p.id);
                    final bg = _petBg(p);
                    return GestureDetector(
                      onTap: () => togglePet(p.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: on ? bg : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: on ? bg.withValues(alpha: 0.5) : AppColors.paleLine,
                            width: on ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: on ? AppColors.surface.withValues(alpha: 0.55) : bg,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Center(
                                    child: Text('🦎', style: TextStyle(fontSize: 22)),
                                  ),
                                ),
                                if (on)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 11, color: AppColors.paleBg),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              p.speciesName,
                              style: const TextStyle(fontSize: 9.5, color: AppColors.paleInk3, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Step 3 · 반복 주기 위젯
// ════════════════════════════════════════════════════════════════

class _CycleStep extends StatelessWidget {
  final _CycleMode cycleMode;
  final int interval;
  final Set<int> weekdays;
  final Set<int> monthDays;
  final String startDate;
  final Color typeBg;
  final void Function(_CycleMode) onCycleModeChanged;
  final void Function(int) onIntervalChanged;
  final void Function(int) onWeekdayToggled;
  final void Function(int) onMonthDayToggled;
  final void Function(String) onStartDateChanged;
  final String Function(String) fmtDate;

  const _CycleStep({
    required this.cycleMode,
    required this.interval,
    required this.weekdays,
    required this.monthDays,
    required this.startDate,
    required this.typeBg,
    required this.onCycleModeChanged,
    required this.onIntervalChanged,
    required this.onWeekdayToggled,
    required this.onMonthDayToggled,
    required this.onStartDateChanged,
    required this.fmtDate,
  });

  String _todayOffset(int offset) {
    final d = DateTime.now().add(Duration(days: offset));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayOffset(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시작일
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('시작일', style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.2,
          )),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(startDate) ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              onStartDateChanged('${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.paleLine),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fmtDate(startDate), style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary,
                      )),
                      const Text('이 날짜부터 반복이 시작돼요', style: TextStyle(
                        fontSize: 11, color: AppColors.paleInk3, fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.paleInk3, size: 18),
              ],
            ),
          ),
        ),
        // 빠른 선택 칩
        Row(
          children: [
            for (final entry in {0: '오늘', 1: '내일', 7: '다음 주'}.entries) ...[
              Builder(builder: (_) {
                final iso = _todayOffset(entry.key);
                final on = startDate == iso;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onStartDateChanged(iso),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? typeBg : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: on ? null : Border.all(color: AppColors.paleLine),
                      ),
                      child: Text(entry.value, style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
                      )),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
        const SizedBox(height: 20),
        // 반복 주기 세그먼트
        const Text('반복 주기', style: TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.2,
        )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.paleBgAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final entry in {
                _CycleMode.interval: '일 단위',
                _CycleMode.weekday: '요일',
                _CycleMode.monthday: '월 단위',
              }.entries)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onCycleModeChanged(entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: cycleMode == entry.key ? AppColors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: cycleMode == entry.key ? Border.all(color: AppColors.paleLine) : null,
                        boxShadow: cycleMode == entry.key
                            ? [const BoxShadow(color: Color(0x0C3A332B), blurRadius: 2)]
                            : null,
                      ),
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: cycleMode == entry.key ? AppColors.primary : AppColors.paleInk2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 주기 컨텐츠
        if (cycleMode == _CycleMode.interval)
          _IntervalPicker(interval: interval, typeBg: typeBg, onChanged: onIntervalChanged)
        else if (cycleMode == _CycleMode.weekday)
          _WeekdayPicker(weekdays: weekdays, onToggle: onWeekdayToggled)
        else
          _MonthdayPicker(monthDays: monthDays, typeBg: typeBg, onToggle: onMonthDayToggled),
      ],
    );
  }
}

class _IntervalPicker extends StatelessWidget {
  final int interval;
  final Color typeBg;
  final void Function(int) onChanged;

  const _IntervalPicker({required this.interval, required this.typeBg, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 스텝퍼
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.paleLine),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onChanged((interval - 1).clamp(1, 365)),
                child: Container(
                  width: 46,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.paleLine)),
                  ),
                  child: const Text('−', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$interval', style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary,
                    )),
                    const SizedBox(width: 6),
                    const Text('일마다', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.paleInk2,
                    )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onChanged((interval + 1).clamp(1, 365)),
                child: Container(
                  width: 46,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.paleLine)),
                  ),
                  child: const Text('＋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 프리셋 칩
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _intervalPresets.map((p) {
            final on = interval == p.$1;
            return GestureDetector(
              onTap: () => onChanged(p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: on ? typeBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: on ? null : Border.all(color: AppColors.paleLine),
                ),
                child: Text(p.$2, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  final Set<int> weekdays;
  final void Function(int) onToggle;

  const _WeekdayPicker({required this.weekdays, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (d) {
        final on = weekdays.contains(d);
        final color = d == 0
            ? AppColors.petCoralInk
            : d == 6
                ? AppColors.petSkyInk
                : AppColors.paleInk2;
        return Expanded(
          child: GestureDetector(
            onTap: () => onToggle(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: d < 6 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: on ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: on ? AppColors.primary : AppColors.paleLine),
              ),
              child: Text(
                _weekKo[d],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: on ? AppColors.paleBg : color,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MonthdayPicker extends StatelessWidget {
  final Set<int> monthDays;
  final Color typeBg;
  final void Function(int) onToggle;

  const _MonthdayPicker({required this.monthDays, required this.typeBg, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '반복할 날짜를 모두 탭하세요 · 여러 날 선택 가능',
          style: TextStyle(fontSize: 11, color: AppColors.paleInk3, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 1,
          ),
          itemCount: 31,
          itemBuilder: (_, i) {
            final d = i + 1;
            final on = monthDays.contains(d);
            return GestureDetector(
              onTap: () => onToggle(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: on ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: on ? AppColors.primary : AppColors.paleLine),
                ),
                child: Center(
                  child: Text('$d', style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: on ? AppColors.paleBg : AppColors.paleInk2,
                  )),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // 말일 버튼
        GestureDetector(
          onTap: () => onToggle(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: monthDays.contains(32) ? typeBg : AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: monthDays.contains(32) ? Colors.transparent : AppColors.paleLine,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: monthDays.contains(32) ? AppColors.primary : AppColors.paleBgAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: monthDays.contains(32)
                      ? const Icon(Icons.check, size: 14, color: AppColors.paleBg)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text('말일', style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary,
                )),
                const Spacer(),
                const Text('매월 마지막 날', style: TextStyle(
                  fontSize: 11, color: AppColors.paleInk3, fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ),
        // 선택 요약 칩
        if (monthDays.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('매월', style: TextStyle(
                fontSize: 11, color: AppColors.paleInk3, fontWeight: FontWeight.w700,
              )),
              ...( monthDays.toList()..sort()).map((d) => Container(
                padding: const EdgeInsets.fromLTRB(9, 3, 4, 3),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d == 32 ? '말일' : '$d일', style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary,
                    )),
                    const SizedBox(width: 3),
                    GestureDetector(
                      onTap: () => onToggle(d),
                      child: const Icon(Icons.close, size: 13, color: AppColors.paleInk2),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Step 4 · 알림 위젯
// ════════════════════════════════════════════════════════════════

class _AlarmStep extends StatelessWidget {
  final int alarmHour, alarmMinute;
  final bool alarmOn;
  final Color typeBg;
  final String cycleSummary;
  final void Function(int, int) onTimeChanged;
  final VoidCallback onAlarmToggled;

  const _AlarmStep({
    required this.alarmHour,
    required this.alarmMinute,
    required this.alarmOn,
    required this.typeBg,
    required this.cycleSummary,
    required this.onTimeChanged,
    required this.onAlarmToggled,
  });

  static const _presets = ['09:00', '12:00', '19:00', '21:00'];

  String get _timeStr =>
      '${alarmHour.toString().padLeft(2, '0')}:${alarmMinute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SField(
          label: '알림 시간',
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.paleLine),
            ),
            child: Column(
              children: [
                // ── 인라인 시간 스피너 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _TimeSpinner(
                      value: alarmHour,
                      min: 0, max: 23,
                      wrap: false,
                      typeBg: typeBg,
                      onDelta: (d) => onTimeChanged((alarmHour + d).clamp(0, 23), alarmMinute),
                      onSubmit: (t) {
                        final v = int.tryParse(t);
                        if (v != null) onTimeChanged(v.clamp(0, 23), alarmMinute);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(':', style: TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w700,
                        color: AppColors.primary, height: 0.9,
                      )),
                    ),
                    _TimeSpinner(
                      value: alarmMinute,
                      min: 0, max: 59,
                      wrap: true,
                      typeBg: typeBg,
                      onDelta: (d) {
                        final m = ((alarmMinute + d) % 60 + 60) % 60;
                        onTimeChanged(alarmHour, m);
                      },
                      onSubmit: (t) {
                        final v = int.tryParse(t);
                        if (v != null) onTimeChanged(alarmHour, v.clamp(0, 59));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── 프리셋 칩 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _presets.map((tp) {
                    final on = tp == _timeStr;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          final parts = tp.split(':').map(int.parse).toList();
                          onTimeChanged(parts[0], parts[1]);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: on ? typeBg : AppColors.paleBg,
                            borderRadius: BorderRadius.circular(999),
                            border: on ? null : Border.all(color: AppColors.paleLine),
                          ),
                          child: Text(tp, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: on ? AppColors.primary : AppColors.paleInk2,
                          )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        // ── 알림 토글 행 ──
        GestureDetector(
          onTap: onAlarmToggled,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.paleLine),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: alarmOn ? typeBg : AppColors.paleBgAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.notifications_outlined, size: 18,
                      color: alarmOn ? AppColors.primary : AppColors.paleInk3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('알림 받기', style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary,
                      )),
                      Text(
                        alarmOn ? '$cycleSummary · $_timeStr에 알려드려요' : '알림 없이 루틴만 기록해요',
                        style: const TextStyle(fontSize: 11, color: AppColors.paleInk3, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44, height: 26,
                  decoration: BoxDecoration(
                    color: alarmOn ? AppColors.primary : AppColors.paleLine,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment: alarmOn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 20, height: 20,
                      decoration: const BoxDecoration(color: AppColors.paleBg, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 시간 스피너 — 위아래 화살표 + 직접 입력
// ════════════════════════════════════════════════════════════════

class _TimeSpinner extends StatefulWidget {
  final int value;
  final int min, max;
  final bool wrap;
  final Color typeBg;
  final void Function(int) onDelta;
  final void Function(String) onSubmit;

  const _TimeSpinner({
    required this.value,
    required this.min,
    required this.max,
    required this.wrap,
    required this.typeBg,
    required this.onDelta,
    required this.onSubmit,
  });

  @override
  State<_TimeSpinner> createState() => _TimeSpinnerState();
}

class _TimeSpinnerState extends State<_TimeSpinner> {
  bool _editing = false;
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEdit() {
    _ctrl.text = widget.value.toString().padLeft(2, '0');
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: 2);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) widget.onSubmit(text);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.value.toString().padLeft(2, '0');
    final canUp   = widget.wrap || widget.value < widget.max;
    final canDown = widget.wrap || widget.value > widget.min;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ▲ 위
        GestureDetector(
          onTap: canUp ? () => widget.onDelta(1) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 64, height: 36,
            decoration: BoxDecoration(
              color: canUp ? AppColors.paleBgAlt : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.keyboard_arrow_up, size: 24,
                color: canUp ? AppColors.paleInk2 : AppColors.paleLine),
          ),
        ),
        const SizedBox(height: 4),
        // 숫자 (탭 → 직접입력)
        GestureDetector(
          onTap: _editing ? null : _startEdit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 80, height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _editing
                  ? widget.typeBg.withValues(alpha: 0.25)
                  : AppColors.paleBgAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _editing ? widget.typeBg : Colors.transparent,
                width: 2,
              ),
            ),
            child: _editing
                ? TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _commit(),
                  )
                : Text(label, style: const TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.primary,
                  )),
          ),
        ),
        const SizedBox(height: 4),
        // ▼ 아래
        GestureDetector(
          onTap: canDown ? () => widget.onDelta(-1) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 64, height: 36,
            decoration: BoxDecoration(
              color: canDown ? AppColors.paleBgAlt : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.keyboard_arrow_down, size: 24,
                color: canDown ? AppColors.paleInk2 : AppColors.paleLine),
          ),
        ),
      ],
    );
  }
}
