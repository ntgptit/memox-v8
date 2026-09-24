# ECC (plugin, project scope)

[ECC](https://github.com/affaan-m/ECC) (MIT) is enabled for this repo as the
Claude Code plugin `ecc@ecc`, declared in `.claude/settings.json`
(`extraKnownMarketplaces.ecc` + `enabledPlugins`). It is not vendored: Claude
Code fetches it from `affaan-m/ECC` (default branch) and namespaces it as
`ecc:<skill>`.

- Installed by `claude plugin marketplace add affaan-m/ECC --scope project`
  then `claude plugin install ecc@ecc --scope project` (version 2.2.2 at the
  time). Claude Code asks each developer to trust the marketplace on first use.
- It brings skills, agents, commands and plugin hooks (PreToolUse, PostToolUse,
  PreCompact, SessionStart, Stop, SessionEnd). `claude plugin details ecc@ecc`
  reports about 41k tokens of always-on context per session.
- Hook behaviour is set per developer with `/plugin configure ecc@ecc`
  (`hooks_enabled`, `hook_profile`: minimal | standard | strict) or with
  `ECC_HOOK_PROFILE` / `ECC_DISABLED_HOOKS`. Its `config-protection` hook
  blocks edits to linter and formatter configs such as `analysis_options.yaml`.
- Rules (`rules/`) are not part of the plugin and are not installed.
- Do not also run ECC's `install.sh` or `ecc-universal` into this repo: the
  skills and hooks would be installed twice.

Process ownership in `CLAUDE.md` still holds: Superpowers drives the
development process and Impeccable the design work. ECC skills that overlap
them (planning, TDD, verification, review, design system) are not the default.

To remove: delete both keys from `.claude/settings.json`, or run
`claude plugin uninstall ecc@ecc --scope project`.
