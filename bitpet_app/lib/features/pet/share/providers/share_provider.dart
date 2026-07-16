import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/share_repository.dart';
import '../data/models/share_models.dart';

/// 내 공유코드 (없으면 서버 발급). 마이페이지·초대 화면에서 사용.
final myShareCodeProvider = FutureProvider<String>((ref) async {
  return ref.watch(shareRepositoryProvider).myShareCode();
});

/// 내가 받은 대기중 초대 목록 (단건 flat — 하위 호환)
final receivedInvitationsProvider =
    FutureProvider<List<ShareInvitation>>((ref) async {
  return ref.watch(shareRepositoryProvider).received();
});

/// 내가 받은 대기중 초대 — 배치(여러 개체)로 묶어 조회
final receivedBatchesProvider =
    FutureProvider<List<ShareInvitationBatch>>((ref) async {
  return ref.watch(shareRepositoryProvider).receivedBatches();
});

/// 개체 사육자(공유 멤버) 목록
final petKeepersProvider =
    FutureProvider.family<List<Keeper>, int>((ref, petId) async {
  return ref.watch(shareRepositoryProvider).keepers(petId);
});

/// 개체에 대해 내가 보낸 대기중 초대 목록
final petSentInvitationsProvider =
    FutureProvider.family<List<ShareInvitation>, int>((ref, petId) async {
  return ref.watch(shareRepositoryProvider).sent(petId);
});
