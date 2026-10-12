// 부화한 알 → 개체 등록.
//
// 사용자가 적는 것은 **이름 + 성별**, 그리고 선택으로 **첫 몸무게**뿐이다.
// 종·해칭일·부모는 클러치가 이미 아는 값이라 서버가 채운다(계보도 자동 연결).
//
// ⛔ 시트 상단에 '부화 상태/부화일' 블록을 다시 넣지 말 것 — 부화 다음이 개체 등록이고
// 부화일과 해칭일은 같은 값이다. 한 번 그렇게 만들었다가 폼이 두 배로 길어졌다.
// 모프·사진은 등록을 끝낸 뒤 편집 화면에서 받는다.
//
// 이 시트는 알 **하나**가 아니라 [queue] 를 받는다. 부화한 알이 세 개면 세 번
// 등록해야 하는데, 예전처럼 한 마리를 저장하고 시트를 닫아 버리면 목록으로
// 튕겨 나갔다가 버튼을 다시 찾아 눌러야 했다. 지금은 저장 후 **시트를 닫지 않고**
// 폼만 다음 알로 갈아끼운다(1/3 → 2/3 → 3/3).
//
// ⛔ 다음 알로 넘기는 걸 가로 스와이프(PageView)로 만들지 말 것 — 바텀시트의
// 드래그-닫기 제스처와 경합해서 비스듬한 스와이프가 시트를 닫아 버리고,
// 알마다 저장이 독립된 서버 호출이라 '뒤로 밀면 이미 저장된 알' 문제가 생긴다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/toast_message.dart';
import '../../../pet/providers/pet_provider.dart';
import '../../data/models/record_models.dart';
import '../../data/record_repository.dart';
import '../../providers/record_invalidation.dart';

class HatchRegisterSheet extends ConsumerStatefulWidget {
  final LayingRecord laying;

  /// 등록할 알들. 앞에서부터 하나씩 처리한다. 롱프레스로 특정 알만 열 때는
  /// 길이 1 로 들어온다 — 그때는 진행 카운터를 숨긴다.
  final List<HatchRecord> queue;

  const HatchRegisterSheet({
    super.key,
    required this.laying,
    required this.queue,
  });

  @override
  ConsumerState<HatchRegisterSheet> createState() =>
      _HatchRegisterSheetState();
}

class _HatchRegisterSheetState extends ConsumerState<HatchRegisterSheet> {
  final _name = TextEditingController();
  final _weight = TextEditingController();
  String _gender = 'UNKNOWN';
  bool _busy = false;

  /// 지금 적고 있는 알의 [HatchRegisterSheet.queue] 안 위치.
  int _at = 0;

  HatchRecord get _hatch => widget.queue[_at];
  int get _total => widget.queue.length;
  bool get _isLast => _at == _total - 1;

  @override
  void initState() {
    super.initState();
    _resetForm();
  }

