# MemoX V8 — One primary for both themes, and a primary ink for text

Status: approved 2026-09-27 · Path: architectural

## 1. Intent

The owner finds the dark primary `#8B9AFF` too pastel ("nữ tính", lacking life). After
two rounds of rendered candidates, the owner chose the light theme's brand indigo
`#5265F5` (the `seed`) as the dark primary too.

An audit showed the cost. In dark, `#5265F5` passes as a **fill** with white ink
(4.63:1) and as a **border** on cards (3.67:1). It fails as **text or icon ink** on
every dark ground: 2.46–4.11:1 on grounds, 3.0–3.3:1 on primary tints. The light
theme already has a milder form of the same gap: `#5265F5` text sits at 4.2–4.4:1 on
the light surface and `surfaceContainerLow`.

The fix is a split. `primary` stays the brand fill in both themes. A new derived
**`primaryInk`** carries every place primary is text, an icon or a focus ring. It is
pulled toward `onSurface` until it reads at 4.5:1 on every ground, as the status inks
already are.

Success means:

- both themes use `#5265F5` for every primary fill, border and tint;
- every primary-coloured text, icon and focus ring reads at ≥ 4.5:1 on every ground
  of its theme, and on the primary tints it sits on;
- nothing that sits on a primary fill loses contrast (white on `#5265F5` is 4.63:1);
- the goldens are re-rendered and checked, and the deviations from the kit are
  recorded.

## 2. Evidence (2026-09-27)

Dark, primary as ink:

| Ground | Old `#8B9AFF` | New `#5265F5` |
|---|---|---|
| surface `#0A0E27` | 7.39 | 4.11 |
| card `surfaceContainerLowest` `#131A3A` | 6.60 | 3.67 |
| `surfaceContainerLow` `#1B2249` | 5.95 | 3.31 |
| `surfaceContainer` `#232B5A` | 5.22 | 2.90 |
| `surfaceContainerHigh` `#2C356E` | 4.43 | 2.46 |
| primary tints (badge 12 %, tag chip 10 %, nav pill 20 %, command tile 8 %) | 5.2–5.6 | 3.0–3.3 |

Dark, primary as fill: dark ink on the old primary was 6.76:1. White on the new primary
is 4.63:1, and dark ink on it would be 3.76:1, so `onPrimary` must become white.

`primaryInk` = `Color.lerp(primary, onSurface, t)`:

- **dark**, `t` = 0.45 → about `#94A0F7`, whose worst case over every dark ground and
  tint is 4.68:1;
- **light**, `t` = 0.15 → about `#4A5AD7`, whose worst case over every light ground
  and tint is ≥ 4.5:1.

The unit test computes both on the real `onSurface` values.

## 3. Decisions

| # | Decision | Owner |
|---|---|---|
| D1 | Dark `primary` is `AppColorSchemes.seed` (`#5265F5`); dark `onPrimary` is `#FFFFFF` | Owner, 2026-09-27 |
| D2 | A new derived colour, `MxDerivedColors.primaryInk`, is primary pulled toward `onSurface` (dark 0.45, light 0.15). It is the only primary for text, icons, spinner arcs off a fill, and focus rings, in both themes | Owner, 2026-09-27 |
| D3 | Fills, selected edges, radio and checkbox fills, toggles, schedule bars, dots, cursors and tints keep `primary` | Owner, 2026-09-27 |
| D4 | Unchanged: the light `inversePrimary` `#8B9AFF` (a snackbar action is text on the dark inverse surface), `statusReviewing` `#8B9AFF` (a status colour), and `primaryContainer` | Owner, 2026-09-27 |
| D5 | `MxBadge` solid is allowed only with the primary tone: `onPrimary` is the only ink guaranteed on its fill. This closes a latent white-on-mint or white-on-amber case | Owner, 2026-09-27 |

## 4. Call sites

**→ `primaryInk` (text, icon, focus ring, spinner off a fill):**

- **`mx_text_styles.dart`:** `navLabel` (selected), `disclosureLabel`,
  `rowTitleMatch`, `requiredMarker`, `removableTagLabel`. `MxTextStyles` holds only a
  `ColorScheme`, so `MxDerivedColors` exposes a static `primaryInkOf(ColorScheme)`.
  Both the `primaryInk` field and these styles call it, so there is one source.
