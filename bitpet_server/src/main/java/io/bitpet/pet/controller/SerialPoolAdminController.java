package io.bitpet.pet.controller;

import io.bitpet.pet.dto.SerialPoolStatResponse;
import io.bitpet.pet.service.SerialPoolService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Admin - Serial Pool")
@RestController
@RequestMapping("/api/v1/admin/serial-pool")
@RequiredArgsConstructor
public class SerialPoolAdminController {

    private final SerialPoolService serialPoolService;

    @GetMapping("/stats")
    public List<SerialPoolStatResponse> getStats() {
        return serialPoolService.listStats();
    }

    @PostMapping("/refresh")
    public SerialPoolStatResponse refresh() {
        return serialPoolService.forceRefresh();
    }
}
