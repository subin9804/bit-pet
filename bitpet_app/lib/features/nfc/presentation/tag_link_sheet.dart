import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../data/models/tag_models.dart';
import '../data/tag_repository.dart';
import '../providers/tag_provider.dart';

/// "어느 개체에 연결할까요?" — 첫 스캔 시 뜨는 연결 모달.
///
/// 연결에 성공하면 [TagResolveResult]를 돌려준다. 취소하면 null.
Future<TagResolveResult?> showTagLinkSheet(
  BuildContext context, {
  required String tagCd,
  int? initialPetId,
}) {
  return showModalBottomSheet<TagResolveResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TagLinkSheet(tagCd: tagCd, initialPetId: initialPetId),
  );
}

class TagLinkSheet extends ConsumerStatefulWidget {
  final String tagCd;
  final int? initialPetId;
  const TagLinkSheet({super.key, required this.tagCd, this.initialPetId});

  @override
  ConsumerState<TagLinkSheet> createState() => _TagLinkSheetState();
}

class _TagLinkSheetState extends ConsumerState<TagLinkSheet> {
  int? _petId;
  TagAction _action = TagAction.petDetail;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _petId = widget.initialPetId;
  }

  Future<void> _submit() async {
    final petId = _petId;
    if (petId == null || _saving) return;
    setState(() => _saving = true);
    try {
      final result = await ref.read(tagRepositoryProvider).link(
            tagCd: widget.tagCd,
            petId: petId,
            action: _action,
          );
      ref.invalidate(myTagsProvider);
      ref.invalidate(tagResolveProvider(widget.tagCd));
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, '태그 연결에 실패했습니다.', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.paleLine)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('어느 개체에 연결할까요?', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text(
                          '이 태그를 찍으면 선택한 개체로 바로 들어갑니다.',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: AppColors.bg2,
                    child: Text(
                      widget.tagCd,
                      style: AppTextStyles.mono(11, FontWeight.w700,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── 개체 목록 ─────────────────────────────────────
            Flexible(
              child: petsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('개체 목록을 불러오지 못했어요')),
                ),
                data: (pets) {
                  final selectable =
                      pets.where((p) => !p.isDeceased).toList(growable: false);
                  if (selectable.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                          child: Text('먼저 개체를 등록해 주세요',
                              style: TextStyle(color: AppColors.textSecondary))),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: selectable.length,
                    itemBuilder: (_, i) => _PetRow(
                      pet: selectable[i],
                      selected: selectable[i].id == _petId,
                      onTap: () => setState(() => _petId = selectable[i].id),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: AppColors.paleLine),

            // ── 기본 동작 ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
              child: Text('태그를 찍었을 때', style: AppTextStyles.bodyBold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TagAction.values.map((a) {
                  final on = a == _action;
                  return GestureDetector(
                    onTap: () => setState(() => _action = a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: on ? AppColors.primary : AppColors.card,
                        border: Border.all(
                            color: on ? AppColors.primary : AppColors.paleLine),
                      ),
                      child: Text(
                        a.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on ? AppColors.paleBg : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── 액션 ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.paleLine),
                        ),
                        child: const Text('나중에',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _petId == null ? null : _submit,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        color: _petId == null
                            ? AppColors.bg2
                            : AppColors.primary,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                '이 개체에 연결',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _petId == null
                                      ? AppColors.textDisabled
                                      : AppColors.paleBg,
                                ),
                              ),
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

class _PetRow extends StatelessWidget {
  final Pet pet;
  final bool selected;
  final VoidCallback onTap;
  const _PetRow({required this.pet, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.bg2 : AppColors.card,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.paleLine),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text('${pet.speciesName} · ${pet.serialNo}',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