  /// 다음 알로 넘어갈 때마다 폼을 비운다. 이름만 어미 이름 + 알 번호로
  /// 미리 채우고 성별·몸무게는 비운다 — 앞 알의 값이 남아 있으면 그대로
  /// 저장돼 버리는 쪽이 더 위험하다.
  void _resetForm() {
    _name.text = widget.laying.petName == null
        ? ''
        : '${widget.laying.petName} #${_hatch.eggIndex}';
    _weight.clear();
    _gender = 'UNKNOWN';
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hatchedAt = _hatch.hatchedAt;

    return AppSheet(
      title: '개체로 등록',
      subtitle: [
        if (_total > 1) '${_at + 1}/$_total',
        if (widget.laying.petName != null) '${widget.laying.petName}의 클러치',
        '${_hatch.eggIndex}번 알',
        if (hatchedAt != null) '${hatchedAt.month}. ${hatchedAt.day} 부화',
      ].join(' · '),
      busy: _busy,
      // 남은 알이 있으면 버튼이 **다음 할 일**을 말한다. '등록하기'만 쓰면
      // 눌러 보고 나서야 시트가 안 닫힌 걸 알게 된다.
      primaryLabel: _isLast ? '등록 완료' : '저장하고 다음 알 (${_at + 1}/$_total)',
      onPrimary: () => _register(openEdit: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: AppDecor.card,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('이름 *', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xs + 2),
                TextField(
                  controller: _name,
                  style: AppTextStyles.body,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: '개체 이름'),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text('어미 이름 + 알 번호로 미리 채워 뒀어요',
                    style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.lg),
                Text('성별', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  children: [
                    for (final g in const [
                      ('UNKNOWN', '미구분'),
                      ('MALE', '수컷'),
                      ('FEMALE', '암컷'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AppChip(
                          label: g.$2,
                          selected: _gender == g.$1,
                          onTap: () => setState(() => _gender = g.$1),
                        ),
                      ),
                  ],
                ),
                // 선택 — 비우고 등록해도 된다. 적으면 해칭일자 체중 기록 한 건이 함께 생긴다.
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1, color: AppColors.bgAlt),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text('첫 몸무게', style: AppTextStyles.label),
                    const SizedBox(width: AppSpacing.xs),
                    Text('(선택)', style: AppTextStyles.label),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _weight,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]')),
                        ],
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(hintText: '예: 3.2'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('g',
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('적으면 해칭일 체중으로 기록돼요',
                          style: AppTextStyles.label),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 자동으로 들어가는 것 — 읽기만 하는 블록.
          const SizedBox(height: AppSpacing.md + 2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.brandTintSoft,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.brandTint),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.caption.copyWith(height: 1.7),
                children: [
                  if (widget.laying.speciesName != null) ...[
                    const TextSpan(text: '종 '),
                    _b(widget.laying.speciesName!),
                    const TextSpan(text: ' · '),
                  ],
                  const TextSpan(text: '해칭일 '),
                  _b(hatchedAt == null
                      ? '부화일 없음'
                      : '${hatchedAt.year}. ${hatchedAt.month}. ${hatchedAt.day}'),
                  const TextSpan(text: '\n부모 '),
                  _b(widget.laying.petName ?? '어미'),
                  const TextSpan(text: ' 계보 자동 연결'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: _busy ? null : () => _register(openEdit: true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandAction,
                textStyle:
                    AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              ),
              child: const Text('모프·사진까지 자세히 입력하기'),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _b(String text) => TextSpan(
      text: text,
      style: AppTextStyles.caption.copyWith(
          height: 1.7, fontWeight: FontWeight.w700, color: AppColors.ink));

  /// [openEdit] 이면 등록을 끝낸 뒤 그 개체의 편집 화면으로 보낸다 — 모프·사진은
  /// 거기서 받는다. 시트에 그 칸들을 넣으면 '이름+성별만' 이라는 전제가 무너진다.
  Future<void> _register({required bool openEdit}) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, '이름을 적어주세요', type: ToastType.warning);
      return;
    }
    final weightText = _weight.text.trim();
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    if (weightText.isNotEmpty && (weight == null || weight <= 0)) {
      showToast(context, '몸무게를 다시 확인해주세요', type: ToastType.warning);
      return;
    }

    setState(() => _busy = true);
    try {
      final petId = await ref.read(recordRepositoryProvider).registerPetFromHatch(
            widget.laying.id,
            _hatch.id,
            name: name,
            gender: _gender,
            weightG: weight,
          );
      invalidatePetRecords(ref, widget.laying.petId);
      ref.invalidate(petListProvider);

      if (!mounted) return;
      showToast(context, '$name 개체로 등록했어요', type: ToastType.success);

      // 모프·사진까지 적겠다고 했으면 편집 화면이 먼저다 — 남은 알은
      // 하단 버튼이 다시 떠 있으니 돌아와서 이어 하면 된다.
      if (openEdit) {
        Navigator.of(context).pop();
        context.push('/pets/$petId/edit');
        return;
      }
      if (_isLast) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _at++;
        _busy = false;
        _resetForm();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, '등록하지 못했어요', type: ToastType.error);
      }
    }
  }
}
