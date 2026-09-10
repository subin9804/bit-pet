import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../data/pet_repository.dart';
import '../../providers/pet_provider.dart';

/// 모프 다중선택 바텀시트.
///
/// 개체 등록 스텝 안에 모프 칩을 전부 깔아두던 방식을 대체한다. 볼파이썬처럼 모프가
/// 50개를 넘는 종이 있어서 스텝 한 칸에 담기지 않았고, 스크롤을 내리면 뭘 골랐는지
/// 보이지 않는 문제가 있었다. 여기서는
///
///  - **검색**으로 좁히고 (한글명 · 영문명 · **별칭**까지)
///  - **선택된 것은 상단에 고정**해 항상 보이게 하고
///  - 카탈로그에 없는 조합 모프는 **직접 추가**할 수 있다
///
/// 별칭은 서버 `morph_cd.alias_list` 에 이미 들어 있던 데이터다 ('핀스'로 핀스트라이프,
/// 'LW'로 릴리화이트). 목록이 종당 최대 60개 수준이라 서버 autocomplete 를 호출하지 않고
/// 이미 받아둔 목록을 클라이언트에서 거른다 — 타이핑마다 네트워크를 타지 않고 오프라인에서도 된다.
///
/// 팝 결과값: 선택된 모프 목록 (`List<Morph>`) 또는 null (취소)
class MorphPickerSheet extends ConsumerStatefulWidget {
  final Species species;
  final List<Morph> initialSelection;

  const MorphPickerSheet({
    super.key,
    required this.species,
    this.initialSelection = const [],
  });

  @override
  ConsumerState<MorphPickerSheet> createState() => _MorphPickerSheetState();
}

