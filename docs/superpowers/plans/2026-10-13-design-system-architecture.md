# Design System + Theme Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the "Flashcard Color Tokens" Design System and move the theme to a standard Flutter Material 3 structure fed by one generated source, `design/tokens.json`, in one PR.

**Architecture:** `design/tokens.json` (+ `design/app_tokens.json`) is the only hand-owned token source. `tools/design/generate.py` writes `lib/core/theme/generated/*.g.dart`, the `DESIGN.md` frontmatter and the token part of `.impeccable/design.json`; `tools/design/check.py` and token tests compare against it. Old token classes are deleted first (compile errors are the work list), renamed 1:1 by a codemod driven by `tools/design/removed_symbols.json`, and a PreToolUse hook + guard rules + a `dod_check.sh` grep stop them from coming back.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13, Riverpod, Python ≥ 3.12 stdlib only (generator, check, codemod, hook), pytest/unittest, the repo's `code-verification-guard-v2`.

**Spec:** the owner's brief (this session's prompt), `design/tokens.json`, and `docs/shared/design/memox-design-tokens.md` (SPEC; only §2.3, 3, 5, 6, 9 apply).

## Global Constraints

- Token values come only from `design/tokens.json`; never edited, rounded, "nearest step", or kept for an old test/golden/skill. Nothing hand-written in test or code.
- No alias, typedef, re-export, forwarding getter, "compat/legacy" class, or redeclared old name, even temporarily.
- Gates are never skipped, weakened, or bypassed: no `skip`, `--no-verify`, lowered severity, `// ignore`, or wider golden tolerance. A gate that describes the old structure is updated to the new one.
- Branch `feat/design-system-architecture` from `master` (not reused from the cancelled token PR). Linear: work is a sub-issue of the nearest epic; branch/PR name its `DEV-n`; In Progress now, In Review at PR (CLAUDE.md "Progress on Linear").
- Extension target: `MxColorsExtension` 16 fields, `AppDimens` 42 fields + app-only, `ThemeContext` getters exactly `colors, texts, mxColors, dimens`; plus `accentColor`, `deckIconColor` (theme_rules.dart), `screenMargin`, `windowSize`.
- `brightness` branching to choose colour/size only in `theme_rules.dart` (and `app_theme.dart` builds light/dark by two separate calls).
- Text: widgets use `context.texts.<role>` and may only `copyWith(color:)` or `copyWith(fontFamily: AppTypography.monoFamily)`.
- Tint backgrounds only via `ColorTint.tintOver` (8-bit channel rounding, `opacity-dragged` constant from the generator).
- Single-line text rule: shorten the copy, never "…"; "Per session" is fixed by layout. Footer button pairs: `LayoutBuilder`, stack vertically when two do not fit.
- Hero card on Today: `context.accentColor.tintOver(colors.surface)`.
- Fonts: Be Vietnam Pro 400/500/600 + Noto Sans KR from `google/fonts` (OFL, `OFL.txt` kept). If they cannot be fetched: stop and report; no substitute font.
- Language: reply/report Vietnamese; code, commits, PR text in existing conventions (English). User code style: no `else`, early return, comments/docs in English and sparse.
- Commit trailers per session attribution; push only to `claude/optimistic-bardeen-9kzfbg`? **No:** the session designates `claude/optimistic-bardeen-9kzfbg`; the brief names `feat/design-system-architecture`. Work on the brief's branch name locally and push it **only after** the owner confirms which remote branch to use (see Open Items).

## Review Focus

