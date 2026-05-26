import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';
import 'widgets/species_bottom_sheet.dart';
import 'widgets/parent_pet_bottom_sheet.dart';

/// 03.png + 03b.png — 개체 등록/수정 폼 화면
class PetFormScreen extends ConsumerStatefulWidget {
  final int? petId; // null = 신규 등록
  const PetFormScreen({super.key, this.petId});

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(text: '0.0');
  final _memoCtrl = TextEditingController();

  Species? _selectedSpecies;
  String? _morphText;
  String _gender = 'MALE'; // 기본값: 수컷
  int _identityColorIdx = 5; // 기본값: 인디핑크 (palette[5])
  DateTime? _hatchingDate;
  bool _hatchingUnknown = false;
  DateTime? _adoptionDate;
  bool _adoptionUnknown = false;
  String _weightUnit = 'g';
  Pet? _fatherPet;
  Pet? _motherPet;
  bool _isLoading = false;

  // ─── 색상 팔레트 HEX (AppColors.petColorPalette 순서와 동일) ───────────────
  static const _paletteHex = [
    '#E2F5ED', // 0: 민트
    '#FBE4D8', // 1: 연주황
    '#D8F3FF', // 2: 연하늘
    '#EAE2FF', // 3: 연보라
    '#FFF7D8', // 4: 연노랑
    '#FFD8D8', // 5: 인디핑크
  ];

  Color get _identityColor =>
      AppColors.petColorPalette[_identityColorIdx];
  String get _identityColorHex => _paletteHex[_identityColorIdx];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  // ─── 액션 ─────────────────────────────────────────────────────────────────

