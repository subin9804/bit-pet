package io.bitpet.common.legal;

import io.bitpet.auth.domain.AgreementType;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 약관 공개 페이지 — {@code https://tailog.me/legal/{id}}.
 *
 * <p>스토어 심사는 개인정보처리방침을 <b>앱 밖에서 열리는 URL</b>로 요구한다(Play 콘솔
 * '앱 콘텐츠'). 앱 안의 약관 시트만으로는 안 된다.
 *
 * <p><b>원문은 앱의 {@code lib/core/legal/legal_documents.dart} 가 정본</b>이고
 * {@code resources/legal/*.txt} 는 그 사본이다. 두 곳이 다르면 사용자가 앱에서 동의한 약관과
 * 웹에 공개된 약관이 달라진다 — {@code LegalDocumentsSyncTest} 가 이를 막는다.
 * 시행일은 {@link AgreementType} 버전을 그대로 쓴다(재동의 기준과 같은 값).
 */
@Tag(name = "Legal")
@RestController
public class LegalPageController {

    private static final String HTML = MediaType.TEXT_HTML_VALUE + ";charset=UTF-8";

    /** 공개 순서 그대로. id 는 앱 문서 id 와 같다. */
    static final Map<String, Doc> DOCS = new LinkedHashMap<>();
    static {
        DOCS.put("tos", new Doc("서비스 이용약관", AgreementType.TOS));
        DOCS.put("privacy", new Doc("개인정보 처리방침", AgreementType.PRIVACY));
        DOCS.put("age", new Doc("만 14세 이상 확인", AgreementType.AGE_14));
        DOCS.put("guardian", new Doc("법정대리인 동의", AgreementType.GUARDIAN));
        DOCS.put("marketing", new Doc("마케팅 정보 수신 동의", AgreementType.MARKETING));
    }

    record Doc(String title, AgreementType type) {}

    @Operation(summary = "약관 목록 (공개 HTML)")
    @GetMapping(value = "/legal", produces = HTML)
    public String index() {
        StringBuilder list = new StringBuilder();
        DOCS.forEach((id, doc) -> list.append("<li><a href=\"/legal/").append(id).append("\">")
                .append(escape(doc.title())).append("</a></li>"));
        list.append("<li><a href=\"/legal/account-deletion\">계정 삭제 안내</a></li>");
        return page("약관 및 정책", "<h1>약관 및 정책</h1><ul class=\"docs\">" + list + "</ul>");
    }

    /**
     * 계정 삭제 안내 — Play 콘솔 '데이터 보안 > 데이터 삭제'가 요구하는 <b>앱 밖에서 열리는</b>
     * 삭제 방법 URL. 앱을 지운 사람도 계정을 지울 길이 있어야 한다.
     *
     * <p>동의를 받는 약관이 아니라서 {@link #DOCS} 에 넣지 않는다 — 넣으면 AgreementType 과
     * 앱 원문이 있어야 하는 {@code LegalDocumentsSyncTest} 에 걸린다. 원문은 서버에만 있다.
     * 리터럴 경로라 {@code /legal/{id}} 보다 먼저 매칭된다.
     */
    @Operation(summary = "계정 삭제 안내 (공개 HTML)")
    @GetMapping(value = "/legal/account-deletion", produces = HTML)
    public String accountDeletion() {
        String body = """
                <h1>계정 삭제 안내</h1>
                <div class="body">%s</div>
                <p class="back"><a href="/legal">약관 목록</a></p>
                """.formatted(escape(read("legal-info/account-deletion.txt")));
        return page("계정 삭제 안내", body);
    }

    @Operation(summary = "약관 원문 (공개 HTML)")
    @GetMapping(value = "/legal/{id}", produces = HTML)
    public ResponseEntity<String> document(@PathVariable String id) {
        Doc doc = DOCS.get(id);
        if (doc == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .contentType(MediaType.valueOf(HTML))
                    .body(page("찾을 수 없는 문서",
                            "<h1>찾을 수 없는 문서</h1><p class=\"meta\"><a href=\"/legal\">약관 목록</a></p>"));
        }
        String body = """
                <h1>%s</h1>
                <p class="meta">시행일 %s</p>
                <div class="body">%s</div>
                <p class="back"><a href="/legal">약관 목록</a></p>
                """.formatted(escape(doc.title()), doc.type().currentVersion(), escape(text(id)));
        return ResponseEntity.ok().contentType(MediaType.valueOf(HTML)).body(page(doc.title(), body));
    }

    static String text(String id) {
        return read("legal/" + id + ".txt");
    }

    private static String read(String path) {
        try {
            return new ClassPathResource(path).getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static String page(String title, String body) {
        return """
                <!doctype html>
                <html lang="ko">
                <head>
                  <meta charset="utf-8">
                  <meta name="viewport" content="width=device-width,initial-scale=1">
                  <link rel="icon" href="/brand/favicon.png">
                  <title>%s · 테일로그</title>
                  <style>
                    :root { color-scheme: light; }
                    * { box-sizing: border-box; }
                    body { margin:0; padding:32px 16px 48px; background:#F4FBF6; color:#2B2A26;
                           font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,
                                       "Apple SD Gothic Neo","Noto Sans KR",sans-serif; }
                    header { text-align:center; margin-bottom:18px; }
                    .wordmark { height:22px; opacity:.5; }
                    main { max-width:720px; margin:0 auto; background:#fff; border:1px solid #E4EFE8;
                           padding:28px 22px; }
                    h1 { font-size:22px; margin:0 0 6px; letter-spacing:-.02em; }
                    .meta { font-size:13px; color:#6B7A70; margin:0 0 20px; }
                    /* 원문 줄바꿈·들여쓰기를 그대로 살린다 — 앱 시트와 같은 모양 */
                    .body { white-space:pre-wrap; word-break:keep-all; overflow-wrap:anywhere;
                            font-size:14px; line-height:1.75; }
                    .docs { list-style:none; padding:0; margin:16px 0 0; }
                    .docs li { border-top:1px solid #EFF5F1; }
                    .docs a { display:block; padding:14px 2px; color:#2B2A26; text-decoration:none; }
                    .back { margin:28px 0 0; font-size:13px; }
                    a { color:#3E7A5E; }
                  </style>
                </head>
                <body>
                  <header><a href="/legal"><img class="wordmark" src="/brand/logo.svg" alt="TAILOG"></a></header>
                  <main>
                %s
                  </main>
                </body>
                </html>
                """.formatted(escape(title), body);
    }

    private static String escape(String raw) {
        if (raw == null) return "";
        return raw.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }
}