1. A widget that read a removed token and now silently resolves to a *different role of the same value* (e.g. `warning` vs `warningContainer`, `onWarning` swap) — pinned by a codemod test on the `warning`/`onWarning` pair and a hand-reviewed list of every hit.
2. `AppSpacing.gutter` split (screen margin vs item gap) — every hit classified in a table; test that `context.screenMargin` is 16 below 600 and 24 from 600.
3. Light/dark parity of `accentColor`/`deckIconColor` and `tintOver` hex equality with SPEC §2 pre-computed values (`#E4E2F7`, `#28254F`, `#D6E7E2`, `#172A40`, `#EBE3D6`, `#312638`, `#F4DADA`, `#312441`).
4. Footer button pair overflow at 360dp and at large text — widget test with `LayoutBuilder` fallback to vertical.
5. Vietnamese stacked diacritics clipped at line height 1.43 (Ẳ, Ổ, Ỗ) once the golden font changes — recorded under "Việc tiếp theo", not fixed by raising `height`.
6. Generator determinism and rename detection: running twice is byte-identical; a renamed token appears in `removed_symbols.json` with empty replacement and `check.py` fails until filled.

---

## File Structure

**Create:** `design/tokens.json`, `design/app_tokens.json`, `design/contrast_exceptions.json`, `design/README.md`; `tools/design/{generate.py,check.py,codemod.py,removed_symbols.json,tests/}`; `lib/core/theme/generated/*.g.dart` (5); `lib/core/theme/{color_tint.dart,theme_rules.dart,app_icons.dart (moved)}`; `.claude/hooks/block_removed_theme_symbols.py` + test; guard rules + pytest; `docs/agent/visual-change.md`; ADR-022; `docs/shared/design/memox-design-tokens.md`; font assets.

**Modify:** `lib/core/theme/{app_theme,app_component_themes,app_typography,theme_context}.dart`, `mastery_ramp.dart`, all ~200 `lib/` consumers, `pubspec.yaml`, `test/flutter_test_config.dart`, `DESIGN.md`, `.impeccable/design.json`, `CLAUDE.md`, skills `flutter-design-system`, `flutter-theme-design`, `dod_check.sh`, CI `gate` job, `.claude/settings.json`, `check_design_tokens.py`.

**Delete:** `foundations/*` (except icons → moved), `mx_text_styles.dart`, `mx_semantic_colors.dart`, `mx_derived_colors.dart` (not named in the brief; its `*Soft`/`*Border` derivations are replaced by `tintOver`, and it is not in the allowed-file list — reported), `app_decorations.dart`, `app_button_style.dart`, `app_color_schemes.dart`, `PlusJakartaSans-Variable.ttf`, old theme tests.

**Allowed files in `lib/core/theme/`** (closed list enforced by guard): `app_theme.dart, app_component_themes.dart, app_surface_themes.dart, app_typography.dart, app_icons.dart, color_tint.dart, theme_rules.dart, theme_context.dart, mastery_ramp.dart, focus_ring_border.dart, generated/*.g.dart`.

---

### Task 1: Branch, SPEC, token source

**Files:** Create `design/tokens.json`, `design/README.md`, `docs/shared/design/memox-design-tokens.md`; Modify none.

- [ ] Confirm master still old: `grep -rn "fromSeed\|PlusJakartaSans" lib` (verified at plan time: `app_color_schemes.dart:19,60`, `app_typography.dart:9`; no part of the token PR present).
- [ ] Find/create the Linear sub-issue (WBS `FE`) via the connector; set In Progress.
- [ ] `cp` the attached `tokens.json` to `design/tokens.json` unchanged; `sha256sum` it against the upload and record the hash in the PR.
- [ ] Copy SPEC to `docs/shared/design/memox-design-tokens.md` with first line: `> Chỉ dùng mục 2.3, 3, 5, 6, 9; giá trị chuẩn nằm ở design/tokens.json`.
- [ ] Write `design/README.md` (exported from the Design System; to change the look, replace the file and run the generator; never hand-edit generated files).
- [ ] Commit.

### Task 2: Barrier first (brief §0)

**Files:** Create `tools/design/removed_symbols.json`, `.claude/hooks/block_removed_theme_symbols.py`, `.claude/hooks/tests/test_block_removed_theme_symbols.py`; Modify `.claude/settings.json`, guard rules, `dod_check.sh`, `.claude/hooks/README.md`.

