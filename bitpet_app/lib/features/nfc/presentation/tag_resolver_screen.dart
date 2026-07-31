import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/tag_models.dart';
import '../data/tag_repository.dart';
import 'tag_link_sheet.dart';

/// NFC 태그 스캔의 경유 화면.
///
/// OS가 `https://{host}/t/{tagCd}` 를 열어주면 go_router가 여기로 보낸다.
/// 앱은 NFC를 직접 읽지 않는다 — 이 화면은 딥링크로 받은 코드를 서버에 물어보고
/// status에 따라 라우팅만 한다.
///
/// * LINKED         → 개체 상세(+ 기본 동작에 따라 기록 시트)
/// * UNLINKED       → 개체 선택 모달 → 연결 → 개체 상세
/// * OWNED_BY_OTHER → 안내
/// * 404            → "유효하지 않은 태그"
class TagResolverScreen extends ConsumerStatefulWidget {
  final String tagCd;
  const TagResolverScreen({super.key, required this.tagCd});

  @override
  ConsumerState<TagResolverScreen> createState() => _TagResolverScreenState();
}

class _TagResolverScreenState extends ConsumerState<TagResolverScreen> {
  /// 라우팅은 딱 한 번만. 빌드가 여러 번 돌아도 중복 이동하지 않도록 잠근다.
  bool _handled = false;
  String? _errorMessage;
  TagStatus? _blockedStatus;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final result = await ref.read(tagRepositoryProvider).resolve(widget.tagCd);
      if (!mounted) return;
      switch (result.status) {
        case TagStatus.linked:
          _enterPet(result.petId!, result.defaultAction);
        case TagStatus.unlinked:
          await _promptLink();
        case TagStatus.ownedByOther:
          setState(() => _blockedStatus = TagStatus.ownedByOther);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            e.statusCode == 404 ? '유효하지 않은 태그입니다.' : e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '태그를 확인하지 못했어요. 잠시 후 다시 시도해 주세요.');
      }
    }
  }

  Future<void> _promptLink() async {
    final linked = await showTagLinkSheet(context, tagCd: widget.tagCd);
    if (!mounted) return;
    if (linked == null) {
      // 연결을 미룬 경우 — 태그 화면에 남겨두지 않고 홈으로
      context.go('/home');
      return;
    }
    _enterPet(linked.petId!, linked.defaultAction);
  }

  /// 개체 상세로 이동.
  ///
  /// 홈을 스택 하단에 깔고 그 위에 상세를 얹는다. 그러지 않으면 뒤로가기 한 번에
  /// 앱이 그대로 종료된다.
  void _enterPet(int petId, TagAction action) {
    if (_handled) return;
    _handled = true;
    final recordType = action.recordTypeId;
    final query = recordType == null ? '' : '?openRecord=$recordType';
    context.go('/home');
    context.push('/pets/$petId$query');
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _TagMessage(
        icon: Icons.link_off,
        title: '태그를 열 수 없어요',
        message: _errorMessage!,
        tagCd: widget.tagCd,
      );
    }
    if (_blockedStatus == TagStatus.ownedByOther) {
      return _TagMessage(
        icon: Icons.lock_outline,
        title: '이미 등록된 태그입니다',
        message: '다른 사육자의 개체에 연결되어 있어요.\n'
            '양도받은 태그라면 이전 소유자가 먼저 연결을 해제해야 합니다.',
        tagCd: widget.tagCd,
      );
    }
    return const Scaffold(
      backgroundColor: AppColors.paleBg,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _TagMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String tagCd;

  const _TagMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.tagCd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppColors.textDisabled),
              const SizedBox(height: 18),
              Text(title, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 14),
              Text(
                tagCd,
                style: AppTextStyles.mono(11, FontWeight.w700,
                    color: AppColors.paleInk3),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  height: 48,
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: AppColors.primary,
                  child: const Text(
                    '홈으로',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.paleBg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
