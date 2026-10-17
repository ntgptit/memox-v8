# Changing the look

How to change a colour, a size, a font or any other visual value. The app is drawn
with ForUI, and the values live in Dart under `lib/core/theme/`
([ADR-026](../shared/decisions/ADR-026-forui-la-he-component-giao-dien.md)). Everything
else is rendered from that theme or checked against it.

1. Change the value where it lives:
   - a colour: `lib/core/theme/app_palette.dart` (the two `FColors`) or
     `mx_status_colors.dart` (success, warning, info), in both modes;
   - a text role: `MxTextRoles` or the type scale in `app_typography.dart`;
   - a spacing or layout size: `app_dimens.dart`;
   - a radius, a border width, a shadow or a component's own style: ForUI's, set
     through `FThemeData` in `app_theme.dart`, or a style delta in the one `Mx*`
     widget that needs it.
   Never write a colour value anywhere else (`tools/design/check.py`), and never
   edit the `DESIGN.md` frontmatter or the token part of `.impeccable/design.json`
   by hand.
2. Run `MEMOX_WRITE_DESIGN_DOCS=1 flutter test test/tools/design_doc_test.dart`.
   It rewrites the `DESIGN.md` frontmatter and the token part of
   `.impeccable/design.json` from the production themes. Then run the test once
   more without the variable.
3. Run `test/core/theme/token_contrast_test.dart`: every text pair holds 4.5:1
   and every edge pair 3:1, in both modes. A failing pair is a palette change,
   never an exception.
4. A name that was renamed or removed goes into `tools/design/removed_symbols.json`
   with its replacement. `python3 tools/design/check.py` fails until every use is
   fixed. The compile errors after the removal are the work list. Do not declare
   the old name again in any form (alias, typedef, forwarding getter): the hook,
   the guard and the gate refuse it.
5. Run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update` in
   the Linux container and build the before · after · diff page with the
   `golden-compare` skill for the owner to review.
6. `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` is green.

No other file needs a hand edit to change a value. If one does, that file holds a
copy of a value that should be read from the theme: fix that instead of editing it.

## A ForUI upgrade

`forui` is pinned exactly in `pubspec.yaml`. An upgrade is a visual change: read
ForUI's changelog, run the gate, regenerate the design docs (step 2) and the
goldens (step 5), and give the owner the golden review page.

## Impeccable

Impeccable judges the UI against `DESIGN.md`, whose frontmatter is rendered from
the production theme. It does not change values: a finding that asks for a
different value, or that contradicts the theme, is not a bug to fix in code.
Record it and tell the owner.