**Interfaces — Produces:** `removed_symbols.json` = `{"symbols": {old: replacement}, "files": [paths]}`; hook exit 2 + message `'<name>' đã bị xoá. Sửa chỗ dùng thành: <replacement>`.

- [ ] Build `removed_symbols.json` from every mapping table (B, C, C2, D, V.5): `MxSemanticColors, semanticColors, derivedColors, MxDerivedColors, MxTextStyles, textStyles, AppSpacing, AppRadius, AppSize, AppIconSize, AppStroke, AppOpacity, AppDurations, AppEasing, AppEffects, AppShadows, AppDecorations, appButtonStyle, AppColorSchemes, primaryText, primarySoft, successSoft, learningSoft, warningSoft, dangerSoft, 0xFF4255FF, PlusJakartaSans, fromSeed`, and only dotted forms for short names (`semanticColors.warning`, `.onWarning`, `.border`, `.success`, …). `files`: the deleted paths.
- [ ] Write failing hook tests (stdlib `unittest`, like siblings): blocks `.dart` under `lib/`/`test/` whose new content has a removed name; allows the same text in `.json/.md`; blocks any write to a `files` path; blocks edits under `lib/core/theme/generated/` with "sửa design/tokens.json rồi chạy tools/design/generate.py"; passes clean content.
- [ ] Implement the hook (read `tools/design/removed_symbols.json`; inspect `tool_input.content` / `new_string`); register in `.claude/settings.json` PreToolUse `Edit|Write` next to `block_released_migrations.py` (if that script is absent in this checkout, register alone and report).
- [ ] Guard closed-list rule (new rules in `memox-design-token-rules.yaml`, pytest in `tests/test_memox_v8_design_system_guard_rules.py`): extension fields vs `tokens.json`/`app_tokens.json`, `ThemeContext` getter list, forbidden `typedef|@Deprecated|export … show|=> other;` in `lib/core/theme/` (except `theme_rules.dart`), allowed-file list, `files` paths must not exist, `brightness ==`/`isDark` colour/size branching outside `theme_rules.dart`. Bump `VERSION` per `AGENTS.md`.
- [ ] `dod_check.sh`: add step `removed_symbols` running `python3 tools/design/check.py --symbols` (greps `lib/` + `test/`); add step `design_tokens` running `check.py`.
- [ ] Commit.

### Task 3: Generator and check (brief G1)

**Files:** Create `tools/design/generate.py`, `tools/design/check.py`, `design/app_tokens.json`, `design/contrast_exceptions.json`, `tools/design/tests/test_generate.py`, `lib/core/theme/generated/*.g.dart`.

**Interfaces — Produces:** `ColorSchemes.light/dark` (`const ColorScheme`, 46 roles); `MxColorsExtension` (16 fields, `copyWith`, `lerp`, `static const light/dark`); `AppDimens` (42 + app-only fields, `copyWith() => this`, `lerp => this`, const default ctor); `buildTextTheme(...)`/`AppTypeScale` 12 roles + `fontFamily`, `fontFamilyFallback`; `kOpacityDragged`.

- [ ] Tests first (unittest): output stable across two runs; 46 roles for each brightness; 16 extension fields; 42 dimens in the brief's order; `height == lineHeight/fontSize`; header line present; rename detection appends to `removed_symbols.json` with empty replacement.
- [ ] Implement `generate.py` (dart format applied via `dart format` if on PATH, else deterministic own formatting that `dart format` leaves unchanged — verify with `dart format --set-exit-if-changed`). Name sets: M3 roles by name; `{success,warning,info}-{color,onColor,container,onContainer}` → `{name},on{Name},{name}Container,on{Name}Container`; `cardSurface, searchSurface, tileSurface, divider`; seeds ignored. Token `inverseOnSurface` → `onInverseSurface` if present.
- [ ] `app_tokens.json`: `{name,value,usage}` for values used by several widgets (decided in Task 6 while migrating; start with the Task-6-identified set).
- [ ] `check.py`: regenerate to temp dir, diff against committed generated Dart, `DESIGN.md` frontmatter, `.impeccable/design.json` token part; fail if `DESIGN.md` prose matches `#[0-9A-Fa-f]{6}` or a number+token unit; fail on `removed_symbols.json` entries with empty replacement; `--symbols` mode greps `lib/ test/`.
- [ ] Capture the old→new token table (G1.4) *before* old classes are deleted, into the scratchpad for the final report.
- [ ] Commit.

