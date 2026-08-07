import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/nfc/data/models/tag_models.dart';
import '../../features/nfc/data/tag_repository.dart';
import '../api/api_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'nfc_reader.dart';
import 'pet_summary.dart';

/// 태그를 찍어 개체 하나를 고르는 바텀시트. 고른 개체를 돌려주고, 취소하면 null.
///
/// 개체 선택이 필요한 자리라면 어디든 '목록에서 선택'의 짝으로 붙일 수 있다
/// (가계도 부모 등록, 메이팅 상대 지정 등).
///
/// ```dart
/// final picked = await showNfcPetScanSheet(context);
/// if (picked != null) selectParent(picked.card);
/// ```
Future<PetSummary?> showNfcPetScanSheet(
  BuildContext context, {
  String title = '이름표로 찾기',
  String? subtitle,
}) {
  return showModalBottomSheet<PetSummary>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // 스캔 중에는 리더 모드로 NFC를 선점한다. 바깥을 눌러 닫으면 dispose에서 해제된다
    builder: (_) => NfcPetScanSheet(title: title, subtitle: subtitle),
  );
}

class NfcPetScanSheet extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;

  const NfcPetScanSheet({super.key, this.title = '이름표로 찾기', this.subtitle});

  @override
  ConsumerState<NfcPetScanSheet> createState() => _NfcPetScanSheetState();
}

class _NfcPetScanSheetState extends ConsumerState<NfcPetScanSheet> {
  final _reader = NfcReader();

  /// 태그 하나를 처리하는 동안 다음 태그를 받지 않는다.
  /// 카드를 갖다 대면 폴링이 연속으로 물려 같은 태그가 여러 번 들어온다.
  bool _busy = false;
  bool _nfcAvailable = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    // ⚠️ 여기서 해제하지 않으면 시트를 닫은 뒤에도 리더 모드가 살아 있어
    //    태그를 찍어도 딥링크(App Link)가 뜨지 않는다. 시작한 쪽이 끝낸다.
    _reader.stop();
    super.dispose();
  }

  Future<void> _startScan() async {
    final available = await NfcReader.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _nfcAvailable = false;
        _message = '이 기기에서 NFC를 쓸 수 없어요.\n설정에서 NFC가 켜져 있는지 확인해 주세요.';
      });
      return;
    }
    try {
      await _reader.start(
        onTagCode: _onTagCode,
        onForeignTag: () {
          if (mounted) setState(() => _message = 'tailog 이름표가 아닙니다.');
        },
      );
    } catch (e) {
      if (mounted) setState(() => _message = '스캔을 시작하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _onTagCode(String tagCd) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final result = await ref.read(tagRepositoryProvider).scan(tagCd);
      if (!mounted) return;

      final pet = result.pet;
      if (pet != null) {
        // 남의 개체(OWNED_BY_OTHER)도 그대로 돌려준다 — 부모 등록처럼 남의 개체가
        // 정당하게 필요한 자리가 있다. 쓸 수 있는지는 호출부가 PetSummary.isMine 으로 판단한다
        await _reader.stop();
        if (mounted) {
          Navigator.of(context).pop(PetSummary(tagCd: result.tagCd, card: pet));
        }
        return;
      }

      setState(() {
        _busy = false;
        _message = switch (result.status) {
          TagStatus.revoked => '사용이 중지된 이름표예요.\n분실·복제 신고로 차단된 태그입니다.',
          // 개체가 지워졌거나 주인이 탈퇴한 태그도 여기로 온다 (서버가 UNLINKED로 내린다)
          _ => '아직 개체와 연결되지 않은 이름표예요.\n마이페이지 › 이름표 관리에서 연결할 수 있어요.',
        };
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.statusCode == 404 ? '유효하지 않은 이름표입니다.' : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = '태그를 확인하지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.paleLine)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(
                widget.subtitle ?? '개체에 달린 이름표에 휴대폰 뒷면을 가까이 대주세요.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 28),
              Center(
                child: Icon(
                  _nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                  size: 56,
                  color: _nfcAvailable
                      ? AppColors.primary
                      : AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  height: 20,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.paleLine),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
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
