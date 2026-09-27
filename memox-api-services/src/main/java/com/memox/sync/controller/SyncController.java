package com.memox.sync.controller;

import com.memox.sync.dto.request.PushRequest;
import com.memox.sync.dto.response.ChangesResponse;
import com.memox.sync.dto.response.PushResponse;
import com.memox.sync.service.SyncService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Server-sync protocol (ADR-013, spec §4). */
@RestController
@RequestMapping("/api/v1/sync")
@RequiredArgsConstructor
public class SyncController {

    static final int MAX_CHANGES = 500;

    private final SyncService syncService;

    @PostMapping("/push")
    public PushResponse push(@Valid @RequestBody PushRequest request) {
        return syncService.push(request);
    }

    @GetMapping("/changes")
    public ChangesResponse changes(
            @RequestParam @Min(0) long since,
            @RequestParam(defaultValue = "" + MAX_CHANGES) @Min(1) @Max(MAX_CHANGES) int limit) {
        return syncService.changesSince(since, limit);
    }
}