### Task 4: Fonts (brief V.1)

- [ ] Download from `raw.githubusercontent.com/google/fonts/main/ofl/{bevietnampro,notosanskr}` (reachable; `github.com/.../raw` and jsdelivr are denied by the proxy). If any file fails: stop, report, no substitute.
- [ ] Place TTFs + `OFL.txt` in `assets/fonts/`; declare weights in `pubspec.yaml`; delete `PlusJakartaSans-Variable.ttf`; update `test/flutter_test_config.dart`.
- [ ] Commit.

### Task 5: Delete old classes, write the new theme core

**Files:** Create `color_tint.dart`, `theme_rules.dart`, new `theme_context.dart`/`app_theme.dart`/`app_component_themes.dart`/`app_typography.dart`; move `foundations/app_icons.dart` → `app_icons.dart`; Delete listed classes.

- [ ] Failing tests first: `color_tint_test.dart` (hex equality with SPEC §2 pre-computed list above), `theme_rules_test.dart` (2 getters × 2 modes), `theme_context_test.dart`.
- [ ] `ColorTint.tintOver`: per 8-bit channel `round(fg*0.16 + bg*0.84)`, alpha 255, factor from `kOpacityDragged`.
- [ ] `theme_rules.dart`: `accentColor` (`primary` / `primaryFixedDim`), `deckIconColor` (`mxColors.info` / `infoContainer`), each with a doc comment quoting the DS rule; plus `screenMargin`, `windowSize` (from `dimens.breakpoint*`).
- [ ] `app_theme.dart`: `buildLightTheme()`/`buildDarkTheme()` as two calls with their own scheme/extension; component themes (card, searchBar, divider, filled/outlined/text/icon button, navigationBar/Rail, progress, chip, inputDecoration, dialog, bottomSheet, snackBar, tooltip) referencing tokens only; `fieldHint/dialogShape/dialogBarrier/sheetShape` getters removed and their consumers read the component theme.
- [ ] Delete old classes/files; run `flutter analyze` — its error list is the work list for Task 6.
- [ ] Commit (analyze red here is expected; this commit is not pushed alone).

### Task 6: Migrate consumers by codemod, then by hand

**Files:** all `lib/` and `test/` consumers (≈ 200 files; 1,700 occurrences at plan time: AppSpacing 778/182 files, textStyles 175/124, AppRadius 64, AppSize 84, AppIconSize 62, AppStroke 63, AppOpacity 33, AppDurations 35, semantic colors 127, AppDecorations 24).

- [ ] Write `tools/design/codemod.py` (reads `removed_symbols.json`, applies unambiguous 1:1 maps for B/C/C2 tables, injects `final dimens = context.dimens;` where needed, drops now-invalid `const`); unit-test it on fixtures, including the `warning`/`onWarning` pair, which the codemod refuses and lists for hand edit.
- [ ] Sub-passes, each ending with `flutter analyze` on the touched directory and a commit: (a) `dimens` (spacing/radius/size/icon/stroke/opacity/duration); (b) text (`textStyles.x` → role per SPEC 3.3, own picks logged); (c) colours (table C) with hand pass for `warning`/`onWarning`, `*Soft`→`tintOver` with correct base; (d) `AppDecorations`/`appButtonStyle` → component themes or `Mx*` parameters (Card via `cardTheme`, Today hero = accent tint); (e) `gutter` classification (margin vs gap) as a logged table; (f) app-only values: private `static const` with doc, or `app_tokens.json`.
- [ ] Layout (brief V.2): `windowSize`, rail from 600, content max widths, study column, overview 2-column at ≥ 672 via `LayoutBuilder`, narrow card (<300) stacking, footer button pairs stack when they do not fit; shortened copy logged `old → new` with ARB key; "Per session" fixed by layout.
- [ ] Mono font: `AppTypography.monoFamily`.
- [ ] Final: `grep` per `removed_symbols.json` returns nothing.

