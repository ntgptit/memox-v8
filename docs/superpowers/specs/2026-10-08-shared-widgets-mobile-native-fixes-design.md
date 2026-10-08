# Shared widgets mobile-native fixes (audit 2026-10-08, F-01…F-06) — design

Status: owner rulings 2026-10-08 (chat), spec awaiting review ·
Path: architectural (two new shared widgets, one shared API removed, a theme token removed,
three screens, `DESIGN.md`) ·
Linear: epic DEV-301; sub-issues DEV-302 … DEV-307 · one PR on the session branch.

## 1. Intent

**The problem.** The mobile-native audit of 2026-10-08 scored 50 of the 53 shared widgets at
85/100 or more and found no P0 or P1. Six P2 findings remain, and three widgets sit under the
gate (`MxBottomNav` 82, `MxBreadcrumb` 80, `MxEmptyState` 84). All six are residue of the
web kit the UI base was built from, or of a row vocabulary with one bar missing:

- **F-01.** `MxBottomNav` blurs a backdrop that holds nothing: the bar is a sibling of the
  body (`body.bottom == nav.top`, measured), so `BackdropFilter` costs a `saveLayer` per
  frame and shows nothing.
- **F-02.** `MxEmptyState.footnote` draws a boxed `MxNote` inside the raised card: two ghost
  edges in dark.
- **F-03.** No shared "multi-line, selectable card row": deck, card and Trash rows each
  rebuild card + ink + checkbox + ⋮ + a one-node semantics by hand, with different padding
  and lead columns.
- **F-04.** Dividers have two owners (`MxListRow` and `MxOptionRow` draw their own;
  `MxSection` draws between its children), so every caller must remember `hasDivider`.
- **F-05.** Horizontal scroll regions cut their content flat: `MxBreadcrumb` hides ancestors
  with no cue; the chip rows of Card list and Monitoring cut a chip at the edge. Study has a
  local fade (`StudyScrollFadeWidget`) the system lacks.
- **F-06.** Card list enters selection by long-press only; Trash offers "Select".

**Success means:** the six sub-issues are Done; `MxBottomNav`, `MxBreadcrumb` and
`MxEmptyState` carry no open P2; every changed golden is regenerated in the Linux container
and reviewed on a golden-compare page; `DESIGN.md` records the glass removal and the note
rule; the gate passes.

## 2. Owner rulings (2026-10-08)

- **R1 · DEV-302.** Option (a): remove the blur, keep the bar where it is. `extendBody` is
  not adopted.
- **R2 · DEV-304.** A new widget `MxSelectableCardRow`, not new slots on `MxCard`.
- **R3 · DEV-306.** `StudyScrollFadeWidget` is promoted to a shared `MxScrollFade` with an
  axis; the study copy goes.
- **R4 · Delivery.** One PR on the session branch, implemented inline, each sub-issue in its
  own commits naming its `DEV-n`; the final whole-branch review runs on Opus.
- **R5 · Design.** The six sections below, approved as presented in chat.

## 3. Design

### 3.1 `MxBottomNav` without glass (DEV-302)

`lib/shared/widgets/mx_bottom_nav.dart` drops `BackdropFilter` and keeps `ClipRRect` (the
ripple stays inside the rounded bar) around a `DecoratedBox` filled with `colors.surface` and
edged with the ghost border, inside the same 8 / 4 / 8 / 12 + inset padding. Removed with it:
`MxDerivedColors.chromeGlass`, `AppEffects.glassBlur`, `AppEffects.glassOpacity` and their
tests (`mx_derived_colors_test.dart`, `foundations_test.dart`). `AppEffects` keeps
`scrimOpacity`.

Tests: `mx_bottom_nav_test.dart` expects no `BackdropFilter` and a `surface` fill;
`mx_app_shell_test.dart` gains a test that pins the decision: with a `bottomBar`, the body's
bottom edge equals the bar's top edge.

Documents: `DESIGN.md` › Elevation & Depth drops "The bottom bar is translucent glass (surface
at 84% with an 18 blur)" and says the bar is the page surface with the ghost edge; spec UI base
§4.4 and §9 note the removal (a new register row names this spec).

### 3.2 `MxEmptyState` footnote as a hint (DEV-303)

