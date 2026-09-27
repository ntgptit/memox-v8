-- ADR-013 / server-sync spec §7. Ids are client-generated UUIDs (ADR-007); times are UTC (ADR-008).

CREATE TABLE user_sync_version (
    user_id uuid PRIMARY KEY,
    version bigint NOT NULL
);

CREATE TABLE sync_applied_op (
    user_id uuid NOT NULL,
    op_id uuid NOT NULL,
    server_version bigint NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, op_id)
);

CREATE TABLE deck (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL,
    name text NOT NULL,
    parent_id uuid NULL REFERENCES deck (id),
    root_id uuid NOT NULL,
    depth integer NOT NULL CHECK (depth BETWEEN 1 AND 10),
    content_type text NOT NULL CHECK (content_type IN ('unset', 'card', 'deck')),
    scheduler_type text NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
    scheduler_version integer NULL,
    scheduler_config text NULL,
    study_config text NULL,
    generation integer NULL,
    first_answered_at timestamptz NULL,
    source_template_id text NULL,
    source_template_version integer NULL,
    delete_batch_id uuid NULL,
    sibling_position integer NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    server_version bigint NOT NULL,
    last_device_id uuid NOT NULL,
    deleted_at timestamptz NULL,
    -- A root holds decks and owns the scheduler; a child has neither (schema.md: deck).
    CONSTRAINT deck_root_shape CHECK (
        (parent_id IS NULL AND content_type = 'deck' AND scheduler_type IS NOT NULL)
        OR (parent_id IS NOT NULL AND scheduler_type IS NULL))
);

CREATE INDEX idx_deck_user_version ON deck (user_id, server_version);
CREATE INDEX idx_deck_parent ON deck (parent_id);
