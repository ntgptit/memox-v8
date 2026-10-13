# Changing the look

How to change a colour, a size, a font or any other visual token. The look has
one source, `design/tokens.json`, exported from the Design System "Flashcard
Color Tokens". Everything else is generated from it or checked against it
([ADR-022](../shared/decisions/ADR-022-mot-nguon-token-va-theme-flutter.md)).

1. The owner changes the Design System and exports `tokens.json`.
2. Replace `design/tokens.json` with the export. Never edit it by hand, and never
   edit anything under `lib/core/theme/generated/` or the `DESIGN.md`
   frontmatter.
3. Run `python3 tools/design/generate.py`. It rewrites
   `lib/core/theme/generated/*.g.dart`, the `DESIGN.md` frontmatter and the token
   part of `.impeccable/design.json`.
4. A token that was renamed or removed: the generator compares the old names with
   the new ones and appends each lost name to `tools/design/removed_symbols.json`
   with an empty replacement. `python3 tools/design/check.py` fails until each
   replacement is filled in and every use is fixed. The compile errors after the
   removal are the work list; run `python3 tools/design/codemod.py` for the
   mechanical renames and fix the rest by hand. Do not declare the old name again
   in any form (alias, typedef, forwarding getter): the hook, the guard and the
   gate refuse it.
5. Run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update` in
   the Linux container and build the before · after · diff page with the
   `golden-compare` skill for the owner to review.
6. `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` is green.

No other file needs a hand edit to change a token value. If one does, that file
holds a copy of a value that should be generated or read at run time: fix that
instead of editing it.

## Values the app has and the Design System does not

`design/app_tokens.json` lists them (name, value, usage). The generator adds
them to the end of `AppDimens`. A value only one widget uses is a private
constant with a doc comment in that widget. Both kinds are reported to the owner
so they can be added to the Design System; when they are, they leave the file.

## Impeccable

Impeccable judges the UI against `DESIGN.md`, whose frontmatter is generated from
`tokens.json`. It does not change tokens: a finding that asks for a different
token value, or that contradicts `tokens.json`, is not a bug to fix in code.
Record it and tell the owner.
