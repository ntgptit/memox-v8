-- Deck name 32 spec 2026-10-21 §6 (BR-DECK-020): the server's ceiling on a
-- deck name, in code points of the stored form (the app sends it trimmed,
-- in NFC). The app allows at most 32 characters within the same ceiling,
-- so no row it writes is refused here (owner 2026-10-21, N2). A CHECK
-- failure comes back VALIDATION_FAILED from private.push_one, on every
-- path that writes a deck.
alter table public.deck
  add constraint deck_name_length check (char_length(name) <= 128);
