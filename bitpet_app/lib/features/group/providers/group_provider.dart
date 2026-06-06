import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/group_repository.dart';
import '../data/models/group_models.dart';

/// 내 그룹 정보. null = 그룹 없음 (온보딩 필요).
final myGroupProvider = FutureProvider.autoDispose<GroupInfo?>((ref) {
  return ref.watch(groupRepositoryProvider).getMyGroup();
});

/// 그룹 액션 Notifier (생성/참여/수정/탈퇴/강퇴)
final groupActionProvider =
    AsyncNotifierProvider<GroupActionNotifier, GroupInfo?>(
        GroupActionNotifier.new);

class GroupActionNotifier extends AsyncNotifier<GroupInfo?> {
  GroupRepository get _repo => ref.read(groupRepositoryProvider);

  @override
  Future<GroupInfo?> build() async {
    return ref.watch(groupRepositoryProvider).getMyGroup();
  }

  Future<void> create(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.createGroup(name));
    ref.invalidate(myGroupProvider);
  }

  Future<void> join(String inviteCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.joinGroup(inviteCode));
    ref.invalidate(myGroupProvider);
  }

  Future<void> updateName(String name) async {
    state = await AsyncValue.guard(() => _repo.updateGroupName(name));
    ref.invalidate(myGroupProvider);
  }

  Future<void> leaveOrDisband() async {
    await _repo.leaveOrDisband();
    state = const AsyncData(null);
    ref.invalidate(myGroupProvider);
  }

  Future<void> kick(int userId) async {
    await _repo.kickMember(userId);
    final updated = await _repo.getMyGroup();
    state = AsyncData(updated);
    ref.invalidate(myGroupProvider);
  }
}
