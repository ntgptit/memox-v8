-- API-A2 spec §3. Card content only: tags are API-B2, the schedule API-B5. Lengths mirror BR-CARD-001..003;
-- the service enforces them in UTF-16 units after NFC, the CHECKs are the database's safety net.
CREATE TABLE card (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    deck_id uuid NOT NULL REFERENCES deck (id),
    front text NOT NULL CHECK (char_length(front) BETWEEN 1 AND 60),
    back text NOT NULL CHECK (char_length(back) BETWEEN 1 AND 240),
    example text NULL CHECK (example IS NULL OR char_length(example) BETWEEN 1 AND 240),
    hint text NULL CHECK (hint IS NULL OR char_length(hint) BETWEEN 1 AND 240),
    pronunciation text NULL CHECK (pronunciation IS NULL OR char_length(pronunciation) BETWEEN 1 AND 240),
    is_flagged boolean NOT NULL DEFAULT false,
    delete_batch_id uuid NULL REFERENCES delete_batch (id),
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    server_version bigint NOT NULL,
    last_device_id uuid NOT NULL,
    deleted_at timestamptz NULL
);
CREATE UNIQUE INDEX uq_card_user_version ON card (user_id, server_version);
CREATE INDEX idx_card_deck ON card (deck_id);
CREATE INDEX idx_card_delete_batch ON card (delete_batch_id);

-- Rows written by the retired row sync are not re-checked; every new write is (spec §3).
ALTER TABLE deck ADD CONSTRAINT fk_deck_delete_batch
    FOREIGN KEY (delete_batch_id) REFERENCES delete_batch (id) NOT VALID;
