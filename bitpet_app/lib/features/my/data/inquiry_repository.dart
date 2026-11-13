import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// 문의 종류. 서버 `InquiryCategory` 의 거울이다.
enum InquiryCategory {
  bug('BUG', '오류 제보'),
  suggestion('SUGGESTION', '기능 제안'),
  account('ACCOUNT', '계정'),
  etc('ETC', '기타');

  final String code;
  final String label;
  const InquiryCategory(this.code, this.label);
}

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepository(ref.watch(dioProvider));
});

/// 개발자에게 문의하기 — 보내기만 있다. 답장 없는 일방향 건의함이라
/// 내가 보낸 문의를 다시 보는 API 도 없다.
class InquiryRepository {
  final Dio _dio;
  InquiryRepository(this._dio);

  Future<void> send({
    required InquiryCategory category,
    required String content,
    String? appVersion,
    String? platform,
    String? osVersion,
  }) async {
    await _dio.post('/inquiries', data: {
      'category': category.code,
      'content': content.trim(),
      'appVersion': ?appVersion,
      'platform': ?platform,
      'osVersion': ?osVersion,
    });
  }
}
