/// 태그에 굽힌 URL에서 태그 코드를 뽑아내는 파서.
///
/// 실물 태그는 되돌릴 수 없다 — 한 번 굽고 락을 걸면 그 URL은 영원히 그대로다.
/// 그래서 파싱은 관대해야 한다. 세대마다 호스트가 달라졌거나(`www.` 유무, `http`/`https`),
/// 뒤에 쿼리가 붙었어도 코드만 꺼낼 수 있으면 읽어준다.
library;

/// 태그 코드 형식 — Crockford Base32 6자 (I·L·O·U 제외). 서버 ck_nfc_tag_mst_cd_format 과 같다.
final RegExp _tagCodePattern = RegExp(r'^[0-9A-HJKMNP-TV-Z]{6}$');

/// 우리 태그로 인정하는 호스트. 서브도메인·`www.` 는 접미 일치로 함께 받는다.
const List<String> kTagHosts = ['tailog.me'];

/// `www.`·서브도메인까지 받는 호스트 대안. [kTagHosts] 에서 만들어 두 패턴이 함께 움직이게 한다
/// — 호스트를 늘렸는데 정규식만 안 따라오는 사고를 막는다.
final String _hostAlternation =
    '(?:[\\w-]+\\.)*(?:${kTagHosts.map(RegExp.escape).join('|')})';

/// 잡다한 문자열 속에 박힌 `tailog.me/t/{code}` 를 그대로 집어내는 패턴.
///
/// 앞의 `(?:^|[^\w.-])` 는 장식이 아니다. 이게 없으면 `nottailog.me/t/ABC123` 이
/// 4번째 글자부터 매치돼 남의 도메인 태그를 우리 것으로 읽는다.
final RegExp _embeddedPattern = RegExp(
  '(?:^|[^\\w.-])$_hostAlternation/t/([0-9A-HJKMNP-TV-Z]{6})(?![0-9A-Z])',
  caseSensitive: false,
);

/// NDEF에서 읽은 URL이 우리 태그인지 판정하고 코드를 꺼낸다.
///
/// * 우리 태그가 아니면 (다른 서비스의 NFC 카드, 교통카드 URL 등) → null
/// * 우리 호스트인데 코드 형식이 어긋나면 → null (구워진 쓰레기 값)
///
/// 반환값은 항상 대문자다. 소문자로 굽힌 구재고가 있어도 서버 PK와 어긋나지 않게
/// **여기서** 정규화한다 — 호출부마다 하면 언젠가 한 곳이 빠진다.
String? parseTagCode(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;

  // 문자열 어딘가에 'tailog.me/t/{code}' 가 통째로 박혀 있으면 그걸로 끝낸다.
  // TEXT 레코드는 앞에 상태 바이트·언어 코드가 붙고, 굽는 도구에 따라 잡다한 값이
  // 섞여 들어오기도 한다 — URL 파서만 믿으면 그런 태그를 전부 놓친다.
  final embedded = _embeddedPattern.firstMatch(text);
  if (embedded != null) return embedded.group(1)!.toUpperCase();

  final uri = Uri.tryParse(text);
  if (uri == null) return null;

  // 스킴 없이 'tailog.me/t/ABC123' 로 굽힌 경우 host가 비고 path에 전부 들어온다
  final host = uri.host.isNotEmpty ? uri.host.toLowerCase() : null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  if (host != null) {
    if (!kTagHosts.any((h) => host == h || host.endsWith('.$h'))) return null;
  } else {
    // host가 없으면 첫 세그먼트가 호스트일 수 있다
    if (segments.isEmpty) return null;
    final first = segments.first.toLowerCase();
    if (!kTagHosts.any((h) => first == h || first.endsWith('.$h'))) return null;
    segments.removeAt(0);
  }

  // /t/{tagCd} — 't' 다음 세그먼트가 코드다. 그 뒤에 뭐가 더 붙어 있어도 무시한다
  final tIndex = segments.indexOf('t');
  if (tIndex < 0 || tIndex + 1 >= segments.length) return null;

  final code = segments[tIndex + 1].toUpperCase();
  return _tagCodePattern.hasMatch(code) ? code : null;
}

/// 우리 호스트이긴 한지 — 코드가 깨졌을 때 "다른 서비스 태그"와 구분해 안내하려고 쓴다.
///
/// [parseTagCode] 가 null을 준 뒤 이게 true면 "우리 이름표인데 코드가 깨졌다"는 뜻이라
/// 안내 문구가 달라진다. 그래서 여기도 파서와 같은 관대함을 유지한다.
bool isTagHost(String? raw) {
  if (raw == null) return false;
  final text = raw.trim();
  if (text.isEmpty) return false;

  if (_hostPattern.hasMatch(text)) return true;

  final uri = Uri.tryParse(text);
  if (uri == null) return false;
  final host = uri.host.isNotEmpty
      ? uri.host.toLowerCase()
      : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first.toLowerCase() : '');
  return kTagHosts.any((h) => host == h || host.endsWith('.$h'));
}

/// 코드까지 보지 않고 호스트만 찾는 패턴. [_embeddedPattern] 과 짝이다.
final RegExp _hostPattern = RegExp(
  '(?:^|[^\\w.-])$_hostAlternation(?=[/:?#]|\$)',
  caseSensitive: false,
);
