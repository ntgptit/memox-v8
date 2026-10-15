# design/

`tokens.json` is exported from the Design System "Flashcard Color Tokens". It is
the only hand-owned source of token values.

- To change the look: replace `tokens.json`, then run `python3 tools/design/generate.py`.
- `app_tokens.json` holds values the app needs that the Design System does not define yet.
- Never edit `lib/core/theme/generated/` or the `DESIGN.md` frontmatter by hand.
- Full flow: `docs/agent/visual-change.md`.
