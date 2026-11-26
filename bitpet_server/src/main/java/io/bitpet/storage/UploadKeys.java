package io.bitpet.storage;

import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * 업로드 키·content-type 규칙의 단일 지점 — 사진·게시글·프로필이 같이 쓴다.
 *
 * <p><b>content-type 은 서버가 확장자 허용 목록에서 정한다.</b> 앱이 보낸 값을 그대로
 * 서명하면 {@code text/html} 같은 걸로 올려 버킷 도메인에서 스크립트가 도는 파일을 만들 수 있다.
 * 목록에 없는 확장자는 확장자를 떼고 {@code application/octet-stream} 으로 서명한다 —
 * 브라우저가 렌더링하지 않는 타입이고, 앱도 같은 규칙(`contentTypeFor`)이라 PUT 헤더가 맞는다.
 *
 * <p><b>등록 시 키는 서버가 발급한 모양인지 대조한다</b> ({@link #isIssued}). 키를 그대로 믿으면
 * 남의 경로(다른 개체·글·사람의 파일)를 내 사진으로 등록했다가 삭제하면서 그 파일을 지울 수 있다.
 */
public final class UploadKeys {

    private static final Map<String, String> IMAGE_TYPES = Map.of(
            "jpg", "image/jpeg",
            "jpeg", "image/jpeg",
            "png", "image/png",
            "webp", "image/webp",
            "heic", "image/heic",
            "heif", "image/heif");

    private static final String FALLBACK_TYPE = "application/octet-stream";

    /** {@code <uuid>} 또는 {@code <uuid>.<허용 확장자>} — 썸네일({@code _thumb.jpg})은 여기서 받지 않는다 */
    private static final Pattern ISSUED_NAME = Pattern.compile(
            "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(\\.(jpg|jpeg|png|webp|heic|heif))?");

    private UploadKeys() {
    }

    /** 허용 목록에 있는 확장자(소문자)만 돌려준다. 없거나 모르는 확장자면 빈 문자열 */
    public static String extension(String filename) {
        if (filename == null) return "";
        int dot = filename.lastIndexOf('.');
        if (dot < 0) return "";
        String ext = filename.substring(dot + 1).toLowerCase();
        return IMAGE_TYPES.containsKey(ext) ? ext : "";
    }

    public static String contentType(String ext) {
        return IMAGE_TYPES.getOrDefault(ext, FALLBACK_TYPE);
    }

    /** {@code prefix} 는 {@code pets/12/} 처럼 슬래시로 끝나야 한다 */
    public static String newKey(String prefix, String ext) {
        return prefix + UUID.randomUUID() + (ext.isEmpty() ? "" : "." + ext);
    }

    /** {@link #newKey} 가 {@code prefix} 아래에 만들 수 있는 모양인지 */
    public static boolean isIssued(String key, String prefix) {
        return key != null
                && key.startsWith(prefix)
                && ISSUED_NAME.matcher(key.substring(prefix.length())).matches();
    }
}
