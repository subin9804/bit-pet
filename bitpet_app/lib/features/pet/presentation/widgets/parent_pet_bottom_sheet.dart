import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../data/pet_repository.dart';
import '../../providers/pet_provider.dart';

/// 부모 개체 선택 바텀시트.
///
/// 두 가지 경로가 있다:
///  1. **내 개체 목록** — 성별·종이 맞는 것만 추려서 보여준다
///  2. **일련번호 검색** — 남의 개체를 부모로 걸 때. 부모 등록은 소유자와 무관하게 되지만,
///     그렇다고 남의 개체 목록을 훑게 할 수는 없어 **정확한 일련번호 일치**로만 연다
///
/// [isFather] : true → 부(♂) 선택, false → 모(♀) 선택
/// 팝 결과값: 선택된 [PetCard] 또는 null (취소)
class ParentPetBottomSheet extends ConsumerStatefulWidget {
  final bool isFather;
  final PetCard? initialSelection;
  final int? excludePetId;    // 수정 중인 개체 제외
  final int? filterSpeciesId; // 같은 종만 표시

  const ParentPetBottomSheet({
    super.key,
    required this.isFather,
    this.initialSelection,
    this.excludePetId,
    this.filterSpeciesId,
  });

  @override
  ConsumerState<ParentPetBottomSheet> createState() =>
      _ParentPetBottomSheetState();
}

class _ParentPetBottomSheetState
    extends ConsumerState<ParentPetBottomSheet> {
  final _searchCtrl = TextEditingController();
  PetCard? _selectedPet;
  String _query = '';

  /// 일련번호로 찾아온 남의 개체 (내 목록에 없는 개체)
  PetCard? _remoteFound;
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialSelection;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _genderCode => widget.isFather ? 'MALE' : 'FEMALE';
  String get _genderLabel => widget.isFather ? '부 (♂)' : '모 (♀)';
  String get _genderKo => widget.isFather ? '수컷' : '암컷';

  /// 일련번호 정확 일치로 남의 개체 찾기.
  /// 성별·종이 맞지 않으면 여기서 막는다 — 서버는 "실존 개체"만 보므로 이 검증은 앱 몫이다.
  Future<void> _searchBySerial() async {
    final serial = _query.trim().toUpperCase();
    if (serial.isEmpty) return;
    setState(() { _searching = true; _searchError = null; _remoteFound = null; });

    final card = await ref.read(petRepositoryProvider).findCardBySerial(serial);
    if (!mounted) return;

    String? err;
    if (card == null) {
      err = '$serial 로 찾을 수 없어요. 비공개 개체이거나 없는 번호예요';
    } else if (card.petId == widget.excludePetId) {
      err = '자기 자신은 부모로 등록할 수 없어요';
    } else if (card.gender != _genderCode) {
      err = '$_genderKo 개체가 아니에요';
    } else if (widget.filterSpeciesId != null &&
        card.speciesId != widget.filterSpeciesId) {
      err = '종이 달라요 (${card.speciesName})';
    }

    setState(() {
      _searching = false;
      _searchError = err;
      _remoteFound = err == null ? card : null;
      if (err == null) _selectedPet = card;
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchField(),
          const SizedBox(height: 12),
          Expanded(
            child: petsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('개체 목록을 불러오지 못했어요')),
              data: _buildBody,
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ─── Section builders ─────────────────────────────────────────────────────

  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT PARENT', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text('$_genderLabel 개체 선택', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              '내 개체는 이름·종으로, 남의 개체는 일련번호로 찾을 수 있어요',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );

  Widget _buildSearchField() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => setState(() {
            _query = v;
            _remoteFound = null;
            _searchError = null;
          }),
          onSubmitted: (_) => _searchBySerial(),
          decoration: const InputDecoration(
            hintText: '이름 · 종 · 일련번호',
            prefixIcon: Icon(Icons.search, size: 20),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );

  Widget _buildBody(List<Pet> allPets) {
    final q = _query.trim().toLowerCase();
    final filtered = allPets.where((p) {
      if (p.gender != _genderCode) return false;
      // 수정 중인 개체 제외
      if (widget.excludePetId != null && p.id == widget.excludePetId) return false;
      // 같은 종만
      if (widget.filterSpeciesId != null && p.speciesId != widget.filterSpeciesId) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.serialNo.toLowerCase().contains(q) ||
          p.speciesName.toLowerCase().contains(q);
    }).map(PetCard.fromPet).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 일련번호 검색 결과 / 검색 유도 — 내 목록에 없을 때가 정확히 남의 개체를 거는 상황이다
        if (_remoteFound != null) ...[
          Text('일련번호 검색 결과', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          _PetListCard(
            card: _remoteFound!,
            isSelected: _selectedPet?.petId == _remoteFound!.petId,
            isFather: widget.isFather,
            onTap: () => setState(() => _selectedPet = _remoteFound),
          ),
          const SizedBox(height: 12),
        ] else if (q.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SerialSearchTile(
              query: _query.trim().toUpperCase(),
              searching: _searching,
              error: _searchError,
              onTap: _searching ? null : _searchBySerial,
            ),
          ),
        Text('내 $_genderKo 개체 ${filtered.length}마리',
            style: AppTextStyles.caption),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                '조건에 맞는 $_genderKo 개체가 없어요',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textDisabled),
              ),
            ),
          )
        else
          ...filtered.map((c) => _PetListCard(
                card: c,
                isSelected: _selectedPet?.petId == c.petId,
                isFather: widget.isFather,
                onTap: () => setState(() => _selectedPet = c),
              )),
      ],
    );
  }

  Widget _buildBottomButtons() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              // 취소
              SizedBox(
                width: 72,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              // 연결
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedPet == null
                      ? null
                      : () => Navigator.pop(context, _selectedPet),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    disabledBackgroundColor: AppColors.bg2,
                    disabledForegroundColor: AppColors.textDisabled,
                  ),
                  child: const Text('연결'),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── 일련번호 검색 유도 타일 ──────────────────────────────────────────────────

