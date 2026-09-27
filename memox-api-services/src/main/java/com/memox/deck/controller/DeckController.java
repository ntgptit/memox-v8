package com.memox.deck.controller;

import com.memox.common.PagingResponse;
import com.memox.common.security.CurrentUserProvider;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.DeckListQuery;
import com.memox.deck.dto.request.DeleteDeckRequest;
import com.memox.deck.dto.request.MoveDeckRequest;
import com.memox.deck.dto.request.RenameDeckRequest;
import com.memox.deck.dto.request.ReorderDeckRequest;
import com.memox.deck.dto.request.StudyOptionsRequest;
import com.memox.deck.dto.response.DeckResponse;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Deck routes (API-A2 spec §6); each calls the service method its sync command calls. */
@RestController
@RequestMapping("/api/v1/decks")
@RequiredArgsConstructor
public class DeckController {

    private final DeckService deckService;
    private final IdempotencyService idempotencyService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DeckResponse createRoot(
            @Valid @RequestBody CreateRootDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.createRootDeck(context, request));
        return deckService.getDeck(context.userId(), request.id());
    }

    @PostMapping("/{id}/sub-decks")
    @ResponseStatus(HttpStatus.CREATED)
    public DeckResponse createSub(
            @PathVariable UUID id,
            @Valid @RequestBody CreateSubDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.createSubDeck(context, id, request));
        return deckService.getDeck(context.userId(), request.id());
    }

    @PatchMapping("/{id}")
    public DeckResponse rename(
            @PathVariable UUID id,
            @Valid @RequestBody RenameDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.renameDeck(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @PostMapping("/{id}/move")
    public DeckResponse move(
            @PathVariable UUID id,
            @Valid @RequestBody MoveDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.moveDeck(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @PostMapping("/{id}/reorder")
    public DeckResponse reorder(
            @PathVariable UUID id,
            @Valid @RequestBody ReorderDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.reorderDeck(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @PutMapping("/{id}/study-options")
    public DeckResponse studyOptions(
            @PathVariable UUID id,
            @Valid @RequestBody StudyOptionsRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.updateStudyOptions(context, id, request));
        return deckService.getDeck(context.userId(), id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @PathVariable UUID id,
            @Valid @RequestBody DeleteDeckRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> deckService.deleteDeck(context, id, request));
    }

    @GetMapping
    public PagingResponse<DeckResponse> list(@Valid DeckListQuery query) {
        return deckService.listDecks(currentUserProvider.currentUserId(), query);
    }

    @GetMapping("/{id}")
    public DeckResponse get(@PathVariable UUID id) {
        return deckService.getDeck(currentUserProvider.currentUserId(), id);
    }
}
