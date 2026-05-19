import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/pet_provider.dart';

class PetDetailScreen extends ConsumerWidget {
  final int petId;
  const PetDetailScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petDetailProvider(petId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          petAsync.whenOrNull(
            data: (pet) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('삭제', style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (action) async {
                if (action == 'edit') {
                  context.push('/pets/$petId/edit');
                } else if (action == 'delete') {
                  final ok = await ConfirmModal.show(
                    context,
                    title: '개체 삭제',
                    message: '${pet.name}을(를) 삭제할까요? 모든 기록도 함께 삭제됩니다.',
                    confirmLabel: '삭제',
                    isDangerous: true,
                  );
                  if (ok && context.mounted) {
                    await ref.read(petListProvider.notifier).remove(petId);
                    context.pop();
                    ToastMessage.show(context, '개체가 삭제되었습니다.',
                        type: ToastType.success);
                  }
                }
              },
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: petAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (pet) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 헤더
              Center(
                child: Column(
                  children: [
                    _avatar(pet.profileImageUrl, pet.colorCode),
                    const SizedBox(height: 12),
                    Text(pet.name, style: AppTextStyles.h1),
                    Text(pet.speciesName,
                        style: AppTextStyles.caption),
                    Text('#${pet.serialNo}',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 기록 빠른 접근
              Text('기록', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              _recordButtons(context, petId),
              const SizedBox(height: 24),
              // 기본 정보
              Text('기본 정보', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              _infoRow('성별', _genderLabel(pet.gender)),
              if (pet.hatchingDate != null)
                _infoRow('부화일',
                    '${pet.hatchingDate!.year}.${pet.hatchingDate!.month.toString().padLeft(2, '0')}.${pet.hatchingDate!.day.toString().padLeft(2, '0')}'),
              if (pet.adoptionDate != null)
                _infoRow('입양일',
                    '${pet.adoptionDate!.year}.${pet.adoptionDate!.month.toString().padLeft(2, '0')}.${pet.adoptionDate!.day.toString().padLeft(2, '0')}'),
              if (pet.latestWeightG != null)
                _infoRow('최근 체중', '${pet.latestWeightG!.toStringAsFixed(1)}g'),
              if (pet.description != null && pet.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('개체 소개', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(pet.description!, style: AppTextStyles.body),
              ],
              if (pet.environmentMemo != null &&
                  pet.environmentMemo!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('사육환경', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(pet.environmentMemo!, style: AppTextStyles.body),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String? imageUrl, String? colorCode) {
    final color = _parseColor(colorCode);
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 3),
      ),
      child: imageUrl != null
          ? ClipOval(child: Image.network(imageUrl, fit: BoxFit.cover))
          : Icon(Icons.pets, color: color, size: 48),
    );
  }

  Widget _recordButtons(BuildContext context, int id) {
    final items = [
      ('체중', Icons.monitor_weight_outlined, '/pets/$id/records/weight'),
      ('급여', Icons.restaurant_outlined, '/pets/$id/records/feeding'),
      ('청소', Icons.cleaning_services_outlined, '/pets/$id/records/cleaning'),
      ('건강', Icons.favorite_outline, '/pets/$id/records/health'),
    ];
    return Row(
      children: items
          .map((item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _RecordButton(
                    label: item.$1,
                    icon: item.$2,
                    onTap: () => context.push(item.$3),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: AppTextStyles.label)),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  String _genderLabel(String gender) => switch (gender) {
        'MALE' => '수컷',
        'FEMALE' => '암컷',
        _ => '미확인',
      };

  Color _parseColor(String? hex) {
    if (hex == null) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _RecordButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RecordButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
