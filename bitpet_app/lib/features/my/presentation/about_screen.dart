import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/external_links.dart';
import '../../../core/legal/legal_document_sheet.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 앱 정보 — 버전·약관·문의처.
///
/// 사업자 정보(상호·대표자·사업자등록번호)는 넣지 않는다. 전자상거래법 제10조의
/// 표시 의무는 재화를 파는 사이버몰에 걸리는 것이고, 앱 안에는 결제가 없다.
/// 판매는 스마트스토어에서 이뤄지고 그쪽 판매자정보가 이미 의무를 이행하고 있어서,
/// 여기서는 스토어로 보내는 링크를 두는 것으로 갈음한다.
///
/// ⚠️ 앱에 유료 구독·인앱결제를 붙이면 앱 자체가 통신판매가 되어 표시 의무가 생긴다.
///    그때 이 화면에 '사업자 정보' 항목을 추가해야 한다.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  /// null 이면 아직 읽는 중.
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = 'v${info.version} (${info.buildNumber})');
    } catch (_) {
      // 버전을 못 읽었다고 화면 전체를 막을 이유는 없다. 그 줄만 비워 둔다.
      if (mounted) setState(() => _version = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('앱 정보'),
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          _AppIdentity(version: _version),
          const SizedBox(height: 28),

          const _SectionLabel('약관·정책'),
          for (final doc in legalDocuments)
            _Row(
              label: doc.title,
              onTap: () => showLegalDocument(context, doc),
            ),
          _Row(
            label: '오픈소스 라이선스',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'tailog',
              applicationVersion: _version ?? '',
            ),
          ),

          const _SectionLabel('문의'),
          _Row(
            label: '문의하기',
            trailing: ExternalLinks.supportEmail,
            onTap: () => openMailTo(
              context,
              ExternalLinks.supportEmail,
              subject: '[tailog] 문의',
            ),
          ),
          _Row(
            label: '이름표 스토어',
            trailing: '스마트스토어',
            onTap: () =>
                openExternalLink(context, ExternalLinks.smartStore),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 tailog',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textDisabled),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// 앱 이름 + 버전. 버전은 pubspec 값을 런타임에 읽는다.
class _AppIdentity extends StatelessWidget {
  final String? version;
  const _AppIdentity({required this.version});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          color: AppColors.bg2,
          child: const Icon(Icons.pets, size: 30, color: AppColors.primary),
        ),
        const SizedBox(height: 14),
        Text('tailog', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        // 읽는 중에는 자리만 잡아둔다. 스피너를 돌리면 버전 한 줄 때문에
        // 화면이 로딩 중인 것처럼 보인다.
        SizedBox(
          height: 18,
          child: Text(
            version ?? '',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          text,
          style:
              AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label;

  /// 오른쪽에 덧붙일 값 (메일 주소 등). 없으면 화살표만.
  final String? trailing;
  final VoidCallback onTap;

  const _Row({required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.body)),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textDisabled),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textDisabled),
            ],
          ),
        ),
      );
}
