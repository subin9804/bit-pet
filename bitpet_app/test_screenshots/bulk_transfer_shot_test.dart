import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/features/pet/share/data/models/share_models.dart';
import 'package:bitpet_app/features/pet/share/presentation/bulk_share_sheet.dart';
import 'harness.dart';

/// 분양 보내기 시트 — 분양하면 나와 함께 키우던 사람이 빠진다는 안내 (2026-11-25 B안).
void main() {
  testWidgets('분양 보내기 시트', (t) async {
    await shot(
      t,
      'bulk_transfer_sheet',
      Scaffold(
        body: Builder(
          builder: (c) => Center(
            child: TextButton(
              onPressed: () => showBulkShareSheet(c,
                  petIds: const [1, 2], inviteType: ShareInviteType.transfer),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      before: (t) async {
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
      },
    );
  });
}
