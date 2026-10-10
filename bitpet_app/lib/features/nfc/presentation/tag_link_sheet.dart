import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/pet_avatar.dart';
import '../../../core/widgets/toast_message.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import '../data/models/tag_models.dart';
import '../data/tag_repository.dart';
import '../providers/tag_provider.dart';
import '../../../core/theme/app_dimens.dart';

/// "어느 개체에 연결할까요?" — 첫 스캔 시 뜨는 연결 모달.
///
/// 연결에 성공하면 [TagResolveResult]를 돌려준다. 취소하면 null.
Future<TagResolveResult?> showTagLinkSheet(
  BuildContext context, {
  required String tagCd,
  int? initialPetId,
}) {
  return showAppSheet<TagResolveResult>(
    context: context,
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
      final result = await ref
          .read(tagRepositoryProvider)
          .link(tagCd: widget.tagCd, petId: petId);
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

    // 태그 코드는 제목 옆 회색 칩이었다 — 보조 줄로 내려 제목 줄을 비운다.
    // '나중에' 버튼은 지웠다: 밖을 눌러 닫으면 그게 '나중에'다 (AppSheet 공통 규칙).
    return AppSheet(
      title: '어느 개체에 연결할까요?',
      subtitle: '${widget.tagCd} · 이 태그를 찍으면 선택한 개체로 바로 들어갑니다.',
      busy: _saving,
      primaryLabel: '이 개체에 연결',
      onPrimary: _petId == null ? null : _submit,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            petsAsync.when(
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
                  // ListView 를 쓰지 않는다 — AppSheet 가 이미 스크롤이라
                  // 안쪽에 또 두면 스크롤이 겹친다.
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: selectable
                        .map((p) => _PetRow(
                              pet: p,
                              selected: p.id == _petId,
                              onTap: () => setState(() => _petId = p.id),
                            ))
                        .toList(growable: false),
                  );
                },
            ),
          ],
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          color: selected ? AppColors.bg2 : AppColors.card,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.paleLine),
        ),
        child: Row(
          children: [
            PetAvatar(
              imageUrl: pet.profileImageUrl,
              size: 36,
              background: AppColors.paleBgAlt,
              iconColor: AppColors.primary,
              subcategory: pet.speciesSubcategory,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 4),
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
