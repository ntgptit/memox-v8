package com.memox.trash.service;

import com.memox.sync.service.WriteContext;
import java.util.UUID;

/** Trash operations reached by batch id. */
public interface TrashService {

    /** Undoes a deck or a card batch, by the batch's item type (BR-TRASH-008). */
    void undo(WriteContext context, UUID batchId);
}