class _MorphPickerSheetState extends ConsumerState<MorphPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  /// 선택 순서를 유지해야 표시 순서가 사용자가 고른 순서와 같아진다.
  late final List<Morph> _selected;

  /// 이번 시트에서 새로 만든 커스텀 모프. provider 를 즉시 invalidate 하면 목록이
  /// 로딩 상태로 깜빡이므로, 화면에는 로컬로 얹어 보여주고 갱신은 닫을 때 한 번만 한다.
  final List<Morph> _locallyAdded = [];

  bool _creating = false;
  String? _createError;

  @override
  void initState() {
    super.initState();
    _selected = List<Morph>.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isSelected(Morph m) => _selected.any((s) => s.id == m.id);

  void _toggle(Morph m) => setState(() {
        final i = _selected.indexWhere((s) => s.id == m.id);
        if (i >= 0) {
          _selected.removeAt(i);
        } else {
          _selected.add(m);
        }
      });

  /// 카탈로그에 없는 조합 모프를 서버에 등록하고 바로 선택 상태로 만든다.
  ///
  /// 서버는 같은 종에 같은 이름이 이미 있으면 새로 만들지 않고 그 모프를 돌려준다.
  /// 그래서 이미 있는 이름을 입력해도 중복이 생기지 않고 그냥 선택될 뿐이다.
  Future<void> _createCustom(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _creating) return;

    setState(() {
      _creating = true;
      _createError = null;
    });

    try {
      final created = await ref
          .read(petRepositoryProvider)
          .createCustomMorph(widget.species.id, trimmed);
      if (!mounted) return;
      setState(() {
        _creating = false;
        if (!_locallyAdded.any((m) => m.id == created.id)) {
          _locallyAdded.add(created);
        }
        if (!_isSelected(created)) _selected.add(created);
        _searchCtrl.clear();
        _query = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _createError = '모프를 추가하지 못했어요. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  void _close(List<Morph>? result) {
    // 커스텀 모프를 만들었다면 다음에 시트를 열 때 목록에 포함되도록 캐시를 비운다.
    if (_locallyAdded.isNotEmpty) {
      ref.invalidate(morphsBySpeciesProvider(widget.species.id));
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final morphsAsync = ref.watch(morphsBySpeciesProvider(widget.species.id));

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
          _buildSelectedStrip(),
          Expanded(
            child: morphsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('모프 목록을 불러오지 못했어요')),
              data: _buildList,
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
            Text('SELECT MORPH', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text('모프 선택', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              '${widget.species.nameKo} · 한글명, 영문명, 별칭으로 찾을 수 있어요',
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
          onChanged: (v) => setState(() {
            _query = v;
            _createError = null;
          }),
          decoration: InputDecoration(
            hintText: '예: 핀스, Pastel, 알비노',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _searchCtrl.clear();
                      _query = '';
                    }),
                  ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );

  /// 선택된 모프를 목록 위에 고정해서 보여준다. 목록을 아무리 스크롤해도
  /// 지금까지 뭘 골랐는지가 항상 보이는 게 이 시트의 핵심이다.
  Widget _buildSelectedStrip() {
    if (_selected.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text('아직 선택한 모프가 없어요', style: AppTextStyles.caption),
      );
    }
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 132),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택됨 ${_selected.length}', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selected
                  .map((m) => _SelectedChip(
                        morph: m,
                        onRemove: () => _toggle(m),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Morph> catalog) {
    // 서버 목록 + 이번에 만든 커스텀 모프(아직 캐시에 없음)
    final all = <Morph>[
      ...catalog,
      ..._locallyAdded.where((a) => !catalog.any((c) => c.id == a.id)),
    ];

    final q = _query.trim();
    final filtered = all.where((m) => m.matches(q)).toList();

    // 검색어와 이름이 정확히 같은 모프가 이미 있으면 '직접 추가'를 권할 이유가 없다.
    final exactExists =
        all.any((m) => m.nameKo.toLowerCase() == q.toLowerCase());
    final showAddTile = q.isNotEmpty && !exactExists;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 8),

        if (showAddTile) ...[
          _AddCustomTile(
            name: q,
            busy: _creating,
            onTap: _creating ? null : () => _createCustom(q),
          ),
          const SizedBox(height: 8),
        ],

        if (_createError != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _createError!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],

        if (filtered.isEmpty && !showAddTile)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                q.isEmpty ? '등록된 모프가 없어요' : "'$q' 와 맞는 모프가 없어요",
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textDisabled),
              ),
            ),
          )
        else
          ...filtered.map((m) => _MorphRow(
                morph: m,
                selected: _isSelected(m),
                query: q,
                onTap: () => _toggle(m),
              )),
      ],
    );
  }

  Widget _buildBottomButtons() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: OutlinedButton(
                  onPressed: () => _close(null),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              // 모프는 없어도 되는 정보라 0개 선택으로 닫는 것도 허용한다.
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _close(List<Morph>.from(_selected)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: Text(_selected.isEmpty
                      ? '선택 안 함'
                      : '${_selected.length}개 선택 · 완료'),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── 상단 고정 선택 칩 ────────────────────────────────────────────────────────

class _SelectedChip extends StatelessWidget {
  final Morph morph;
  final VoidCallback onRemove;

  const _SelectedChip({required this.morph, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 칩에는 한글명만 — 영문명까지 넣으면 칩이 길어져 Wrap 줄바꿈이 지저분해진다.
            Text(
              morph.nameKo,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.paleBg,
              ),
            ),
            if (morph.hasHealthConcern) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.warning_amber_rounded,
                size: 13,
                color: AppColors.paleBg.withValues(alpha: 0.85),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 14,
              color: AppColors.paleBg.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 목록 한 줄 ───────────────────────────────────────────────────────────────

class _MorphRow extends StatelessWidget {
  final Morph morph;
  final bool selected;
  final String query;
  final VoidCallback onTap;

  const _MorphRow({
    required this.morph,
    required this.selected,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 별칭으로 찾아온 경우 왜 이게 걸렸는지 보여준다 ('핀스' → 핀스트라이프)
    final matchedAliases = query.isEmpty
        ? const <String>[]
        : morph.aliases
            .where((a) => a.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.paleLine)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: selected ? AppColors.primary : AppColors.paleInk3,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          morph.nameKo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (morph.nameEn != null && morph.nameEn!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            morph.nameEn!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.paleInk2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (morph.isUserDefined) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration:
                              BoxDecoration(color: AppColors.bg2),
                          child: const Text(
                            '직접 입력',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.paleInk2,
                            ),
                          ),
                        ),
                      ],
                      if (morph.hasHealthConcern) ...[
                        const SizedBox(width: 6),
                        const Tooltip(
                          message: '건강 우려 모프',
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Color(0xFFCC8800),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (matchedAliases.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '별칭: ${matchedAliases.join(', ')}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.paleInk3,
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

// ─── 카탈로그에 없는 모프 직접 추가 타일 ──────────────────────────────────────

class _AddCustomTile extends StatelessWidget {
  final String name;
  final bool busy;
  final VoidCallback? onTap;

  const _AddCustomTile({
    required this.name,
    required this.busy,
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
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.add, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "'$name' 직접 추가",
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '카탈로그에 없는 조합 모프예요. 나에게만 보여요.',
                    style: AppTextStyles.caption,
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
