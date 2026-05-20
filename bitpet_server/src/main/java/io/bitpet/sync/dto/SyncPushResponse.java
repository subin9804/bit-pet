package io.bitpet.sync.dto;

import java.util.List;

public record SyncPushResponse(List<PushResult> results) {}
