import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pet_profile_card.dart';
import '../../pet/providers/pet_provider.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);
    final selectedPetId = ref.watch(selectedPetIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('bit-pet',
            style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 개체 가로 스크롤
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
              child: Text('내 개체', style: AppTextStyles.h3),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: petsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const EmptyState(message: '개체 로드 실패'),
                data: (pets) {
                  if (pets.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => context.push('/pets/new'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('첫 개체 등록하기',
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pets.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      if (i == pets.length) {
                        return GestureDetector(
                          onTap: () => context.push('/pets/new'),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: AppColors.primary),
                                SizedBox(height: 4),
                                Text('추가',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ),
                        );
                      }
                      final pet = pets[i];
                      return SizedBox(
                        width: 90,
                        child: PetProfileCard(
                          name: pet.name,
                          speciesName: pet.speciesName,
                          colorCode: pet.colorCode,
                          imageUrl: pet.profileImageUrl,
                          isSelected: selectedPetId == pet.id,
                          onTap: () {
                            ref.read(selectedPetIdProvider.notifier).state =
                                pet.id;
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // 오늘의 할 일 (placeholder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('오늘의 루틴', style: AppTextStyles.h3),
                  const Spacer(),
                  if (selectedPetId != null)
                    TextButton(
                      onPressed: () => context.go('/records'),
                      child: const Text('전체보기'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (selectedPetId == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '위에서 개체를 선택하면 오늘의 루틴을 볼 수 있어요',
                    style: AppTextStyles.caption,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '루틴 기능 개발 중... (STEP 7)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
