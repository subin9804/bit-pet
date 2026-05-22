// Screen 06e: 피딩 기록 바텀시트 (per-pet navigation)
// - 상단 개체 탭 칩
// - 현재 개체 카드 (컬러 bg, 이름, 종, 체중)
// - 급여 종류 드롭다운 (이전 입력값 선택 포함)
// - 급여량 stepper + 퀵 칩
// - 메모 입력
// - 완료/미완료 버튼
// - 다음 개체 / 뒤로 / 닫기
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/data/routine_repository.dart';
import '../../routine/providers/routine_provider.dart';
import '../data/record_repository.dart';

class FeedingRecordSheet extends ConsumerStatefulWidget {
  final TodayRoutine routine;
  final int? initialPetId;
  final bool fromHome; // 홈에서 온 경우 뒤로 버튼 숨김

  const FeedingRecordSheet({
    super.key,
    required this.routine,
    this.initialPetId,
    this.fromHome = false,
  });

  @override
  ConsumerState<FeedingRecordSheet> createState() =>
      _FeedingRecordSheetState();
}

class _FeedingRecordSheetState extends ConsumerState<FeedingRecordSheet> {
  late int _currentIndex;
  final Map<int, _FeedingEntry> _entries = {};
  bool _saving = false;

  // 이전에 사용한 급여 종류 목록 (자동완성)
  final List<String> _foodSuggestions = [
    '귀뚜라미',
    '두비아',
    '밀웜',
    '슈퍼웜',
    '핑키',
  ];

  @override
  void initState() {
    super.initState();
    final pets = widget.routine.petStatuses;
    _currentIndex = widget.initialPetId != null
        ? pets.indexWhere((s) => s.petId == widget.initialPetId)
            .clamp(0, pets.length - 1)
        : 0;
    // 각 개체마다 entry 초기화
    for (final s in pets) {
      _entries[s.petId] = _FeedingEntry();
    }
  }

  List<TodayPetStatus> get _pets => widget.routine.petStatuses;
  TodayPetStatus get _current => _pets[_currentIndex];
  _FeedingEntry get _currentEntry => _entries[_current.petId]!;

  int get _savedCount =>
      _entries.values.where((e) => e.isSaved).length;

