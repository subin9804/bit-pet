package io.bitpet.nfc.controller;

import io.bitpet.common.config.DeeplinkProperties;
import io.bitpet.nfc.dto.TagLandingPet;
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
 * <p><b>노출 범위</b> — 이름·종·모프·성별·대표 사진까지. 이름표에 이미 적혀 있을 법한 것들이다.
 * 체중·급여 같은 사육 기록, 생일·입양일, 주인 정보는 절대 내려주지 않는다.
 *
 * <p><b>설치 유도는 아주 약하게.</b> 이 페이지의 주인공은 개체다. 설치 링크는 맨 아래 작은
 * 한 줄로만 둔다 — 광고처럼 보이는 순간 이름표의 신뢰가 깎인다.
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
        Optional<TagLandingPet> pet;
        try {
            pet = nfcTagService.peekPet(tagCd);
        } catch (Exception e) {
            pet = Optional.empty();
        }

        String code = escape(tagCd);
        return ResponseEntity.ok(pet
                .map(p -> petPage(p, code))
                .orElseGet(() -> emptyPage(
                        "연결되지 않은 이름표",
                        "아직 개체와 연결되지 않은 태그예요.<br>앱에서 스캔하면 개체를 연결할 수 있어요.",
                        code)));
    }

    /** 존재하지 않는 태그 코드 — 위조 차단. 404 지만 빈 화면 대신 안내를 보여준다. */
    @GetMapping(value = "/t", produces = MediaType.TEXT_HTML_VALUE + ";charset=UTF-8")
    public ResponseEntity<String> landingWithoutCode() {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .contentType(MediaType.valueOf(MediaType.TEXT_HTML_VALUE + ";charset=UTF-8"))
                .body(emptyPage("유효하지 않은 이름표", "태그 코드가 확인되지 않아요.", ""));
    }

    // -------------------------------------------------------------------------
    // HTML
    // -------------------------------------------------------------------------

    private String petPage(TagLandingPet pet, String tagCd) {
        String name = escape(pet.name());

        // 종 · 모프 · 성별 — 있는 것만 가운뎃점으로 잇는다
        StringBuilder meta = new StringBuilder();
        if (pet.speciesName() != null) meta.append(escape(pet.speciesName()));
        if (pet.genderLabel() != null) {
            if (meta.length() > 0) meta.append(" · ");
            meta.append(escape(pet.genderLabel()));
        }

        StringBuilder morphs = new StringBuilder();
        for (String m : pet.morphNames()) {
            morphs.append("<span class=\"chip\">").append(escape(m)).append("</span>");
        }

        String photo = pet.imageUrl() != null
                ? "<img class=\"photo\" src=\"" + escape(pet.imageUrl()) + "\" alt=\"\">"
                : "<div class=\"photo placeholder\"><img src=\"/brand/icon-512.png\" alt=\"\"></div>";

        // 주인 · 마지막 기록 — 개체 정보 아래 작은 두 줄. 기록은 종류와 시점만이다
        StringBuilder facts = new StringBuilder();
        if (pet.ownerName() != null) {
            facts.append("<div class=\"fact\"><span>주인</span><b>")
                 .append(escape(pet.ownerName())).append("</b></div>");
        }
        if (pet.lastRecordLabel() != null) {
            facts.append("<div class=\"fact\"><span>마지막 기록</span><b>")
                 .append(escape(pet.lastRecordLabel())).append(" · ")
                 .append(escape(relativeDay(pet.lastRecordAt()))).append("</b></div>");
        }

        String body = """
                  <header><img class="wordmark" src="/brand/logo.svg" alt="TAILOG"></header>
                  <main>
                    %s
                    <h1>%s</h1>
                    %s
                    %s
                    %s
                    <p class="code">%s</p>
                  </main>
                """.formatted(
                photo,
                name,
                meta.length() > 0 ? "<p class=\"meta\">" + meta + "</p>" : "",
                morphs.length() > 0 ? "<div class=\"chips\">" + morphs + "</div>" : "",
                facts.length() > 0 ? "<div class=\"facts\">" + facts + "</div>" : "",
                tagCd);

        return page(name + " 의 이름표", body);
    }

    /** "오늘 / 어제 / N일 전 / yyyy.MM.dd" — 30일이 넘으면 상대 표현이 오히려 안 읽힌다 */
    private static String relativeDay(java.time.Instant at) {
        if (at == null) return "";
        java.time.ZoneId seoul = java.time.ZoneId.of("Asia/Seoul");
        java.time.LocalDate day = at.atZone(seoul).toLocalDate();
        long days = java.time.temporal.ChronoUnit.DAYS.between(day, java.time.LocalDate.now(seoul));
        if (days <= 0)  return "오늘";
        if (days == 1)  return "어제";
        if (days <= 30) return days + "일 전";
        return day.format(java.time.format.DateTimeFormatter.ofPattern("yyyy.MM.dd"));
    }

    private String emptyPage(String headline, String subline, String tagCd) {
        String body = """
                  <header><img class="wordmark" src="/brand/logo.svg" alt="TAILOG"></header>
                  <main>
                    <div class="photo placeholder"><img src="/brand/icon-512.png" alt=""></div>
                    <h1>%s</h1>
                    <p class="meta">%s</p>
                    %s
                  </main>
                """.formatted(headline, subline,
                tagCd.isEmpty() ? "" : "<p class=\"code\">" + tagCd + "</p>");
        return page(headline, body);
    }

    private String page(String title, String body) {
        String store = escape(deeplinkProperties.playStoreUrl());
        return """
                <!doctype html>
                <html lang="ko">
                <head>
                  <meta charset="utf-8">
                  <meta name="viewport" content="width=device-width,initial-scale=1">
                  <meta name="robots" content="noindex">
                  <link rel="icon" href="/brand/favicon.png">
                  <title>%s · 테일로그</title>
                  <style>
                    :root { color-scheme: light; }
                    * { box-sizing: border-box; }
                    body { margin:0; min-height:100vh; display:flex; flex-direction:column;
                           align-items:center; justify-content:center; padding:32px 20px;
                           background:#F4FBF6; color:#2B2A26;
                           font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,
                                       "Apple SD Gothic Neo","Noto Sans KR",sans-serif; }
                    header { margin-bottom:18px; }
                    .wordmark { height:22px; opacity:.5; }
                    main { width:min(400px,100%%); background:#fff; border:1px solid #E4EFE8;
                           padding:32px 24px 26px; text-align:center; }
                    .photo { width:132px; height:132px; object-fit:cover; border-radius:50%%;
                             display:block; margin:0 auto 18px; background:#F4FBF6; }
                    .photo.placeholder { display:flex; align-items:center; justify-content:center; }
                    .photo.placeholder img { width:76px; height:76px; opacity:.85; }
                    h1 { font-size:24px; margin:0 0 6px; letter-spacing:-.02em; }
                    .meta { font-size:14px; line-height:1.6; color:#6B7A70; margin:0; }
                    .chips { margin-top:12px; display:flex; flex-wrap:wrap; gap:6px;
                             justify-content:center; }
                    .chip { font-size:12px; padding:5px 10px; background:#F0F8F3;
                            color:#3E7A5E; }
                    /* 주인 · 마지막 기록 — 기록의 '내용'은 여기 절대 넣지 말 것 (공개 URL 이다) */
                    .facts { margin-top:18px; padding-top:14px; border-top:1px solid #EFF5F1;
                             display:flex; flex-direction:column; gap:7px; }
                    .fact { display:flex; justify-content:space-between; font-size:13px; }
                    .fact span { color:#9AA8A0; }
                    .fact b { font-weight:600; color:#3E4B44; }
                    .code { margin-top:20px; font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
                            font-size:11px; letter-spacing:.14em; color:#B6C4BC; }
                    /* 설치 유도는 여기 한 줄뿐 — 버튼으로 키우지 말 것 */
                    footer { margin-top:16px; font-size:12px; color:#9AA8A0; text-align:center; }
                    footer a { color:#6B7A70; }
                  </style>
                </head>
                <body>
                %s
                  <footer>테일로그로 기록되는 개체예요 · <a href="%s">앱 보기</a></footer>
                </body>
                </html>
                """.formatted(title, body, store);
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
