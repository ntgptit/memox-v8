# design/

The design values no longer live here. Since ADR-026 the app is drawn with ForUI
and its values are Dart in `lib/core/theme/`:

- colours: `app_palette.dart` (the two ForUI `FColors`) and `mx_status_colors.dart`;
- type: `app_typography.dart`; spacing and layout sizes: `app_dimens.dart`;
- radii, border width and component styles: ForUI's, set in `app_theme.dart`.

`DESIGN.md`'s frontmatter and `.impeccable/design.json` are rendered from that
theme (`test/tools/design_doc_test.dart`). How to change the look:
`docs/agent/visual-change.md`. `tokens.json`, `app_tokens.json` and
`contrast_exceptions.json` were retired with the Material 3 theme
(`tools/design/removed_symbols.json` keeps them from coming back).
