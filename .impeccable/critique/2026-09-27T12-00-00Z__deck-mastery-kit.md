---
target: kit screen 01 deck rows (mastery bar), the open-deck summary card (donut, "Mastered · {algorithm}") and the sort sheet (Progress), pre-plan
total_score: 32
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "dir:docs/shared/ui/screen-handoff/img/01-deck-list"
timestamp: 2026-09-27T12-00-00Z
slug: deck-mastery-kit
---
Method: one pass. The kit captures of 01 (`rootLoaded`, `rootSortFilter` and `deckLoaded`, light and dark) and the kit source of module DeckList (v3 `1790244159-01e6`) were read against spec `docs/superpowers/specs/2026-09-27-deck-mastery-design.md` (R1–R3, D1–D12). They were checked against the shared pieces as they stand: `MxLinearProgress`, `MxMasteryDonut`, `MasteryRamp`, `DeckRowWidget` and `DeckSummaryCardWidget`. There is no build yet. Contrast was computed from `mx_semantic_colors.dart` and Foundations.

## Design Health Score: 32/40

| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of system status | 3 | A deck at 0.01 % paints a bar of well under 1 px: progress exists but cannot be seen (P2b) |
| 2 | Match system / real world | 4 | "Least mastered first" says what the order does; "Mastered · SM-2" names what the donut counts |
| 3 | User control and freedom | 4 | Progress is a view-only sort, reversible from the same sheet |
| 4 | Consistency and standards | 3 | The donut rounds 99.6 % to "100%" and 0.4 % to "0%"; the row's spoken percent must not copy that (P2a) |
| 5 | Error prevention | 4 | No write path here |
| 6 | Recognition vs recall | 3 | The row states mastery by bar length and colour only; the number is in semantics, not on screen (P1) |
| 7 | Flexibility and efficiency | 3 | Progress sort serves the "what needs work" scan |
| 8 | Aesthetic and minimalist | 4 | One 5 px bar per row, no new chrome |
| 9 | Error recovery | 2 | Unchanged: the level's error state covers the read |
| 10 | Help and documentation | 2 | Nothing explains "mastered" (box 8 / 128 days) on this screen; the card list's legend does |

## Design specificity
Mastery here is not a completion bar. The denominator counts new cards (R1), so a large deck that someone has only started reads low. That is honest: the bar answers "how much of this deck will stay with me", not "how far through it am I".

## Priority issues

- **[P1] The learning-band fill fails non-text contrast in light.**
  - *Problem:* below 34 % the fill is `statusLearning` #F59E0B. It measures **1.73:1** on the progress track #E2E7F3, under the 3:1 a meaningful graphic needs (WCAG 1.4.11). The other bands pass: reviewing 3.74, mastered 3.50, dark learning 7.32. Most decks in a real library sit in that band, and the row prints no number.
  - *Mitigation already in the spec:* the row's semantics say "{n}% mastered" (D9). The summary's donut prints the percentage.
  - *Options for the owner:*
    - **(a) Keep the kit's fill.** Record it in UI-base §9, extending row 4 (tracks under 3:1). This follows row 105's precedent: the fills keep the kit's hues and the inks darken. `MasteryRamp` stays one function for the donut and the bar.
    - **(b) Darken the learning band in light,** to `statusLearningInk` or a new ramp step. The donut changes colour too (screen 07's goldens), and the kit is left behind.
  - *Recommendation:* (a). The bar is a glanceable companion to a number that exists (semantics, summary donut, card list). The ramp's promise, "a 40 % deck is the same colour on every screen", is itself an accessibility property.
  - *Command:* `/impeccable audit`
- **[P2a] Percentages must not round to a lie.**
  - *Problem:* `NumberFormat.percentPattern` rounds half to even. 0.996 reads "100%" while cards are still unmastered, and 0.004 reads "0%" while one card is mastered.
  - *Fix:* one `MasteryRamp.percent(fraction)` helper. It gives 0 only at 0 mastered and 100 only at all mastered, and clamps between them to 1…99. The row's semantics and the donut both use it.
  - *Scope:* the donut change touches screen 07's summary only at those edges, and its goldens (20 %) do not move.
  - *Command:* `/impeccable harden`
- **[P2b] A sliver of progress is invisible.**
  - *Problem:* IELTS in the kit is 3.5 % of ~220 dp, which is 7.7 dp. One mastered card in 10,000 is 0.02 dp, and nothing shows.
  - *Fix:* when mastered > 0, the fill is at least as wide as the bar is tall (5 dp), so it reads as a dot. When mastered < cards, the fill stops at least 5 dp short of full, so a nearly done deck never reads as done. The semantics carry the exact figure.
  - *Command:* `/impeccable harden`
- **[P3] Smaller points the plan adopts.**
  - **Track colour:** the kit's row track is `--memox-surface-container`; Foundations name `progress-track` (= `surfaceContainerHigh`) for progress and mastery. Keep `progress-track`, as spec D8 says. On the white card it is the more visible of the two (1.25 against 1.18). Record the deviation in detail file 01.
  - **Bar extent:** the bar spans the text column only and stops before ⋮, as the kit's grid does (`48px 1fr 24px`). It is not full-bleed.
  - **Empty deck:** the track alone, and the semantics add nothing. The meta line "Empty · add cards or a sub-deck" already says it.
  - **Summary with sub-decks and no card:** the donut reads "0%". The line "N sub-decks · 0 cards" beside it gives the reason, and a hidden donut would make the card jump when the first card lands.
  - **Overline:** "MASTERED · SM-2" uses the same compact overline style as screen 07's "DECK PROGRESS · …", and its semantics read it unshouted (`semanticsLabel`).
  - **Sort sheet:** Progress is the fifth `MxOptionRow` with the sub-line "Least mastered first". The chip reads "Progress" when it is chosen, and "Progress · Due only" with the filter on, like the other sorts.
  - **Text scale 2:** the bar is a fixed 5 dp band under a meta line that already ellipsises, so the row grows only by its text.
  - **Motion:** the bar eases on change like `MxLinearProgress`, and instantly under Remove animations. A resort after an answer is not animated (the list rebuilds).

## Plan must adopt or rule on
1. P1: **the owner ruled (b) on 2026-09-27**, darkening the learning band in light.
   `MasteryRamp`'s learning band resolves to the existing `statusLearningInk`: 4.94:1 on
   the track in light, and in dark it equals `statusLearning`, so dark is unchanged. The
   donut on screens 01 and 07 follows. There is no new token. The deviation from the kit's
   amber is recorded in UI-base §9.
2. P2a and P2b: adopt. They add a percent helper and a minimum and maximum visible fill in the mastery variant.
3. The P3 points: adopt, and record the track deviation in detail file 01.
