// Screen 06e: 급여 기록 바텀시트 (per-pet navigation)
// - 상단 개체 탭 칩
// - 현재 개체 카드 (컬러 bg, 이름, 종)
// - FeedComposerFields (먹이 종류/사이즈/수량/ml/용량/직접입력/영양제/메모)
// - 완료/미완료 버튼
// - 다음 개체 / 뒤로 / 닫기
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pet_avatar.dart';
import '../../../core/widgets/toast_message.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/data/routine_repository.dart';
import '../../routine/providers/routine_provider.dart';
import '../data/record_repository.dart';
import '../providers/record_invalidation.dart';
import 'widgets/feed_items_editor.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_network_image.dart';

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
  final Map<int, List<FeedFormData>> _items = {};
  final Map<int, String> _memos = {};
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
      _items[s.petId] = [];
      _memos[s.petId] = '';
      _saved[s.petId] = false;
    }
  }

  List<TodayPetStatus> get _pets => widget.routine.petStatuses;
  TodayPetStatus get _current => _pets[_currentIndex];
  List<FeedFormData> get _currentItems => _items[_current.petId]!;

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
    final items = _currentItems;
    if (items.isEmpty) { showToast(context, '급여를 목록에 추가해 주세요'); return; }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final repo = ref.read(recordRepositoryProvider);
      for (final item in items) {
        await repo.addFeeding(_current.petId, item.toApiMap(fedAt: now));
      }
      final memo = _memos[_current.petId]!.trim();
      await ref.read(routineRepositoryProvider).completeIndividual(
        widget.routine.id,
        RoutineCompleteIndividualRequest(
          petId:     _current.petId,
          status:    RoutineLogStatus.COMPLETED,
          feedItems: items,
          memo:      memo.isEmpty ? null : memo,
        ),
      );
      setState(() => _saved[_current.petId] = true);
      ref.read(todayRoutinesProvider.notifier).updatePetStatus(widget.routine.id, _current.petId, true);
      invalidatePetRecords(ref, _current.petId);
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _petBg(TodayPetStatus s) {
    // 개체 지정색은 걷어냈다 — 저장된 hex 를 그대로 칠하던 자리다.
    // 자세한 이유는 core/theme/pale_palette.dart 주석 참고.
    return AppColors.bgAlt;
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
                  borderRadius: AppRadius.brPill,
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
                      Text('급여 기록', style: AppTextStyles.title),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.petColorPeach,
                      borderRadius: AppRadius.brPill,
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
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _petBg(s)
                            : AppColors.bg2,
                        borderRadius:
                            AppRadius.brPill,
                        border: Border.all(
                          color: isActive
                              ? _petBg(s).withValues(alpha: 0.6)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PetAvatar(
                              imageUrl: s.imageUrl,
                              size: 18,
                              background: Colors.transparent,
                              iconColor: AppColors.primary
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
                            size: 16,
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
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 현재 개체 카드
                    _CurrentPetCard(
                        status: _current, bgColor: _petBg(_current)),
                    const SizedBox(height: 16),
                    // 급여 입력 컴포저 (목록에 추가)
                    FeedItemsEditor(
                      items: _currentItems,
                      petId: _current.petId,
                      bandColor: AppColors.petPeach,
                      onChanged: (list) => setState(() => _items[_current.petId] = list),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) => _memos[_current.petId] = v,
                      maxLines: 2,
                      decoration: AppInputStyles.textarea(hintText: '특이사항 (선택)'),
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
                                  : Text(_currentItems.isEmpty
                                      ? '완료'
                                      : '완료 (${_currentItems.length}종 저장)'),
                            ),
                          ),
                    const SizedBox(height: 8),
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
                              AppIcon(AppIcons.petLine,
                                  size: 16,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                  '다음 · ${_pets[_currentIndex + 1].petName}'),
                              const SizedBox(width: 4),
                              const AppIcon(AppIcons.chevronRight,
                                  size: 16),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                        height:
                            MediaQuery.of(context).viewInsets.bottom + 16),
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
                            Icon(Icons.arrow_back_ios, size: 16),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.35),
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.brLg,
            ),
            child: status.imageUrl != null
                ? ClipRRect(
                    borderRadius: AppRadius.brLg,
                    child: AppNetworkImage(status.imageUrl,
                        fit: BoxFit.cover,
                        memWidth: 120,
                        placeholder: AppIcon(AppIcons.petLine,
                            size: 20,
                            color: AppColors.primary.withValues(alpha: 0.4))),
                  )
                : AppIcon(AppIcons.petLine,
                    size: 20,
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
              size: 20, color: AppColors.textDisabled),
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
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // '저장됨'은 상태다 — 개체색 팔레트에서 빌려 쓰던 자리라 브랜드색으로 옮겼다.
        color: AppColors.brandTint,
        borderRadius: AppRadius.brLg,
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
          const SizedBox(width: 8),
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
                  horizontal: 8, vertical: 8),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.brMd),
            ),
            child: const Text('미완료',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