`lib/shared/widgets/mx_empty_state.dart` builds the footnote with `MxNote.hint`; the 20 gap
above it stays. `mx_empty_state_test.dart` asserts the footnote's `MxNote.isHint`.
`DESIGN.md` › Containers, `MxNote`: a footnote under a card, a section or an empty state is
always the `hint` form; the boxed form is for a note standing on its own in the flow.

### 3.3 `MxSelectableCardRow` (DEV-304)

New file `lib/shared/widgets/mx_selectable_card_row.dart`. One semantic purpose: a card
that is one item of a list the person can open, long-press into selection and tick.

```dart
class MxSelectableCardRow extends StatelessWidget {
  const MxSelectableCardRow({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelecting = false,
    this.isSelected = false,
    this.isEnabled = true,
    this.trailing,
    this.semanticLabel,
  });
}
```

- **Surface.** `MxCard(isFullBleed: true, isSelected: isSelected)`.
- **Target.** `MxRowInk(onTap, onLongPress)` covers the whole card except [trailing]; inside
  it `Padding(horizontal: gutter, vertical: grouped)` holds `Row(spacing: grouped)` of the
  `MxSelectionCheckbox(isChecked: isSelected)` while `isSelecting`, then `Expanded(child)`.
  The checkbox centres on the row (ruling D4).
- **Trailing.** An `MxIconButton` (⋮) or nothing. It sits outside the ink, 4 from the card's
  end edge, keeps its own node and its own tap, and centres on the card.
- **Semantics.** With [semanticLabel], one node (`container`, `excludeSemantics`) carries the
  label, `button` when not selecting, `checked` while selecting, `enabled`, the tap and the
  long-press, as the Trash row does today; [trailing] stays its own node. Without a label,
  `MergeSemantics` over the ink's content, with `checked` while selecting, as the card row
  does today.
- **Disabled.** `isEnabled: false` dims the whole card to `AppOpacity.disabled` and blocks
  its taps (a Trash entry of the other kind while selecting, BR-TRASH-011).
