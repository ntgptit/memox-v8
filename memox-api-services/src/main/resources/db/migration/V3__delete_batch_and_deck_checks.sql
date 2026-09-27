-- App deck-sync spec §6. A trash batch; tombstoned_at is the sync tombstone, deleted_at the batch's own time.
CREATE TABLE delete_batch (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    item_type text NOT NULL CHECK (item_type IN ('card', 'deck')),
    root_item_id uuid NOT NULL,
    deleted_at timestamptz NOT NULL,
    server_version bigint NOT NULL,
    last_device_id uuid NOT NULL,
    tombstoned_at timestamptz NULL
);
CREATE UNIQUE INDEX uq_delete_batch_user_version ON delete_batch (user_id, server_version);

-- The app's deck CHECKs (deck.drift): a row the app would refuse must be refused here, or it jams every pull.
ALTER TABLE deck ADD CONSTRAINT deck_root_generation CHECK ((parent_id IS NULL) = (generation IS NOT NULL));
ALTER TABLE deck ADD CONSTRAINT deck_root_scheduler_version CHECK ((parent_id IS NULL) = (scheduler_version IS NOT NULL));
ALTER TABLE deck ADD CONSTRAINT deck_child_configs CHECK (parent_id IS NULL OR (scheduler_config IS NULL AND study_config IS NULL));
