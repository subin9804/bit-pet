package io.bitpet.nfc.controller;

import io.bitpet.common.config.DeeplinkProperties;
import io.bitpet.nfc.service.NfcTagService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

/**
 * 앱 미설치자용 랜딩 페이지.
 *
 * <p>태그를 스캔하면 OS 가 {@code https://{host}/t/{tagCd}} 를 연다. 앱이 설치되어 있고 App Links
 * 검증이 끝났다면 브라우저를 거치지 않고 앱이 열리므로 이 페이지는 보이지 않는다.
 * 미설치자에게 404 가 뜨는 것이 최악이므로 반드시 이 페이지가 있어야 한다.
 *
 * <p><b>노출 범위</b> — 개체 이름까지만. 체중·급여 등 사육 기록은 절대 내려주지 않는다.
 */
@Tag(name = "Deep Link")
@RestController
@RequiredArgsConstructor
public class TagLandingController {

    private final NfcTagService nfcTagService;
    private final DeeplinkProperties deeplinkProperties;

    @Operation(summary = "NFC 태그 랜딩 페이지 (미설치자용 HTML)")
    @GetMapping(value = "/t/{tagCd}", produces = MediaType.TEXT_HTML_VALUE + ";charset=UTF-8")
    public ResponseEntity<String> landing(@PathVariable String tagCd) {
        Optional<String> petName;
        try {
            petName = nfcTagService.peekPetName(tagCd);
        } catch (Exception e) {
            petName = Optional.empty();
        }

        String headline = petName
                .map(n -> escape(n) + " 의 이름표")
                .orElse("비트펫 이름표");
        String subline = petName.isPresent()
                ? "앱에서 이 태그를 스캔하면 개체 상세로 바로 들어갑니다."
                : "아직 개체와 연결되지 않은 태그입니다. 앱에서 스캔해 연결해 주세요.";

        return ResponseEntity.ok(page(headline, subline, escape(tagCd)));
    }

    /** 존재하지 않는 태그 코드 — 위조 차단. 404 지만 빈 화면 대신 안내를 보여준다. */
    @GetMapping(value = "/t", produces = MediaType.TEXT_HTML_VALUE + ";charset=UTF-8")
    public ResponseEntity<String> landingWithoutCode() {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .contentType(MediaType.valueOf(MediaType.TEXT_HTML_VALUE + ";charset=UTF-8"))
                .body(page("유효하지 않은 태그", "태그 코드가 확인되지 않습니다.", ""));
    }

    private String page(String headline, String subline, String tagCd) {
        String store = escape(deeplinkProperties.playStoreUrl());
        String codeBlock = tagCd.isEmpty() ? ""
                : "<p class=\"code\">" + tagCd + "</p>";
        return """
                <!doctype html>
                <html lang="ko">
                <head>
                  <meta charset="utf-8">
                  <meta name="viewport" content="width=device-width,initial-scale=1">
                  <meta name="robots" content="noindex">
                  <title>%s · bit-pet</title>
                  <style>
                    :root { color-scheme: light; }
                    body { margin:0; min-height:100vh; display:flex; align-items:center;
                           justify-content:center; background:#F5F2EA; color:#2B2A26;
                           font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,
                                       "Apple SD Gothic Neo","Noto Sans KR",sans-serif; }
                    main { width:min(420px,88vw); background:#FFFDF7; border:1px solid #E3DED0;
                           padding:40px 28px; text-align:center; }
                    h1 { font-size:20px; margin:0 0 10px; letter-spacing:-.02em; }
                    p  { font-size:14px; line-height:1.6; color:#6B665A; margin:0; }
                    .code { margin-top:18px; font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
                            font-size:12px; letter-spacing:.12em; color:#A29B88; }
                    a.cta { display:block; margin-top:26px; padding:14px; background:#2B2A26;
                            color:#F5F2EA; text-decoration:none; font-size:14px; font-weight:600; }
                    .brand { margin-top:22px; font-size:11px; letter-spacing:.2em; color:#A29B88; }
                  </style>
                </head>
                <body>
                  <main>
                    <h1>%s</h1>
                    <p>%s</p>
                    %s
                    <a class="cta" href="%s">비트펫 앱 설치하기</a>
                    <p class="brand">BIT-PET</p>
                  </main>
                </body>
                </html>
                """.formatted(headline, headline, subline, codeBlock, store);
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