- **`app_component_themes.dart`:** the outlined and text button inks; the focus
  colours and the focused field edge.
- **`mx_button.dart`:** the outline ink and `focusColor`.
- **Focus colours** in `mx_chip_trigger.dart`, `mx_filter_chip.dart`,
  `mx_stepper.dart` and `mx_toggle.dart`, and the focus border in `mx_row_ink.dart`.
- **`mx_action_sheet_command_row.dart`:** the non-destructive ink. The tile tint stays
  primary.
- **`mx_bottom_nav.dart`:** the selected icon and label. The pill tint stays primary.
- **`mx_badge.dart`:** the tinted primary-tone ink. The tint stays primary.
- **`mx_workload_breakdown_line.dart`:** the "today" term.
- **`mx_search_field.dart`:** the focused icon.
- **`mx_empty_state.dart`:** the primary tone's glyph ink. Any tint stays primary.
- **`mx_stat_tile.dart`:** the primary emphasis.
- **`mx_spinner.dart`:** the arc when not on a fill.
- **`mx_icon_tile.dart`:** the tinted tone's glyph when no seed is given. The tint
  stays primary.
- **`mx_study_top_bar.dart`:** the default accent, where it inks text or glyphs. Where
  it paints a fill, the fill stays primary.
- **Features:**
  - `card_add_details_widget.dart`: the glyph;
  - `card_removable_tag_chip_widget.dart`: the glyph. The tint stays primary.

**→ `primary`, unchanged:**

- **Fills and edges:** the elevated button fill, `MxButton` primary fill, `MxFab`,
  `MxFilterChip` selected fill, the `MxCard` selected edge, and the `MxOptionRow` radio
  ring.
- **Indicators:** `MxToggle` track, `MxSelectionCheckbox`, the `card_schedule` bars
  and the `study_entry_resume` dot.
- **Other:** `import_step_tracker` fills, the `StudyChoice` selected tone, cursor
  colours, the `MxIconTile` solid tone, and every derived tint (`surfaceHero`,
  `ghostBorder`, the bottom-nav pill, the badge and tag-chip tints).

A call site found during the work that the lists above do not name is classified by
the same rule: text, icon or focus → `primaryInk`; fill, edge, indicator or tint →
`primary`.

## 5. Testing

- **`app_color_schemes_test.dart`:**
  - dark `primary` = `0xFF5265F5`, dark `onPrimary` = `0xFFFFFFFF`;
  - light `inversePrimary` stays `0xFF8B9AFF`, dark `inversePrimary` stays the seed.
- **`mx_derived_colors_test.dart`:**
  - `primaryInk` reaches ≥ 4.5:1 against every `surface*` ground of its theme and
    against primary at 8–20 % over those grounds (computed, not pinned);
  - `primaryInk` light differs from primary;
  - the dark `ghostBorder` and `surfaceHero` expectations follow the new primary.
- **Widget tests:** one assertion per group above that the text or glyph uses
  `primaryInk`, and that a fill kept `primary`, for button, bottom nav, badge,
  command row, search field and text styles.
- **`MxBadge`:** a solid badge with a non-primary tone fails its assertion.
- **Goldens:** re-render in the Linux container. Nearly all 210 change: dark from the
  primary, light from the ink. Check a pixel-diff table for all of them, and check
  about 10 screens in both themes by eye.
- **Gate:** one full `dod_check.sh`.

## 6. Register rows (UI-base §9)

They are added after the current last row:

- dark `primary` `#5265F5` = light (kit `#8B9AFF`), and dark `onPrimary` white (kit
  `#11173A`); owner 2026-09-27;
- `primaryInk` added; primary text, icons and focus rings use it (the kit inks them in
  `primary`); owner 2026-09-27;
- dark `primary-soft`, `primary-border` and `surface-hero` follow the new primary (the
  kit mixes `#8B9AFF`); owner 2026-09-27.

The kit files (`design-handoff.json` and the files generated from it) are not edited
by hand.

## 7. Out of scope

- A new kit.
- `statusReviewing`'s colour.
- The secondary and tertiary roles.