  /// 종 선택 바텀시트 열기 (03c)
  Future<void> _openSpeciesSheet() async {
    final result = await showModalBottomSheet<Species>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          SpeciesBottomSheet(initialSelection: _selectedSpecies),
    );
    if (result != null) {
      setState(() {
        _selectedSpecies = result;
        _morphText = null; // 종 변경 시 모프 초기화
      });
    }
  }

  /// 부모 개체 선택 바텀시트 열기 (03d)
  Future<void> _openParentSheet({required bool isFather}) async {
    final result = await showModalBottomSheet<Pet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPetBottomSheet(
        isFather: isFather,
        initialSelection: isFather ? _fatherPet : _motherPet,
      ),
    );
    if (result != null) {
      setState(() {
        if (isFather) {
          _fatherPet = result;
        } else {
          _motherPet = result;
        }
      });
    }
  }

  /// 날짜 피커
  Future<void> _pickDate({required bool isHatching}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isHatching
          ? (_hatchingDate ?? now)
          : (_adoptionDate ?? now),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isHatching) {
          _hatchingDate = picked;
          _hatchingUnknown = false;
        } else {
          _adoptionDate = picked;
          _adoptionUnknown = false;
        }
      });
    }
  }

  /// 모프 직접 입력 다이얼로그
  Future<void> _openMorphInput() async {
    final ctrl = TextEditingController(text: _morphText);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('모프 직접 입력', style: AppTextStyles.h3),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '모프명을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, ctrl.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _morphText = result.isEmpty ? null : result);
    }
  }

  /// 폼 제출 (개체 등록)
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecies == null) {
      ToastMessage.show(
        context,
        '종을 선택해주세요',
        type: ToastType.warning,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 몸무게 계산 (g 기준으로 통일)
      final rawWeight = double.tryParse(_weightCtrl.text);
      final currentWeightG = rawWeight != null && rawWeight > 0
          ? (_weightUnit == 'kg' ? rawWeight * 1000 : rawWeight)
          : null;

      // 날짜 포맷 (yyyy-MM-dd)
      String? formatDate(DateTime? dt) {
        if (dt == null) return null;
        return '${dt.year}-'
            '${dt.month.toString().padLeft(2, '0')}-'
            '${dt.day.toString().padLeft(2, '0')}';
      }

      await ref.read(petListProvider.notifier).add(
            CreatePetRequest(
              speciesId: _selectedSpecies!.id,
              name: _nameCtrl.text.trim(),
              gender: _gender,
              colorCode: _identityColorHex,
              morphText: _morphText,
              hatchingDate: _hatchingUnknown
                  ? null
                  : formatDate(_hatchingDate),
              adoptionDate: _adoptionUnknown
                  ? null
                  : formatDate(_adoptionDate),
              currentWeightG: currentWeightG,
              fatherPetId: _fatherPet?.id,
              motherPetId: _motherPet?.id,
              description: _memoCtrl.text.trim().isEmpty
                  ? null
                  : _memoCtrl.text.trim(),
            ),
          );

      if (mounted) {
        ToastMessage.show(
          context,
          '개체가 등록되었습니다!',
          type: ToastType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(20, 24, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 사진 + 아이덴티티 컬러
              _buildProfileSection(),
              const SizedBox(height: 28),

              // 이름 *
              _buildNameField(),
              const SizedBox(height: 20),

              // 종 *
              _buildSpeciesField(),
              const SizedBox(height: 20),

              // 모프
              _buildMorphField(),
              const SizedBox(height: 20),

              // 성별
              _buildGenderToggle(),
              const SizedBox(height: 20),

              // 해칭일
              _buildDateField(isHatching: true),
              const SizedBox(height: 20),

              // 입양일
              _buildDateField(isHatching: false),
              const SizedBox(height: 20),

              // 현재 몸무게
              _buildWeightField(),
              const SizedBox(height: 20),

              // 부모 개체
              _buildParentSection(),
              const SizedBox(height: 20),

              // 메모
              _buildMemoField(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 72,
      leading: TextButton(
        onPressed: () => context.pop(),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.only(left: 16),
        ),
        child: Text('취소', style: AppTextStyles.body),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.petId == null ? '개체 등록' : '개체 수정',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 1),
          Text(
            widget.petId == null ? 'NEW' : 'EDIT',
            style: AppTextStyles.label.copyWith(
              letterSpacing: 2.5,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(56, 38),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('저장'),
          ),
        ),
      ],
    );
  }

  // ─── 프로필 + 아이덴티티 컬러 ─────────────────────────────────────────────

  Widget _buildProfileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필 이미지
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: _identityColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  '🦎',
                  style: TextStyle(fontSize: 44),
                ),
              ),
            ),
            // 카메라 버튼
            Positioned(
              bottom: -4,
              right: -4,
              child: GestureDetector(
                onTap: () => ToastMessage.show(
                  context,
                  '이미지 선택 기능은 준비 중이에요',
                  type: ToastType.info,
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // 아이덴티티 컬러 팔레트
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IDENTITY COLOR', style: AppTextStyles.label),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0;
                      i < AppColors.petColorPalette.length;
                      i++)
                    _ColorChip(
                      color: AppColors.petColorPalette[i],
                      isSelected: _identityColorIdx == i,
                      onTap: () =>
                          setState(() => _identityColorIdx = i),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '사진 배경과 식별 칩에 사용됩니다.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 이름 ──────────────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: '이름', isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameCtrl,
          decoration:
              const InputDecoration(hintText: '개체 이름'),
          validator: (v) =>
              v != null && v.trim().isNotEmpty ? null : '이름을 입력해주세요',
        ),
      ],
    );
  }

  // ─── 종 ───────────────────────────────────────────────────────────────────

  Widget _buildSpeciesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: '종', isRequired: true),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openSpeciesSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSpecies?.nameKo ?? '종을 선택하세요',
                    style: AppTextStyles.body.copyWith(
                      color: _selectedSpecies == null
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 모프 ──────────────────────────────────────────────────────────────────

  Widget _buildMorphField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: '모프'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 입력된 모프 칩
            if (_morphText != null)
              Chip(
                label: Text(_morphText!,
                    style: AppTextStyles.caption),
                backgroundColor: AppColors.bg2,
                side: const BorderSide(color: AppColors.border),
                onDeleted: () =>
                    setState(() => _morphText = null),
                deleteIconColor: AppColors.textSecondary,
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
            // 직접 입력 버튼
            GestureDetector(
              onTap: _openMorphInput,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid),
                ),
                child: Text(
                  '+ 직접 입력',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
        // 종 미선택 시 안내 문구
        if (_selectedSpecies == null) ...[
          const SizedBox(height: 8),
          Text(
            '종을 선택하면 추천 모프가 여기에 나타나요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textDisabled),
          ),
          Text(
            '종을 먼저 선택하면 모프 후보가 표시돼요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textDisabled),
          ),
        ],
      ],
    );
  }

  // ─── 성별 ──────────────────────────────────────────────────────────────────

  Widget _buildGenderToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: '성별'),
        const SizedBox(height: 8),
        _GenderToggle(
          selected: _gender,
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }

  // ─── 날짜 (해칭일 / 입양일) ────────────────────────────────────────────────

  Widget _buildDateField({required bool isHatching}) {
    final label = isHatching ? '해칭일' : '입양일';
    final date = isHatching ? _hatchingDate : _adoptionDate;
    final isUnknown =
        isHatching ? _hatchingUnknown : _adoptionUnknown;

    String formatDate(DateTime dt) =>
        '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 8),
        // 날짜 입력창
        GestureDetector(
          onTap: isUnknown
              ? null
              : () => _pickDate(isHatching: isHatching),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isUnknown
                  ? AppColors.bg2
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: isUnknown
                      ? AppColors.textDisabled
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  date != null
                      ? formatDate(date)
                      : '날짜 선택',
                  style: AppTextStyles.body.copyWith(
                    color: date == null || isUnknown
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 모르겠어요 체크박스
        GestureDetector(
          onTap: () => setState(() {
            if (isHatching) {
              _hatchingUnknown = !_hatchingUnknown;
              if (_hatchingUnknown) _hatchingDate = null;
            } else {
              _adoptionUnknown = !_adoptionUnknown;
              if (_adoptionUnknown) _adoptionDate = null;
            }
          }),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: isUnknown,
                  onChanged: (v) => setState(() {
                    if (isHatching) {
                      _hatchingUnknown = v ?? false;
                      if (_hatchingUnknown) _hatchingDate = null;
                    } else {
                      _adoptionUnknown = v ?? false;
                      if (_adoptionUnknown)
                        _adoptionDate = null;
                    }
                  }),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Text('모르겠어요',
                  style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 현재 몸무게 ───────────────────────────────────────────────────────────

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: '현재 몸무게'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 수치 입력
            Expanded(
              child: TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  suffixText: _weightUnit,
                  suffixStyle: AppTextStyles.body
                      .copyWith(color: AppColors.textDisabled),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // g / kg 토글
            _UnitToggle(
              selected: _weightUnit,
              onChanged: (v) => setState(() => _weightUnit = v),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '이후 기록 탭에 자동으로 누적됩니다.',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }

  // ─── 부모 개체 ─────────────────────────────────────────────────────────────

  Widget _buildParentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: '부모 개체'),
        const SizedBox(height: 8),
        _ParentPetTile(
          isFather: true,
          pet: _fatherPet,
          onTap: () => _openParentSheet(isFather: true),
          onClear: () => setState(() => _fatherPet = null),
        ),
        const SizedBox(height: 8),
        _ParentPetTile(
          isFather: false,
          pet: _motherPet,
          onTap: () => _openParentSheet(isFather: false),
          onClear: () => setState(() => _motherPet = null),
        ),
        const SizedBox(height: 8),
        Text(
          '일련번호로 등록된 개체를 검색해 연결할 수 있어요.',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }

  // ─── 메모 ──────────────────────────────────────────────────────────────────

  Widget _buildMemoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(text: '메모'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _memoCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText:
                '예: 온도 26°C · 습도 70%\n2024.11.18 — 첫 동물병원 검진 (이상 없음)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '사육환경·병원 기록·관찰 등 자유롭게 작성하세요.',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 재사용 서브위젯
// ═══════════════════════════════════════════════════════════════════════════════

/// 섹션 레이블 (예: "이름 *", "종 *", "모프")
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  const _FieldLabel({required this.text, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: AppTextStyles.bodyBold),
        if (isRequired)
          Text(
            ' *',
            style: AppTextStyles.bodyBold
                .copyWith(color: AppColors.error),
          ),
      ],
    );
  }
}

/// 아이덴티티 컬러 원형 칩
class _ColorChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check,
                size: 14, color: AppColors.primary)
            : null,
      ),
    );
  }
}

