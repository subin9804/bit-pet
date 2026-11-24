package io.bitpet.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 전체 푸시. {@code marketing} 이 true 면 마케팅 수신 동의자에게만, 제목에 (광고)·본문에 수신거부 안내가 붙는다.
 * 제목 90자는 (광고) 머리말이 붙어도 저장 칸(100)을 넘지 않게 잡은 것.
 */
public record BroadcastRequest(
        @NotBlank @Size(max = 90) String title,
        @NotBlank @Size(max = 400) String body,
        boolean marketing
) {}
