package com.memox.trash.service.impl;

import com.memox.card.service.CardService;
import com.memox.common.exception.BusinessException;
import com.memox.common.exception.ErrorCode;
import com.memox.deck.service.DeckService;
import com.memox.sync.service.WriteContext;
import com.memox.trash.mapper.DeleteBatchMapper;
import com.memox.trash.model.DeleteBatch;
import com.memox.trash.service.TrashService;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TrashServiceImpl implements TrashService {

    private static final String DECK = "deck";

    private final DeleteBatchMapper deleteBatchMapper;
    private final DeckService deckService;
    private final CardService cardService;

    @Override
    @Transactional
    public void undo(WriteContext context, UUID batchId) {
        DeleteBatch batch = deleteBatchMapper.findDeleteBatchById(batchId);
        if (batch == null || !batch.getUserId().equals(context.userId())) {
            throw new BusinessException(ErrorCode.BATCH_NOT_FOUND);
        }
        if (DECK.equals(batch.getItemType())) {
            deckService.undoDeckDeletion(context, batchId);
            return;
        }
        cardService.undoCardDeletion(context, batchId);
    }
}
