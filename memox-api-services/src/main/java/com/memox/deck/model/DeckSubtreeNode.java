package com.memox.deck.model;

import java.util.UUID;
import lombok.Getter;
import lombok.Setter;

/** A live deck in a subtree and its distance below the subtree's top ({@code 0} for the top itself). */
@Getter
@Setter
public class DeckSubtreeNode {

    private UUID id;
    private int rel;
}
