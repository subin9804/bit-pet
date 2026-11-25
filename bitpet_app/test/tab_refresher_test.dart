import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/home/presentation/tab_refresher.dart';
import 'package:bitpet_app/features/pet/data/models/pet_models.dart';
import 'package:bitpet_app/features/pet/data/pet_repository.dart';

class _PetRepo extends PetRepository {
  _PetRepo() : super(Dio());
  int calls = 0;
  @override
  Future<List<Pet>> getMyPets() async {
    calls++;
    return const [];
  }
}

void main() {
  testWidgets('다른 탭 루트로 오면 그 탭을 다시 받고, 같은 탭 안 이동은 건너뛴다', (t) async {
    final repo = _PetRepo();
    final notifier = ValueNotifier('/home');
    await t.pumpWidget(ProviderScope(
      overrides: [petRepositoryProvider.overrideWithValue(repo)],
      child: ValueListenableBuilder<String>(
        valueListenable: notifier,
        builder: (_, loc, __) =>
            TabRefresher(location: loc, child: const SizedBox()),
      ),
    ));
    expect(repo.calls, 0);

    notifier.value = '/pets';
    await t.pumpAndSettle();
    final afterSwitch = repo.calls;
    expect(afterSwitch, greaterThan(0));

    // 개체 상세에 들어갔다 목록으로 돌아오는 건 탭 전환이 아니다
    notifier.value = '/pets/3';
    await t.pumpAndSettle();
    notifier.value = '/pets';
    await t.pumpAndSettle();
    expect(repo.calls, afterSwitch);
  });
}
