-- One version per changed row (sync spec §4.2): make a duplicate a loud error instead of a silently skipped change.
DROP INDEX idx_deck_user_version;
CREATE UNIQUE INDEX uq_deck_user_version ON deck (user_id, server_version);
