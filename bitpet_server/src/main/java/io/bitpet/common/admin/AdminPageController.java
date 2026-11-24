package io.bitpet.common.admin;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

/**
 * 웹 관리 페이지 주소를 .html 없이 — 실제 파일은 static/admin/{page}.html.
 *
 * <p>앱에 입구가 없고 링크로만 들어온다. 페이지는 공개 경로인 빈 껍데기이고
 * 로그인·어드민 판정은 그 안에서 부르는 /api/v1/admin/** 가 한다.
 */
@Controller
public class AdminPageController {

    /** 관리 홈 — 각 페이지로 들어가는 카드 */
    @GetMapping({"/admin", "/admin/"})
    public String home() {
        return "forward:/admin/index.html";
    }

    @GetMapping("/admin/{page:banners|reports|inquiries|push}")
    public String page(@PathVariable String page) {
        return "forward:/admin/" + page + ".html";
    }
}
