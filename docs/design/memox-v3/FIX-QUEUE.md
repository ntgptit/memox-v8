# Fix queue — MemoX V3 spec audit

Source: the `/impeccable audit` of these files (12/20, Acceptable). Run the queue with the loop in
`Loop rules` below. The objective gate is:

```bash
python tools/check_spec.py
```

It exits 0 only when every audit finding is fixed. Baseline before the loop: **2/17 checks pass**.

## Decisions taken so the loop never has to ask

The audit left product decisions open. Each has a default that keeps the incumbent design
("refinement preserves"). Change one here **before** starting the loop if you disagree.

| # | Decision | Default |
|---|---|---|
| D1 | AppBar content title | `16/700/-0.3px` (the component contract wins); fix the `20` in `02-theme-binding.md` |
| D2 | ListRow | Keep one line, fixed height, `14/600`. Fix foundations: drop "grows to two title lines", and stop mapping "list titles" to body large |
| D3 | BottomNav and Toggle | Keep the custom geometry. Record `DELIBERATE DEVIATION FROM MATERIAL` with the Material equivalent (NavigationBar 80, Switch 52×32). Add a `blur fallback`: an opaque surface when blur is unavailable or disabled |
| D4 | Adaptive scope | V8.0 is phone-first: the compact window size class (under 600dp) is the only designed class. From 600dp the same single column is centred at a max content width of 600. Navigation rail and expanded layouts are out of scope until a product decision |
| D5 | BottomNav active state | The pill sits behind the glyph only; the label sits on the glass bar. So the pill becomes solid `primaryContainer` and both glyph and label use `onPrimaryContainer` (amended in loop 4; the first wording assumed the label was on the pill) |
| D6 | Units | Layout is dp, text is sp, both written as the numbers already in the spec. Text follows the system font size; layouts must not clip at 1.3. The 12 floor is in sp |
| D7 | Icons | Material Symbols, Outlined, weight 400, chosen by meaning per Lucide name |
| D8 | MasteryDonut label | Raise to 12/700. Change the ring size only if the label cannot fit; record it |

## Queue

Run in order. Tick a box only when the gate checks named for it pass.

- [x] **1. `/impeccable adapt`**: add a `touch area MINIMUM 48` row to `SegmentedTray` (painted 32), `Stepper` (36) and `SelectionCheckbox` (20; the whole row is the target). Turn each Self-check `touch geometry` line to PASS. Gate: `touch`
- [x] **2. `/impeccable harden`**: add a required accessible name to `IconButton`, `StudyTopBar` close and `AppBar` actions; state or value semantics ("exposed as ...") for `Toggle`, `SelectionCheckbox`, `Stepper`, `MasteryDonut`. Gate: `a11y` (both)
- [x] **3. `/impeccable animate`**: one global reduced-motion rule (Android "Remove animations": crossfade or instant cut, state change preserved) in `01-foundations.md` and `02-theme-binding.md`, then a one-line reference in each of the 12 motion widgets that lack it, modelled on `skeleton.md`. Gate: `motion`
- [x] **4. `/impeccable colorize`**: BottomNav active label per D5; one track token (`progress-track`) for `StudyTopBar` and `MasteryDonut`; state the amber `< 34%` fill rule (fill against track 1.73:1, so a text value is required). Gate: `contrast`, `tokens`
- [ ] **5. `/impeccable typeset`**: D1 and D2 type sizes, D8 label size, D6 sp policy in foundations. Gate: `consistency` (both), `type` (both)
- [ ] **6. `/impeccable layout`**: D2 row height and line count across `list-row.md` and foundations, so both say the same thing. Gate: `consistency` (ListRow)
- [ ] **7. `/impeccable shape`**: D3, written into `bottom-nav.md` and `toggle.md`. Gate: `material`, `perf`
- [ ] **8. `/impeccable document`**: `docs/design/memox-v3/icon-mapping.md`, one row per Lucide name used in the widgets, format `` | `lucide-name` | MaterialSymbolName | ``. Gate: `icons`
- [ ] **9. `/impeccable adapt`** (second pass): D4 in `01-foundations.md`, using the phrase "window size class". Gate: `adaptive`
- [ ] **10. `/impeccable polish`**: final pass over every file touched. Re-run the gate; it must be 17/17.

## Loop rules

Each iteration:

1. Run `python tools/check_spec.py`.
2. Take the first unticked item in the queue. Run its command through the Impeccable skill and fix only what the item names.
3. Re-run the gate. Tick the item only if its checks now pass; otherwise fix and re-run once more, and if it still fails, write the reason under `## Blocked` and move on.
4. Append a short entry to `CHANGES.md` (what changed, which decision it applied).
Constraints:

- Edit only inside `docs/design/memox-v3/`. Never edit `tools/`, V7, or generated files. Never commit.
- Keep the template headings and the `  key     FIXED     value` row layout, because the gate reads them.
- Do not invent product claims. Every new rule must trace to an audit finding or a decision above.
- Run each queue command through the Impeccable skill (`impeccable:impeccable`, for example with the argument `adapt`). Do not re-run `impeccable context`; it already ran this session.
- Finish only when the gate prints `17/17 checks pass` and item 10 is ticked, then output exactly `<promise>SPEC_GATE_GREEN</promise>`. Never output it earlier, even if you are stuck: write the reason under `## Blocked` and stop instead.

## Blocked

_none yet_
