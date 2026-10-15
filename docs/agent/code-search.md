# Code search

Every agent searches this repository with ripgrep (`rg`). It respects
`.gitignore`, skips binaries and is fast on the whole tree, so a search stays
scoped and its output stays small. Apply the policy silently; a reply does not
explain it.

- **Tool:** `rg`, never `grep -r`/`-R`, `git grep` or PowerShell
  `Select-String`. Discover files with `rg --files` (`-g '<glob>'` to narrow),
  never `find`, `ls -R` or `Get-ChildItem -Recurse`.
- **Flags:** `rg -l` when only file names matter, `rg -n` for lines,
  `rg -F` for a literal string, `rg -P` only for PCRE2-only features,
  `rg --count` to size a result before printing it.
- **Scope:** narrow to the relevant directory and file type (`-t dart`,
  `-g 'lib/**'`); search an exact symbol or literal before a broad regex.
  Leave generated files (`*.g.dart`, `*.drift.dart`), build output,
  dependencies and binary assets out unless the task needs them.
  `--hidden`, `--no-ignore` or `-uuu` only when necessary. Never rerun an
  equivalent search without a reason.
- **Before changing code:** find the declaration, then every reference and
  usage, the related implementations and shared components, and the callers
  the change reaches; change only after that. Search again afterwards for
  leftover references, outdated patterns and similar implementations (the
  same searches feed check degrade and check similar in `CLAUDE.md`).
- **Dedicated tools:** the harness's Grep and Glob tools run ripgrep and
  satisfy this policy.
- **Vendored skills:** an ECC or Superpowers skill that shows `grep -r` or
  `find` is run as the `rg` equivalent; the vendored file stays unchanged.
- **Fallback:** if `rg` is missing, check and report it; use another tool only
  when technically necessary or clearly better suited. Never install a tool or
  change the environment without the owner's approval.