  void _prev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _next() {
    if (_currentIndex < _pets.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  Future<void> _toggleComplete() async {
    final entry = _currentEntry;
    if (entry.isSaved) {
      // 미완료로 되돌리기
      setState(() {
        _entries[_current.petId] = _FeedingEntry()..isSaved = false;
      });
      // TODO: 서버 로그 삭제 (logId 있는 경우)
      return;
    }
    // 완료 저장
    setState(() => _saving = true);
    try {
      final repo = ref.read(recordRepositoryProvider);
      await repo.addFeeding(_current.petId, {
        'foodType': entry.foodType.isEmpty ? '기타' : entry.foodType,
        if (entry.amount > 0) 'amount': entry.amount.toDouble(),
        if (entry.unit.isNotEmpty) 'unit': entry.unit,
        if (entry.memo.isNotEmpty) 'memo': entry.memo,
        'fedAt': DateTime.now().toIso8601String(),
        'routineId': widget.routine.id,
      });
      // routineLog도 저장
      await ref.read(routineRepositoryProvider).completeIndividual(
            widget.routine.id,
            RoutineCompleteIndividualRequest(
              petId: _current.petId,
              status: RoutineLogStatus.COMPLETED,
              foodType: entry.foodType.isEmpty ? '기타' : entry.foodType,
              amount: entry.amount > 0 ? entry.amount.toDouble() : null,
              unit: entry.unit.isNotEmpty ? entry.unit : null,
              memo: entry.memo.isNotEmpty ? entry.memo : null,
            ),
          );
      setState(() {
        _entries[_current.petId]!.isSaved = true;
      });
      ref
          .read(todayRoutinesProvider.notifier)
          .updatePetStatus(widget.routine.id, _current.petId, true);
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _petBg(TodayPetStatus s) {
    if (s.colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(s.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FEEDING · PER-PET',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textDisabled),
                      ),
                      Text('피딩 기록', style: AppTextStyles.title),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.petColorPeach,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_pets.length}',
                      style: AppTextStyles.bodyBold
                          .copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            // 개체 탭 칩 (상단 수평 스크롤)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _pets.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _pets[i];
                  final entry = _entries[s.petId]!;
                  final isActive = i == _currentIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _petBg(s)
                            : AppColors.bg2,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? _petBg(s).withOpacity(0.6)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets,
                              size: 13,
                              color: AppColors.primary
                                  .withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(s.petName,
                              style: AppTextStyles.caption
                                  .copyWith(
                                      fontWeight:
                                          FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(
                            entry.isSaved
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 12,
                            color: entry.isSaved
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // 스크롤 가능 바디
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 현재 개체 카드
                    _CurrentPetCard(
                        status: _current, bgColor: _petBg(_current)),
                    const SizedBox(height: 16),
                    // 급여 종류
                    Text('급여 종류',
                        style: AppTextStyles.bodyBold
                            .copyWith(fontSize: 13)),
                    const SizedBox(height: 6),
                    _FoodTypeDropdown(
                      value: _currentEntry.foodType,
                      suggestions: _foodSuggestions,
                      onChanged: (v) => setState(() {
                        _currentEntry.foodType = v;
                        _currentEntry.isSaved = false;
                      }),
                    ),
                    const SizedBox(height: 14),
                    // 급여량
                    Text('급여량',
                        style: AppTextStyles.bodyBold
                            .copyWith(fontSize: 13)),
                    const SizedBox(height: 6),
                    _AmountStepper(
                      amount: _currentEntry.amount,
                      unit: _currentEntry.unit,
                      onAmountChanged: (v) => setState(() {
                        _currentEntry.amount = v;
                        _currentEntry.isSaved = false;
                      }),
                      onUnitChanged: (v) => setState(() {
                        _currentEntry.unit = v;
                        _currentEntry.isSaved = false;
                      }),
                    ),
                    const SizedBox(height: 6),
                    // 퀵 칩
                    _QuickAmountChips(
                      unit: _currentEntry.unit,
                      selected: _currentEntry.amount,
                      onTap: (v) => setState(() {
                        _currentEntry.amount = v;
                        _currentEntry.isSaved = false;
                      }),
                    ),
                    const SizedBox(height: 14),
                    // 메모
                    Row(
                      children: [
                        Text('메모',
                            style: AppTextStyles.bodyBold
                                .copyWith(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text('OPTIONAL',
                            style: AppTextStyles.label
                                .copyWith(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      onChanged: (v) => setState(() {
                        _currentEntry.memo = v;
                        _currentEntry.isSaved = false;
                      }),
                      decoration: const InputDecoration(
                          hintText: '특이사항 입력 (선택)'),
                      maxLines: 3,
                      controller: TextEditingController(
                          text: _currentEntry.memo),
                    ),
                    const SizedBox(height: 16),
                    // 완료/저장됨 상태 버튼
                    _currentEntry.isSaved
                        ? _SavedStatusRow(
                            petName: _current.petName,
                            onUndo: () => setState(() {
                              _entries[_current.petId] =
                                  _FeedingEntry()
                                    ..isSaved = false;
                            }),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _saving ? null : _toggleComplete,
                              style: ElevatedButton.styleFrom(
                                  minimumSize:
                                      const Size(0, 48)),
                              child: _saving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2)
                                  : const Text('완료'),
                            ),
                          ),
                    const SizedBox(height: 10),
                    // 다음 개체
                    if (_currentIndex < _pets.length - 1)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _next,
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets,
                                  size: 16,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                  '다음 · ${_pets[_currentIndex + 1].petName}'),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  size: 16),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            // 하단 버튼
            Container(
              padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.border)),
                color: AppColors.surface,
              ),
              child: Row(
                children: [
                  if (!widget.fromHome) ...[
                    SizedBox(
                      width: 80,
                      child: OutlinedButton(
                        onPressed: _prev,
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48)),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_ios, size: 12),
                            Text('뒤로'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48)),
                      child: Text(
                        '닫기  $_savedCount건 저장됨',
                        style: AppTextStyles.bodyBold,
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

// ── 현재 개체 카드 ────────────────────────────────────────────────────────────

class _CurrentPetCard extends StatelessWidget {
  final TodayPetStatus status;
  final Color bgColor;

  const _CurrentPetCard(
      {required this.status, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: status.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(status.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.pets,
                            size: 22,
                            color: AppColors.primary.withOpacity(0.4))),
                  )
                : Icon(Icons.pets,
                    size: 22,
                    color: AppColors.primary.withOpacity(0.4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.petName,
                    style: AppTextStyles.bodyBold),
                Text(status.speciesName,
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Icon(Icons.chevron_left,
              size: 18, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}

// ── 급여 종류 드롭다운 ────────────────────────────────────────────────────────

class _FoodTypeDropdown extends StatefulWidget {
  final String value;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;

  const _FoodTypeDropdown({
    required this.value,
    required this.suggestions,
    required this.onChanged,
  });

  @override
  State<_FoodTypeDropdown> createState() => _FoodTypeDropdownState();
}

class _FoodTypeDropdownState extends State<_FoodTypeDropdown> {
  late final TextEditingController _controller;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_FoodTypeDropdown old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: (v) {
            widget.onChanged(v);
            setState(() => _showSuggestions = v.isEmpty);
          },
          onTap: () =>
              setState(() => _showSuggestions = _controller.text.isEmpty),
          decoration: InputDecoration(
            hintText: '귀뚜라미, 두비아 등',
            suffixIcon: IconButton(
              icon: Icon(
                _showSuggestions
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _showSuggestions = !_showSuggestions),
            ),
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: widget.suggestions.map((s) {
                return InkWell(
                  onTap: () {
                    _controller.text = s;
                    widget.onChanged(s);
                    setState(() => _showSuggestions = false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(s, style: AppTextStyles.body),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── 급여량 스텝퍼 ─────────────────────────────────────────────────────────────

class _AmountStepper extends StatelessWidget {
  final int amount;
  final String unit;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<String> onUnitChanged;

  const _AmountStepper({
    required this.amount,
    required this.unit,
    required this.onAmountChanged,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // - 버튼
        _StepBtn(
          icon: Icons.remove,
          onTap: () {
            if (amount > 0) onAmountChanged(amount - 1);
          },
        ),
        // 수량 표시
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding:
                const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('$amount', style: AppTextStyles.title),
            ),
          ),
        ),
        // 단위 선택
        DropdownButton<String>(
          value: unit.isEmpty ? '마리' : unit,
          items: ['마리', 'g', 'ml', '개']
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: (v) => onUnitChanged(v ?? '마리'),
          underline: const SizedBox(),
        ),
        const SizedBox(width: 8),
        // + 버튼
        _StepBtn(
          icon: Icons.add,
          onTap: () => onAmountChanged(amount + 1),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}

// ── 퀵 급여량 칩 ──────────────────────────────────────────────────────────────

class _QuickAmountChips extends StatelessWidget {
  final String unit;
  final int selected;
  final ValueChanged<int> onTap;

  const _QuickAmountChips({
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final u = unit.isEmpty ? '마리' : unit;
    const amounts = [1, 3, 5, 7, 10];
    return Wrap(
      spacing: 8,
      children: amounts.map((a) {
        final isSelected = selected == a;
        return GestureDetector(
          onTap: () => onTap(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.petColorMint
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: Text(
              '$a$u',
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 저장됨 상태 행 ────────────────────────────────────────────────────────────

class _SavedStatusRow extends StatelessWidget {
  final String petName;
  final VoidCallback onUndo;

  const _SavedStatusRow(
      {required this.petName, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.petColorMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$petName · 저장됨',
                    style: AppTextStyles.bodyBold
                        .copyWith(fontSize: 13)),
                Text(
                  '수정하려면 미완료로 되돌린 뒤 다시 완료하세요',
                  style:
                      AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUndo,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('미완료',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── 급여 입력 엔트리 모델 ─────────────────────────────────────────────────────

class _FeedingEntry {
  String foodType = '';
  int amount = 0;
  String unit = '마리';
  String memo = '';
  bool isSaved = false;
}
