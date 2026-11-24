import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/weight_format.dart';
import '../../../core/widgets/stat_card.dart';
import '../../pet/presentation/widgets/pedigree_parent_card.dart';
import '../../pet/presentation/widgets/pet_hero_card.dart';
import '../../pet/data/models/pet_models.dart';
import '../data/models/tag_models.dart';

/// 남의 개체 이름표를 찍었을 때의 프로필 — 히어로 + 최근 체중·나이 + 정보 카드(해칭일·모프·부모).
///
/// 비공개 개체도 열린다 (실물 이름표가 있어야 닿는 경로). 무엇을 보여줄지는
/// 서버가 응답에서 이미 정했다 — 갤러리·기록·체중 이력은 여기 오지도 않는다.
/// 히어로 위 사육자 머리말을 누르면 그 사람 프로필로 간다 (2026-11-23). 닉네임을 감춘 사람·차단 관계면
/// 서버가 userId 를 비워 보내 "비공개"로만 보이고 눌리지 않는다.
/// (갤러리는 한때 그렸다가 뺐다 — 대표사진 한 장이면 충분하다는 판단.)
class NfcPetProfileView extends StatelessWidget {
  final NfcPetProfile profile;

  const NfcPetProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final age = _age(profile.pet);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.brandTintSoft,
        titleSpacing: 0,
        // 딥링크로 들어온 화면이라 스택 아래가 비어 있다 — 닫으면 홈으로
        leading: IconButton(
          tooltip: '닫기',
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('이름표'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.brandTintSoft,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.owner case final owner? when !owner.isOrphaned) ...[
                  _OwnerHeader(owner: owner),
                  const SizedBox(height: AppSpacing.md),
                ],
                PetHeroCard.card(card: profile.pet),
              ],
            ),
          ),
          // 개체 상세처럼 밴드에 걸치는 통계 칸 — 남에게는 최근 체중·나이 둘만.
          // 이력·그래프는 기록이라 서버가 내려주지 않는다. 정보 카드도 같이 올려
          // 통계 칸과 카드 사이가 상세 화면과 같은 간격이 되게 한다.
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  StatCardRow(cards: [
                    StatCard(
                      label: '최근 체중',
                      value: profile.latestWeightG == null
                          ? null
                          : formatWeight(profile.latestWeightG!),
                      unit: 'g',
                    ),
                    StatCard(label: '나이', value: age?.$1, unit: age?.$2),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _InfoCard(profile: profile),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: AppIconSize.badge, color: AppColors.ink3),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '다른 사육자의 개체예요. 사육 기록은 보이지 않아요.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.ink3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 히어로 위, 밴드 맨 윗줄의 사육자 표시 (2026-11-24). 카드 아래 따로 떠 있던
/// '사육자 | 닉네임' 줄이 정보 칸처럼 읽혀서 "누구의 개체인지"를 머리말로 올렸다.
/// 프로필로 갈 수 있을 때만 눌린다.
class _OwnerHeader extends StatelessWidget {
  final PetOwner owner;
  const _OwnerHeader({required this.owner});

  @override
  Widget build(BuildContext context) {
    final userId = owner.userId;
    final canOpen = userId != null && !owner.isMe;
    final name = owner.nickname ?? '비공개';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: canOpen ? () => context.push('/users/$userId') : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: AppColors.bg, shape: BoxShape.circle),
                child: const Icon(Icons.person,
                    size: 18, color: AppColors.ink3),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: name,
                      style: AppTextStyles.bodyBold.copyWith(
                          color: canOpen ? AppColors.ink : AppColors.ink3),
                    ),
                    TextSpan(
                      text: ' 님의 개체',
                      style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canOpen)
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

/// 나이 — 개월, 12개월을 넘으면 연. 내 개체 상세의 통계 칸과 같은 셈이다
/// (이별한 개체는 이별한 날에서 멈춘다). 해칭일이 없으면 null → '-'.
(String, String)? _age(PetCard pet) {
  final h = pet.hatchingDate;
  if (h == null) return null;
  final until = pet.deceasedAt ?? DateTime.now();
  final months = (until.difference(h).inDays / 30.44).floor();
  if (months < 0) return null;
  if (months < 12) return ('$months', '개월');
  return ((months / 12).floor().toString(), '년');
}

String _fmtDate(DateTime? d, [String? precision]) {
  if (d == null) return '-';
  final ym = '${d.year}.${d.month.toString().padLeft(2, '0')}';
  return precision == 'MONTH' ? ym : '$ym.${d.day.toString().padLeft(2, '0')}';
}

/// 정보 카드 — 해칭일·모프·부모 (2026-11-24). 내 개체 상세의 정보 카드(`PetInfoGrid`)와
/// 같은 순서·모양이고, **입양일은 뺐다** — 사육자 개인의 날짜라 남에게 보일 값이 아니다.
/// 부모 카드를 누르면 가계도와 똑같이 움직인다: 공개 개체면 공개 화면, 아니면 카드 시트.
class _InfoCard extends StatelessWidget {
  final NfcPetProfile profile;
  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final pet = profile.pet;
    final father = profile.father;
    final mother = profile.mother;
    return Container(
      width: double.infinity,
      decoration: AppDecor.cardRaised,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cell(
                label: pet.terms.hatchDate,
                value: _fmtDate(pet.hatchingDate, pet.hatchingDatePrecision),
                chip: pet.hatchingDateApproximate ? '부정확' : null,
              ),
              const SizedBox(width: AppSpacing.md),
              // 이별한 날 — 해칭일의 짝 자리. 없으면 빈 칸으로 열만 맞춘다
              pet.deceasedAt != null
                  ? _Cell(label: '이별한 날 🌈', value: _fmtDate(pet.deceasedAt))
                  : const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('모프', style: AppTextStyles.paleGridLabel),
          const SizedBox(height: AppSpacing.sm),
          if (pet.morphs.isEmpty)
            Text('-', style: AppTextStyles.paleGridValue)
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in pet.morphs)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: const BoxDecoration(
                      color: AppColors.bgAlt,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(
                      m.nameKo,
                      style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
              ],
            ),
          // 부모 — 등록된 부모가 있을 때만. 부·모 반씩, 한쪽만 있어도 빈 칸으로 폭을 고정한다
          if (father != null || mother != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('부모', style: AppTextStyles.paleGridLabel),
            const SizedBox(height: AppSpacing.xs),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: father != null
                        ? PedigreeParentCard(card: father)
                        : const SizedBox(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: mother != null
                        ? PedigreeParentCard(card: mother)
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final String? chip;
  const _Cell({required this.label, required this.value, this.chip});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.paleGridLabel),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Flexible(
                child: Text(value,
                    style: AppTextStyles.mono(13, FontWeight.w600)),
              ),
              if (chip != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brPill,
                    color: AppColors.petPeach,
                    border: Border.all(
                        color: AppColors.petPeachInk.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    chip!,
                    style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: AppColors.petPeachInk),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
