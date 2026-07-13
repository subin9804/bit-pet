import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_shell.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/group_provider.dart';

// ════════════════════════════════════════════════════════════════
// 그룹 없는 유저 전용 온보딩 — 새 그룹 만들기 or 초대코드 입력
// ════════════════════════════════════════════════════════════════

class GroupSetupScreen extends ConsumerStatefulWidget {
  const GroupSetupScreen({super.key});

  @override
  ConsumerState<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends ConsumerState<GroupSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(groupActionProvider.notifier).create(name);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ToastMessage.show(context, e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinGroup() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ToastMessage.show(context, '6자리 코드를 입력하세요', type: ToastType.warning);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(groupActionProvider.notifier).join(code);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.errorCode == 'GROUP_INVITE_CODE_INVALID') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('초대코드 오류'),
            content: const Text('유효하지 않은 초대코드예요.\n코드를 다시 확인해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        ToastMessage.show(context, e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) ToastMessage.show(context, e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(myGroupProvider);

    // 그룹이 이미 있으면 홈으로
    return groupAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.paleBg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildSetupBody(context),
      data: (group) {
        if (group != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/home');
          });
          return const Scaffold(
            backgroundColor: AppColors.paleBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildSetupBody(context);
      },
    );
  }

  Widget _buildSetupBody(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 36, 26, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 워드마크
              const Text('bit-pet',
                  style: TextStyle(
                    fontFamily: 'CourierNew',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.paleInk2,
                    letterSpacing: 0.5,
                  )),
              const SizedBox(height: 20),
              // 타이틀
              const Text('사육 그룹 설정',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.7,
                  )),
              const SizedBox(height: 6),
              const Text('함께 개체를 돌볼 그룹을 설정해요.\n나중에 마이페이지에서 변경할 수 있어요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.paleInk2,
                    height: 1.55,
                  )),
              const SizedBox(height: 36),

              // ── 옵션 A: 새 그룹 만들기 ─────────────────────────────
              _OptionCard(
                icon: Icons.add_circle_outline,
                title: '새 그룹 만들기',
                subtitle: '내가 그룹장이 되어 시작해요',
                child: Column(
                  children: [
                    PaleTextField(
                      controller: _nameCtrl,
                      placeholder: '그룹 이름 (예: 고도네 사육실)',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _loading || _nameCtrl.text.trim().isEmpty
                          ? null
                          : _createGroup,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _nameCtrl.text.trim().isNotEmpty
                              ? AppColors.primary
                              : AppColors.paleLine,
                        ),
                        alignment: Alignment.center,
                        child: _loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.paleBg))
                            : Text(
                                '그룹 만들기',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _nameCtrl.text.trim().isNotEmpty
                                      ? AppColors.paleBg
                                      : AppColors.paleInk3,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 구분선
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.paleLine)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('또는',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.paleInk3,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: AppColors.paleLine)),
                ],
              ),

              const SizedBox(height: 14),

              // ── 옵션 B: 초대코드로 참여 ────────────────────────────
              _OptionCard(
                icon: Icons.group_add_outlined,
                title: '초대코드로 참여',
                subtitle: '다른 사람의 그룹에 멤버로 들어가요',
                child: Column(
                  children: [
                    PaleTextField(
                      controller: _codeCtrl,
                      placeholder: '6자리 코드 (예: AB3D7F)',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _loading || _codeCtrl.text.trim().length != 6
                          ? null
                          : _joinGroup,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _codeCtrl.text.trim().length == 6
                              ? AppColors.primary
                              : AppColors.paleLine,
                        ),
                        alignment: Alignment.center,
                        child: _loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.paleBg))
                            : Text(
                                '그룹 참여',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _codeCtrl.text.trim().length == 6
                                      ? AppColors.paleBg
                                      : AppColors.paleInk3,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.paleBgAlt,
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.primary,
                        )),
                    Text(subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.paleInk2,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
