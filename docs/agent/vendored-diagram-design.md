# Vendored diagram-design skill

`.claude/skills/diagram-design/` is copied, unchanged, from
[cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design)
(MIT, plugin version 2.6.64) at commit
`d1376371965f513d99cc9ec388835d255c5c88d5`, with its `scripts/`. Six of its
slash commands are copied into `.claude/commands/`:

| Upstream `commands/` | Here |
|---|---|
| `export-diagram.md`, `import-drawio.md`, `import-excalidraw.md`, `import-mermaid.md` | same name |
| `doctor.md` | `diagram-doctor.md` (`/doctor` is a Claude Code built-in) |
| `profile.md` | `diagram-profile.md` |

- **Reference material, not process.** It draws standalone HTML/SVG/PNG
  diagrams on request. When it conflicts with `CLAUDE.md`, `CLAUDE.md` wins,
  as for the [ECC skills](vendored-ecc.md).
- **Its style guide is for diagrams only.** It never styles the app;
  `DESIGN.md` and Impeccable own the UI.
- **Diagrams inside repo docs stay Mermaid**, per `project-documentation`.
  A diagram-design file goes into the repo only when the owner asks for one.
- **Scripts.** `scripts/*.py` use the Python standard library only, open no
  network connection, start no process and write only to the path given with
  `--out`. Re-check that on every update.
- **Not vendored:** the plugin manifests, `prompts/` (Pi templates), the
  upstream repo's own `scripts/` and tests.
- **To update:** copy `skills/diagram-design/` and the six commands from a
  pinned upstream commit, review the diff (scripts above all), and update the
  commit above.