### Task 7: Tests against the source (brief G2)

- [ ] Replace `foundations_test`, `app_color_schemes_test`, `mx_semantic_colors_test`, value parts of `app_typography_test`, 7 `mx_text_styles*_test`, `app_decorations*_test` with tests that read `design/tokens.json` + `app_tokens.json` at runtime; `token_contrast_test` computes pairs from the JSON with exceptions in `design/contrast_exceptions.json` (pair, measured ratio, reason).
- [ ] Widget tests read sizes from default `AppDimens`; no literals.
- [ ] Add tests for Review Focus items 2 and 4.

### Task 8: Gates, hooks, skills, docs (brief E, I)

- [ ] Guard: `no_text_restyle` allows only `copyWith(color:)` and `copyWith(fontFamily: AppTypography.monoFamily)`; old names in rules → new; bare-number rule accepts `context.dimens.*`; pytest updated.
- [ ] `check_design_tokens.py` + test: new names.
- [ ] CLAUDE.md: Impeccable lines (H.5), authority order `tokens.json > approved goldens > screen handoff`, knowledge-table rows, the no-redeclare rule.
- [ ] Skills `flutter-design-system`, `flutter-theme-design` (+ references): no hand values; new structure; line-height ≥ 1.5 note; Indigo spec D3/D4 and foundations V3 get "superseded by Flashcard Color Tokens + ADR-022".
- [ ] `docs/agent/visual-change.md` (the six-step flow), ADR-022, update ADR-019 pointer. CI `gate` job runs `check.py`.

### Task 9: DESIGN.md and Impeccable (brief H)

- [ ] Read `.claude/skills/impeccable/` for the frontmatter schema it requires; make `generate.py` emit it (colors, typography, rounded, spacing, components) and the token part of `.impeccable/design.json` (keep `narrative`).
- [ ] Rewrite DESIGN.md prose (Named Rules) with token names only, no hex/numbers.
- [ ] Vendored Impeccable files untouched. Any hook finding caused by stale DESIGN.md is fixed by regenerating, not by touching UI.

### Task 10: Final verification and report (brief F)

- [ ] `run_goldens.sh --update` (Linux container); build golden-compare page; rerun without `--update`: green.
- [ ] `generate.py` twice → clean `git status`; `check.py` green; full `dod_check.sh` (no `--fast`) green; `bash tools/supabase/run_auth_it.sh` not required (no auth/migration paths touched).
- [ ] F.6 hook proof: attempt writing `MxSemanticColors` to a Dart file, capture output, revert.
- [ ] Final whole-branch review (Opus, per hooks README) against the diff.
- [ ] Report in Vietnamese with every table the brief lists; Linear In Review + Done comment with Check degrade / Check similar.

## Open Items

1. **Push target.** The session pins pushes to `claude/optimistic-bardeen-9kzfbg`; the brief says `feat/design-system-architecture`. Plan: commit on the latter locally, push to the session branch unless the owner says otherwise.
2. `MxDerivedColors` is outside the brief's lists; plan deletes it (see File Structure).
3. `foundations/app_icons.dart` is not a token file; plan moves it to `lib/core/theme/app_icons.dart`.
4. Execution method is not yet chosen.
