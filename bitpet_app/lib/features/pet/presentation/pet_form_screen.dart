import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  final int? petId; // null = 신규 등록
  const PetFormScreen({super.key, this.petId});

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _envCtrl = TextEditingController();

  int? _selectedSpeciesId;
  String _gender = 'UNKNOWN';
  String? _colorCode;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _envCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpeciesId == null) {
      ToastMessage.show(context, '종을 선택해주세요', type: ToastType.warning);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(petListProvider.notifier).add(
            CreatePetRequest(
              speciesId: _selectedSpeciesId!,
              name: _nameCtrl.text.trim(),
              gender: _gender,
              colorCode: _colorCode,
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              environmentMemo: _envCtrl.text.trim().isEmpty
                  ? null
                  : _envCtrl.text.trim(),
            ),
          );
      if (mounted) {
        ToastMessage.show(context, '개체가 등록되었습니다.', type: ToastType.success);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speciesAsync = ref.watch(speciesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petId == null ? '개체 등록' : '개체 수정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 종 선택
              Text('종 *', style: AppTextStyles.label),
              const SizedBox(height: 8),
              speciesAsync.when(
                loading: () =>
                    const LinearProgressIndicator(),
                error: (_, __) =>
                    const Text('종 목록 로드 실패'),
                data: (species) => DropdownButtonFormField<int>(
                  value: _selectedSpeciesId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(hintText: '종을 선택하세요'),
                  items: species
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nameKo),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSpeciesId = v),
                ),
              ),
              const SizedBox(height: 16),
              // 이름
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '이름 *'),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : '이름을 입력하세요',
              ),
              const SizedBox(height: 16),
              // 성별
              Text('성별', style: AppTextStyles.label),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'MALE', label: Text('수컷')),
                  ButtonSegment(value: 'FEMALE', label: Text('암컷')),
                  ButtonSegment(value: 'UNKNOWN', label: Text('미확인')),
                ],
                selected: {_gender},
                onSelectionChanged: (s) =>
                    setState(() => _gender = s.first),
              ),
              const SizedBox(height: 16),
              // 식별 색상
              Text('식별 색상 (HEX)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _colorCode,
                decoration: const InputDecoration(
                  labelText: '#RRGGBB',
                  hintText: '예: #39D353',
                ),
                onChanged: (v) => setState(() => _colorCode = v.isEmpty ? null : v),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final valid = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v);
                  return valid ? null : '올바른 HEX 색상을 입력하세요 (#RRGGBB)';
                },
              ),
              const SizedBox(height: 16),
              // 개체 소개
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: '개체 소개 (패턴·특징 등)'),
              ),
              const SizedBox(height: 16),
              // 사육환경
              TextFormField(
                controller: _envCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '사육환경 메모'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.petId == null ? '등록하기' : '저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
