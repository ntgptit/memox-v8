# Distribution and version identity

## Verified host conventions

Checked 2026-09-22 against [official Codex documentation](https://developers.openai.com/codex/skills/):
repository discovery scans `.agents/skills` from current directory through repo root;
the documented user-level location is `~/.agents/skills`. Same-name skills are not
merged and both can appear. No repo-over-global name precedence is promised there.
Codex supports symlinked skill folders, but mutable links do not pin team releases
and Windows checkout permissions vary. This mechanism uses verified copies.

Checked 2026-09-23 against [official Claude Code documentation](https://code.claude.com/docs/en/skills):
the user-level location is `~/.claude/skills`, replaced wholesale by
`CLAUDE_CODE_SKILLS_DIR`; project skills live in `.claude/skills` at each directory
level and load for that directory and below instead of walking up to repo root.
Claude Code does not read `.agents/skills`, so a Codex install is invisible there and
the same release needs its own `.claude` copy. Documented duplicate precedence is
enterprise, personal, project, bundled, then namespaced plugin. Skill identity is the
folder name, so managed copies MUST keep the `project-documentation` directory name.
Symlinked skill folders are undocumented there; verified copies avoid the question.

The installed skill-installer also supports `$CODEX_HOME/skills` (legacy
`~/.codex/skills`). Inspect these candidates too, but do not install another global
copy there by default. `--host agents|claude` selects which convention a mutation
writes, default `agents`; inspect always scans both hosts' user and repository
locations, so a stale copy under the other host surfaces as a conflict instead of
diverging silently. Inspect lists candidates, not which one the host chose;
`--active` must name the actually loaded path. Discovery refresh is host behavior.

## One authoring source

The existing repository-level generic skill directory doubles as canonical authoring
source. It contains no project context; global and other repo installs are managed
copies. Only edit canonical source. It can move to a dedicated skill repository
without content changes. Stable source_id, version and payload hashes are recorded
in `skill-manifest.json`; installed receipts retain canonical provenance. Commit/tag
plus manifest pins a release. No command fetches a remote or merges branches.

Canonical source → seal/version → install/sync/update → global/repository copies.
A verified global copy may transport the same release to another repo; its receipt
retains the original canonical source, rather than becoming a second author.

Use `python "SKILL_DIR/scripts/skill_distribution.py" --help`. Examples:

```text
... release --source CANONICAL --version 2.0.0
... install --source CANONICAL --scope global
... install --source CANONICAL --scope global --host claude
... install --source CANONICAL --scope repository --root TARGET_REPO
... install --source CANONICAL --scope repository --root TARGET_REPO --host claude
... sync --source CANONICAL --scope global
... update --source CANONICAL --scope repository --root TARGET_REPO --version 2.1.0
... verify --source CANONICAL --root TARGET_REPO --host claude
... inspect --root TARGET_REPO --active ACTUALLY_LOADED_SKILL
```

`--global-root` selects an explicit alternative user skill directory, overriding the
host default, useful for isolated tests. `verify` compares canonical against one
host's pair, so a two-host installation is verified once per `--host`. Mutations reject symlinks/junctions and overlapping source/target.
Install requires an absent target. Sync is idempotent for the same sealed release
and refuses drift/version differences. Update requires the source version explicitly,
an intact target with matching source_id and compatibility with any target pin.
Pins are adjusted separately and deliberately; updates never modify repo config.

Release runs only on canonical source, after tests/review, and refuses same-version
content changes or downgrades. Hashes normalize UTF-8 text CRLF to LF so checkout
conversion is not drift; binary bytes are exact. Added/deleted/modified payload files
are detected. Cache and installation receipt are excluded from payload; receipt
identity is checked separately. This is integrity checking, not a publisher signature.
Install/update stages and validates the new directory before swapping, retaining
old content on failure. No force overwrite or automatic reconciliation of edits.

MUST verify after distribution and in review/CI when keeping copies. Workflow entry
requires inspect. Different valid releases are still reported as mismatches. With
a pin, active bytes must match it. Without a pin, conflicting copies require explicit
path/authority review before writes. Never assume newest wins. A missing canonical
checkout permits pinned offline use but cannot prove upstream freshness.

Exit 0: mechanical integrity passed; 1: drift/missing expected copy/release or pin
mismatch; 2: invalid input or unsafe mutation. Inspect always exposes other candidates
and their conflicts even when the explicitly selected active copy satisfies its pin.
