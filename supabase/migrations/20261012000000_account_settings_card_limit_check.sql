-- DEV-214: the server keeps card_limit inside the bounds the app enforces
-- (BR-STUDY-003: 1..200), so no device can push a limit another device would
-- open a session with. A push outside them is VALIDATION_FAILED through the
-- check_violation handler of push_one, with the row the server holds as
-- `current` (server sync spec §4.4). Every released build already checks the
-- value before writing it, so no stored row violates the constraint.
alter table public.account_settings
  add constraint account_settings_card_limit_check check (card_limit between 1 and 200);