class _SerialSearchTile extends StatelessWidget {
  final String query;
  final bool searching;
  final String? error;
  final VoidCallback? onTap;

  const _SerialSearchTile({
    required this.query,
    required this.searching,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (searching)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.travel_explore, size: 18, color: AppColors.paleInk2),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    searching ? '찾는 중…' : "일련번호 '$query' 로 남의 개체 찾기",
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 2),
                    Text(error!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.female)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pet 카드 위젯 ────────────────────────────────────────────────────────────

class _PetListCard extends StatelessWidget {
  final PetCard card;
  final bool isSelected;
  final bool isFather;
  final VoidCallback onTap;

  const _PetListCard({
    required this.card,
    required this.isSelected,
    required this.isFather,
    required this.onTap,
  });

  Color get _identityColor {
    if (card.colorCode == null) return AppColors.bg2;
    try {
      return Color(
          int.parse(card.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.bg2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = card.owner;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 (아이덴티티 컬러 배경)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _identityColor,
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.hardEdge,
              child: card.profileImageUrl != null
                  ? Image.network(card.profileImageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('🦎', style: TextStyle(fontSize: 24))))
                  : const Center(
                      child: Text('🦎', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            // 개체 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          card.name,
                          style: AppTextStyles.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFather ? '♂' : '♀',
                        style: TextStyle(
                          fontSize: 13,
                          color: isFather
                              ? AppColors.male
                              : AppColors.female,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.serialNo,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled),
                  ),
                  Text(
                    card.morphLabel.isEmpty
                        ? card.speciesName
                        : '${card.speciesName} · ${card.morphLabel}',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 남의 개체일 때만 소유자를 붙인다 (가계도 카드와 같은 규칙).
                  // 주인 없음('정보 없음')과 닉네임 비공개('비공개')는 다른 상태다
                  if (!owner.isMe)
                    Text(
                      owner.isOrphaned
                          ? '정보 없음'
                          : owner.userId == null
                              ? (owner.nickname ?? '비공개')
                              : '@${owner.nickname}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
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