/// 성별 3단 토글 (수컷 / 암컷 / 미상)
class _GenderToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _GenderToggle({
    required this.selected,
    required this.onChanged,
  });

  static const _options = <(String, String)>[
    ('MALE', '수컷'),
    ('FEMALE', '암컷'),
    ('UNKNOWN', '미상'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in _options)
            _GenderSegment(
              value: value,
              label: label,
              isSelected: selected == value,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _GenderSegment extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderSegment({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// g / kg 단위 토글
class _UnitToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _UnitToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['g', 'kg'].map((unit) {
          final isSel = selected == unit;
          return GestureDetector(
            onTap: () => onChanged(unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSel ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unit,
                style: AppTextStyles.caption.copyWith(
                  color: isSel
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSel
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 부모 개체 연결 타일 (연결 전 / 연결 후)
class _ParentPetTile extends StatelessWidget {
  final bool isFather;
  final Pet? pet;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ParentPetTile({
    required this.isFather,
    required this.pet,
    required this.onTap,
    required this.onClear,
  });

  String get _genderSymbol => isFather ? '♂' : '♀';
  String get _genderLabel => isFather ? '부 (수컷)' : '모 (암컷)';
  Color get _chipBg =>
      isFather ? AppColors.petColorPeach : AppColors.bg2;

  Color _identityColorOf(Pet p) {
    if (p.colorCode == null) return AppColors.bg2;
    try {
      return Color(
          int.parse(p.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.bg2;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 연결된 개체 없음 → 검색 유도 타일
    if (pet == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // 성별 칩
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _chipBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _genderSymbol,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isFather
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_genderLabel,
                        style: AppTextStyles.caption),
                    const SizedBox(height: 1),
                    Text(
                      '일련번호로 검색해 추가',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.search,
                color: AppColors.textDisabled,
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    // 연결된 개체 있음 → 개체 정보 표시
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.2),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _identityColorOf(pet!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('🦎', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(pet!.name,
                          style: AppTextStyles.bodyBold,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _genderSymbol,
                      style: TextStyle(
                        fontSize: 13,
                        color: isFather
                            ? AppColors.male
                            : AppColors.female,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${pet!.serialNo} · ${pet!.speciesName}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textDisabled),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 해제 버튼
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.textDisabled,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
