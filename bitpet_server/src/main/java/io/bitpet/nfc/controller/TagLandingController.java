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
 * <p><b>모양은 앱 이름표 화면(NfcPetProfileView)을 따른다</b> (2026-11-23) — 연민트 밴드 위 히어로, 그 아래 흰 카드.
 * 웹과 앱이 따로 놀지 않게. 색 값은 앱 토큰에서 옮겨 왔다.
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

        // 이름 옆 성별 기호 — 앱 히어로 카드의 SexIcon 과 같은 색
        String sex = switch (pet.genderLabel() == null ? "" : pet.genderLabel()) {
            case "수컷" -> "<span class=\"sex male\" title=\"수컷\">♂</span>";
            case "암컷" -> "<span class=\"sex female\" title=\"암컷\">♀</span>";
            default -> "";
        };

        StringBuilder chips = new StringBuilder();
        for (String m : pet.morphNames()) {
            chips.append("<span class=\"chip\">").append(escape(m)).append("</span>");
        }

        String photo = pet.imageUrl() != null
                ? "<img class=\"avatar\" src=\"" + escape(pet.imageUrl()) + "\" alt=\"\">"
                : "<div class=\"avatar placeholder\"><img src=\"/brand/icon-512.png\" alt=\"\"></div>";

        // 사육자 · 마지막 기록 — 앱 이름표 화면의 '사육자' 줄과 같은 카드. 기록은 종류와 시점만이다
        StringBuilder rows = new StringBuilder();
        if (pet.ownerName() != null) {
            rows.append(row("사육자", escape(pet.ownerName())));
        }
        if (pet.lastRecordLabel() != null) {
            rows.append(row("마지막 기록",
                    escape(pet.lastRecordLabel()) + " · " + escape(relativeDay(pet.lastRecordAt()))));
        }

        // 부모 — 이름이 주인공이고 모프는 있을 때만 작게 뒤에 붙는다
        StringBuilder parents = new StringBuilder();
        for (var p : pet.parents()) {
            parents.append("<div class=\"row parent\"><span>").append(escape(p.roleLabel()))
                   .append("</span><b>").append(escape(p.name()));
            if (!p.morphNames().isEmpty()) {
                parents.append("<i>").append(escape(String.join(" · ", p.morphNames()))).append("</i>");
            }
            parents.append("</b></div>");
        }

        String body = """
                  <section class="band">
                    %s
                    <div class="hero">
                      %s
                      <div class="hero-text">
                        <h1><span class="name">%s</span>%s</h1>
                        %s
                        %s
                      </div>
                    </div>
                  </section>
                  <main>
                    %s
                    %s
                    <p class="note">사육 기록은 사육자만 볼 수 있어요.</p>
                    <p class="code">%s</p>
                  </main>
                """.formatted(
                topBar(),
                photo,
                name, sex,
                pet.speciesName() != null ? "<p class=\"species\">" + escape(pet.speciesName()) + "</p>" : "",
                chips.length() > 0 ? "<div class=\"chips\">" + chips + "</div>" : "",
                rows.length() > 0 ? "<div class=\"card\">" + rows + "</div>" : "",
                parents.length() > 0
                        ? "<p class=\"section\">부모</p><div class=\"card\">" + parents + "</div>"
                        : "",
                tagCd);

        return page(name + " 의 이름표", body);
    }

    private static String row(String label, String value) {
        return "<div class=\"row\"><span>" + label + "</span><b>" + value + "</b></div>";
    }

    /** 앱 AppBar 자리 — 왼쪽 워드마크, 가운데 '이름표' */
    private static String topBar() {
        return "<div class=\"topbar\"><img class=\"wordmark\" src=\"/brand/logo.svg\" alt=\"TAILOG\">"
                + "<span>이름표</span></div>";
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
                  <section class="band">
                    %s
                  </section>
                  <main>
                    <div class="card empty">
                      <div class="avatar placeholder"><img src="/brand/icon-512.png" alt=""></div>
                      <h1>%s</h1>
                      <p class="species">%s</p>
                    </div>
                    %s
                  </main>
                """.formatted(topBar(), headline, subline,
                tagCd.isEmpty() ? "" : "<p class=\"code\">" + tagCd + "</p>");
        return page(headline, body);
    }

    /**
     * 공통 틀. <b>앱 이름표 화면(NfcPetProfileView)과 같은 모양</b>으로 맞췄다 (2026-11-23 사용자 요청 —
     * 웹과 앱이 따로 노는 느낌). 색·글꼴·둥글기·그림자는 앱 토큰(AppColors / AppRadius / AppShadows)
     * 값을 그대로 옮긴 것이다 — 앱 쪽 토큰을 바꾸면 여기도 같이 볼 것.
     * 연민트 밴드 위 히어로(원형 사진 + 이름·성별 + 종 + 모프 칩) → 회색 캔버스 위 흰 카드.
     */
    private String page(String title, String body) {
        String store = escape(deeplinkProperties.playStoreUrl());
        return """
                <!doctype html>
                <html lang="ko">
                <head>
                  <meta charset="utf-8">
                  <meta name="viewport" content="width=device-width,initial-scale=1">
                  <meta name="robots" content="noindex">
                  <meta name="theme-color" content="#EDFBF4">
                  <link rel="icon" href="/brand/favicon.png">
                  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/static/pretendard.min.css">
                  <title>%s · 테일로그</title>
                  <style>
                    :root { color-scheme: light;
                            --brand50:#EDFBF4; --brand700:#0B7A4B;
                            --canvas:#F4F6F5; --line:#E6EBE7; --ink:#121A15; --ink2:#5B665F; --ink3:#909A94;
                            --male:#3E9BDE; --female:#D95F8B; }
                    * { box-sizing: border-box; }
                    html, body { margin:0; background:var(--canvas); }
                    body { color:var(--ink); min-height:100vh;
                           font-family:Pretendard,-apple-system,BlinkMacSystemFont,"Apple SD Gothic Neo",
                                       "Noto Sans KR","Segoe UI",Roboto,sans-serif;
                           -webkit-font-smoothing:antialiased; }
                    .band, main, footer { width:min(480px,100%%); margin:0 auto; }
                    /* 상단 민트 밴드 — 앱 brandTintSoft */
                    .band { background:var(--brand50); padding:0 24px 28px; }
                    @media (min-width:481px) { .band { border-radius:0 0 16px 16px; } }
                    .topbar { height:56px; display:flex; align-items:center; position:relative; }
                    .topbar .wordmark { height:18px; opacity:.55; }
                    .topbar span { position:absolute; left:50%%; transform:translateX(-50%%);
                                   font-size:17px; font-weight:700; }
                    .hero { display:flex; align-items:center; gap:24px; padding-top:8px; }
                    .avatar { flex:none; width:88px; height:88px; border-radius:50%%; object-fit:cover;
                              background:#fff; display:block; }
                    .avatar.placeholder { display:flex; align-items:center; justify-content:center; overflow:hidden; }
                    .avatar.placeholder img { width:100%%; height:100%%; object-fit:cover; }
                    .hero-text { min-width:0; }
                    h1 { margin:0; font-size:24px; font-weight:800; letter-spacing:-.4px; line-height:1.3;
                         display:flex; align-items:center; gap:8px; }
                    .name { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
                    .sex { font-size:18px; font-weight:700; }
                    .sex.male { color:var(--male); } .sex.female { color:var(--female); }
                    .species { margin:4px 0 0; font-size:14px; line-height:1.5; color:var(--ink2); }
                    .chips { margin-top:12px; display:flex; flex-wrap:wrap; gap:6px 8px; }
                    .chip { font-size:12px; font-weight:700; padding:5px 12px; border-radius:999px;
                            background:#fff; color:var(--ink2); }
                    main { padding:16px 24px 8px; }
                    /* 흰 카드 — 앱 AppDecor.cardRaised */
                    .card { background:#fff; border:1px solid var(--line); border-radius:16px;
                            box-shadow:0 1px 2px rgba(15,21,18,.05), 0 2px 10px rgba(15,21,18,.04);
                            margin-bottom:12px; }
                    .row { display:flex; align-items:baseline; gap:12px; padding:14px 16px; font-size:13px; }
                    .row + .row { border-top:1px solid var(--line); }
                    .row span { flex:none; min-width:64px; color:var(--ink2); }
                    .row b { min-width:0; font-size:15px; font-weight:600; color:var(--ink);
                             overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
                    .row.parent span { min-width:32px; }
                    .row.parent i { font-style:normal; font-size:12px; font-weight:400; color:var(--ink3);
                                    margin-left:8px; }
                    .section { margin:20px 4px 8px; font-size:12px; font-weight:700; color:var(--ink3); }
                    .card.empty { padding:32px 24px; text-align:center; }
                    .card.empty .avatar { margin:0 auto 16px; background:var(--brand50); }
                    .card.empty h1 { justify-content:center; font-size:20px; font-weight:700; }
                    .note { margin:16px 4px 0; font-size:13px; color:var(--ink3); }
                    .code { margin:24px 0 0; text-align:center; font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
                            font-size:11px; font-weight:700; letter-spacing:.14em; color:#B6C4BC; }
                    /* 설치 유도는 여기 한 줄뿐 — 버튼으로 키우지 말 것 */
                    footer { padding:12px 24px 32px; font-size:12px; color:var(--ink3); text-align:center; }
                    footer a { color:var(--brand700); font-weight:600; text-decoration:none; }
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
