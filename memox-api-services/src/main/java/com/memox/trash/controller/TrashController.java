package com.memox.trash.controller;

import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
import com.memox.trash.service.TrashService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Trash routes: undo a batch (BR-TRASH-008). Restore and purge are API-B3. */
@RestController
@RequestMapping("/api/v1/trash")
@RequiredArgsConstructor
public class TrashController {

    private final TrashService trashService;
    private final IdempotencyService idempotencyService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/batches/{batchId}/undo")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void undo(
            @PathVariable UUID batchId,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> trashService.undo(context, batchId));
    }
}
