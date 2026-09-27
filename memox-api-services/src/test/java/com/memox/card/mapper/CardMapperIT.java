package com.memox.card.mapper;

import static org.assertj.core.api.Assertions.assertThat;

import com.memox.TestcontainersConfiguration;
import com.memox.card.model.Card;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.mapper.DeckMapper;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@Transactional
class CardMapperIT {

    @Autowired
    CardMapper cardMapper;

    @Autowired
    DeckMapper deckMapper;

    @Autowired
    DeckService deckService;

    @Test
    void aStoredCardMakesItsDeckDeriveCardAndReachesTheFeed() {
        WriteContext ctx = new WriteContext(UUID.randomUUID(), UUID.randomUUID());
        UUID root = UUID.randomUUID();
        UUID sub = UUID.randomUUID();
        deckService.createRootDeck(ctx, new CreateRootDeckRequest(root, "Root", "sm2"));
        deckService.createSubDeck(ctx, root, new CreateSubDeckRequest(sub, "Sub"));
        Instant now = Instant.parse("2026-09-27T01:00:00Z");
        UUID id = UUID.randomUUID();

        cardMapper.insertCard(Card.builder()
                .id(id)
                .userId(ctx.userId())
                .deckId(sub)
                .front("犬")
                .back("dog")
                .flagged(false)
                .createdAt(now)
                .updatedAt(now)
                .serverVersion(10_000L)
                .lastDeviceId(ctx.deviceId())
                .build());

        assertThat(cardMapper.findCardById(id).getBack()).isEqualTo("dog");
        assertThat(deckMapper.deriveContentType(sub)).isEqualTo("card");
        assertThat(cardMapper.findChangesSince(ctx.userId(), 9_999L, 10))
                .extracting(Card::getId)
                .containsExactly(id);
    }
}
