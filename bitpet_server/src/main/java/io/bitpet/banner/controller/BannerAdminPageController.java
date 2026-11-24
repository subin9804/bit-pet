package io.bitpet.banner.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/** 배너 관리 페이지 주소를 .html 없이 — 실제 파일은 static/admin/banners.html */
@Controller
public class BannerAdminPageController {

    @GetMapping("/admin/banners")
    public String page() {
        return "forward:/admin/banners.html";
    }
}
