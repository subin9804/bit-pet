import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/pet_profile_card.dart';
import '../providers/pet_provider.dart';

class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 개체'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/pets/new'),
          ),
        ],
      ),
      body: petsAsync.when(
        loading: () => const SkeletonCardList(),
        error: (e, _) => EmptyState(
          message: '불러오기 실패',
          subMessage: e.toString(),
          icon: Icons.error_outline,
          actionLabel: '다시 시도',
          onAction: () => ref.read(petListProvider.notifier).load(),
        ),
        data: (pets) {
          if (pets.isEmpty) {
            return EmptyState(
              message: '등록된 개체가 없어요',
              subMessage: '첫 번째 반려 파충류를 등록해보세요!',
              icon: Icons.pets,
              actionLabel: '개체 등록',
              onAction: () => context.push('/pets/new'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(petListProvider.notifier).load(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: pets.length,
              itemBuilder: (_, i) {
                final pet = pets[i];
                return PetProfileCard(
                  name: pet.name,
                  speciesName: pet.speciesName,
                  colorCode: pet.colorCode,
                  imageUrl: pet.profileImageUrl,
                  onTap: () => context.push('/pets/${pet.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/pets/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