- **Not exposed.** Padding, colours, radius, the checkbox size, the gap between cards (the
  caller's 8).

Callers: `deck_row_widget.dart` (no selection; ⋮ as [trailing], so it leaves the ink; its
vertical padding goes from 16 to 12, ruling D1's value, a visible change on screen 01 for the
golden review), `card_row_widget.dart` (selection, no trailing, merged semantics),
`trash_entry_row_widget.dart` (selection, ⋮, one labelled node, locked kind). The other five
`MxCard + MxRowInk` callers (theme card, due strip, import source, add-details, bulk bar)
are not list items and stay.

Tests: `test/shared/widgets/mx_selectable_card_row_test.dart` (tap, long-press, checked state,
one node with a label, trailing fires on its own, 48 target, dim and blocked taps,
checkbox and ⋮ centred); goldens `mx_selectable_card_row_{light,dark}` in
`surface_widgets_golden_test.dart`; a gallery entry in `gallery_surfaces_section.dart`; the
three callers' tests updated.

### 3.4 Dividers owned by the container (DEV-305)

New file `lib/shared/widgets/mx_divided_column.dart`: `MxDividedColumn(children)`, a
`Column` (stretch, min) with the ghost hairline between consecutive children, the loop
`MxSection` draws today. `MxSection` uses it. `MxListRow` and `MxOptionRow` lose
`hasDivider` and draw no edge; every list that relied on the rows' own dividers wraps its
rows in `MxDividedColumn` (or `MxSection` where it already is one), and the
`index < length - 1` arithmetic goes. Lists that passed `hasDivider: false` on every row just
drop the argument. The gallery follows.

Tests: `mx_divided_column_test.dart` (n children, n − 1 hairlines, none for one child);
`mx_list_row_test` and `mx_option_row_test` lose their divider cases; `mx_section_test` keeps
its divider assertions through the new widget.

### 3.5 `MxScrollFade` (DEV-306)

New file `lib/shared/widgets/mx_scroll_fade.dart`, replacing
`lib/features/study/presentation/widgets/support/study_scroll_fade_widget.dart`:

```dart
enum MxScrollFadeGround { page, raised, recessed }

class MxScrollFade extends StatefulWidget {
  const MxScrollFade({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.ground = MxScrollFadeGround.page,
  });
}
```

- `ground` maps to `surface`, `surfaceContainerLowest`, `surfaceContainerLow`; no `Color`
  parameter (components.md).
- Vertical: a 24 fade over the trailing edge while `extentAfter > 0` (today's behaviour).
- Horizontal: a 24 fade over each edge that still has content, resolved through the
  metrics' `axisDirection`, so a reversed scroll view (`MxBreadcrumb`) fades the correct
  side. The fade ignores pointers and is excluded from semantics.
- Callers: `study_browse_widget.dart` (`raised`), `study_guess_widget.dart`,
  `study_match_widget.dart`, `study_face_card_widget.dart` (`raised` / `recessed`);
  `mx_breadcrumb.dart` (horizontal); `card_list_toolbar_widget.dart` and
  `monitoring_filter_bar_widget.dart` (horizontal). The study support test moves to
  `test/shared/widgets/mx_scroll_fade_test.dart`.
- `MxBreadcrumb` keeps one node per ancestor; a test asserts the first ancestor of a
  10-level path is still a reachable, labelled button while scrolled out of view.

Goldens: `mx_breadcrumb_*` (the deep path) and Monitoring's list change.

### 3.6 "Select cards" from the deck's ⋮ (DEV-307)

- `CardSelection` (`card_selection_state.dart`) becomes a state with `isSelecting` and
  `ids`: `start()` enters selection with no card, `toggle`, `selectAll`, `clear` leaves it.
  Its five consumers (`card_deck_app_bar_widget`, `card_add_fab_widget`,
  `card_deck_breadcrumb_widget`, `card_list_section_widget`, `card_list_toolbar_widget`)
  read `isSelecting` where they read "the set is not empty" today; "Select all" and the
  bulk bar read `ids` as before. Leaving selection with the Close control clears both.
- `DeckAction.selectCards` and an `MxActionSheetCommandRow` "Select cards" in
  `deck_action_sheet_widget.dart`, after Rename, shown only when the sheet is opened from the
  open deck of cards (`canSelect`, a card deck); `openDeckActions` takes `onSelectCards`;
  `DeckLevelScreen` takes `onSelectCards: ValueChanged<String>`, wired in
  `lib/app/router/app_router.dart` to `cardSelectionProvider(id).notifier.start()`.
- Copy: `deckActionSelectCards` "Select cards" / "Chọn thẻ".
- Documents: screen 07's app bar row and selection state name the sheet entry; screen 01's
  deck action sheet section lists it.

Tests: `card_selection_state` (start, toggle, clear), the deck action sheet shows the row only
from the open card deck, the Card list widget test enters selection from the sheet and shows
"0 selected" with the bulk bar.

## 4. Behaviour unchanged

Every other shared widget; the Trash app bar's "Select"; long-press on a card row (BR-CARD-020);
the study faces' content; the bottom bar's geometry, inset and labels; the nav rail.

## 5. Tests and gate

Each task is TDD: failing test, implementation, `run_tests.sh` on the touched files. Then
`run_goldens.sh --update` in the Linux container, a `golden-compare` page for the owner, one
`impeccable audit` of the changed goldens against `DESIGN.md`, `dod_check.sh`, the final
whole-branch review on Opus. The sub-issues go In Progress when their task starts and get a
comment with the PR when it opens.

## 6. Out of scope

The P3 notes of the audit (app bar hairline on scroll, one fill for every input, drag on
`MxToggle`, the all-zero workload line on Study home, the disabled-state mechanism,
`MxBadge` width), `extendBody`, text scale ≥ 1.5×, haptics.

## 7. Risks and rollback

- Screen 01's deck rows lose 4 dp of vertical padding and their ⋮ leaves the ink: a visible
  change, judged on the golden review page; rolling back is the deck row keeping its own
  layout on the shared frame.
- DEV-305 touches 36 callers mechanically; it is the last task and can be dropped from the PR
  (sub-issue to Backlog with the reason) without affecting the others.
- `CardSelection`'s new shape regenerates `card_selection_state.g.dart`; every consumer is
  in the card feature and covered by its widget tests.
