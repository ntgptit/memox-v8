package com.memox.card.controller;

import com.memox.card.dto.request.CardContentRequest;
import com.memox.card.dto.request.CardFlagRequest;
import com.memox.card.dto.request.CardListQuery;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.dto.request.DeleteCardsRequest;
import com.memox.card.dto.request.MoveCardsRequest;
import com.memox.card.dto.response.CardResponse;
import com.memox.card.service.CardService;
import com.memox.common.PagingResponse;
import com.memox.common.security.CurrentUserProvider;
import com.memox.sync.service.IdempotencyService;
import com.memox.sync.service.WriteContext;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
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

/** Card routes (API-A2 spec §6); each calls the service method its sync command calls. */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class CardController {

    private final CardService cardService;
    private final IdempotencyService idempotencyService;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/decks/{deckId}/cards")
    @ResponseStatus(HttpStatus.CREATED)
    public CardResponse create(
            @PathVariable UUID deckId,
            @Valid @RequestBody CreateCardRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.createCard(context, deckId, request));
        return cardService.getCard(context.userId(), request.id());
    }

    @PatchMapping("/cards/{id}")
    public CardResponse updateContent(
            @PathVariable UUID id,
            @Valid @RequestBody CardContentRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.updateContent(context, id, request));
        return cardService.getCard(context.userId(), id);
    }

    @PutMapping("/cards/{id}/flag")
    public CardResponse updateFlag(
            @PathVariable UUID id,
            @Valid @RequestBody CardFlagRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.updateFlag(context, id, request));
        return cardService.getCard(context.userId(), id);
    }

    @PostMapping("/cards/move")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void move(
            @Valid @RequestBody MoveCardsRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.moveCards(context, request));
    }

    @PostMapping("/cards/delete")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(
            @Valid @RequestBody DeleteCardsRequest request,
            @RequestHeader(value = WriteContext.DEVICE_HEADER, required = false) UUID deviceId,
            @RequestHeader(value = WriteContext.IDEMPOTENCY_HEADER, required = false) UUID key) {
        WriteContext context = WriteContext.rest(currentUserProvider.currentUserId(), deviceId);
        idempotencyService.runOnce(context.userId(), key, () -> cardService.deleteCards(context, request));
    }

    @GetMapping("/decks/{deckId}/cards")
    public PagingResponse<CardResponse> list(@PathVariable UUID deckId, @Valid CardListQuery query) {
        return cardService.listCards(currentUserProvider.currentUserId(), deckId, query);
    }

    @GetMapping("/cards/{id}")
    public CardResponse get(@PathVariable UUID id) {
        return cardService.getCard(currentUserProvider.currentUserId(), id);
    }
}
