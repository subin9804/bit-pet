// Screen 06e: 피딩 기록 바텀시트 (per-pet navigation)
// - 상단 개체 탭 칩
// - 현재 개체 카드 (컬러 bg, 이름, 종)
// - FeedComposerFields (먹이 종류/사이즈/수량/ml/용량/직접입력/영양제/메모)
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
import 'widgets/feed_composer_fields.dart';

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
  final Map<int, FeedFormData> _forms = {};
  final Map<int, bool> _saved = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pets = widget.routine.petStatuses;
    _currentIndex = widget.initialPetId != null
        ? pets.indexWhere((s) => s.petId == widget.initialPetId)
            .clamp(0, pets.length - 1)
        : 0;
    for (final s in pets) {
      _forms[s.petId] = const FeedFormData();
      _saved[s.petId] = false;
    }
  }

  List<TodayPetStatus> get _pets => widget.routine.petStatuses;
  TodayPetStatus get _current => _pets[_currentIndex];
  FeedFormData get _currentForm => _forms[_current.petId]!;

  int get _savedCount => _saved.values.where((v) => v).length;

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
    if (_saved[_current.petId] == true) {
      setState(() => _saved[_current.petId] = false);
      return;
    }
    setState(() => _saving = true);
    try {
      final form = _currentForm;
      if (!form.isValid) { showToast(context, '먹이 종류를 선택해 주세요'); return; }
      final now = DateTime.now();
      final feedMap = form.toApiMap(fedAt: now);
      final repo = ref.read(recordRepositoryProvider);
      await repo.addFeeding(_current.petId, feedMap);
      await ref.read(routineRepositoryProvider).completeIndividual(
        widget.routine.id,
        RoutineCompleteIndividualRequest(
          petId:     _current.petId,
          status:    RoutineLogStatus.COMPLETED,
          feedItems: form.foodType != null ? [form] : const [],
          memo:      feedMap['memo'] as String?,
        ),
      );
      setState(() => _saved[_current.petId] = true);
      ref.read(todayRoutinesProvider.notifier).updatePetStatus(widget.routine.id, _current.petId, true);
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
                  final isSaved = _saved[s.petId] == true;
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
                              ? _petBg(s).withValues(alpha: 0.6)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets,
                              size: 13,
                              color: AppColors.primary
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(s.petName,
                              style: AppTextStyles.caption
                                  .copyWith(
                                      fontWeight:
                                          FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(
                            isSaved
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 12,
                            color: isSaved
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
                    // 급여 입력 컴포저
                    FeedComposerFields(
                      form: _currentForm,
                      bandColor: AppColors.petPeach,
                      showMemo: true,
                      onChanged: (f) => setState(() => _forms[_current.petId] = f),
                    ),
                    const SizedBox(height: 16),
                    // 완료/저장됨 상태 버튼
                    _saved[_current.petId] == true
                        ? _SavedStatusRow(
                            petName: _current.petName,
                            onUndo: () => setState(() {
                              _saved[_current.petId] = false;
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
        color: bgColor.withValues(alpha: 0.35),
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
                            color: AppColors.primary.withValues(alpha: 0.4))),
                  )
                : Icon(Icons.pets,
                    size: 22,
                    color: AppColors.primary.withValues(alpha: 0.4)),
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
