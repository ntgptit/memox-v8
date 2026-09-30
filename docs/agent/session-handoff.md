# Session handoff

A session handoff is a short file that carries the live thread of one piece of
unfinished work to a fresh agent. It is unrelated to the screen files under
`docs/shared/ui/screen-handoff/`. Write one when the owner asks for a handoff.

- **When:** only when the work moves to another harness (Claude ↔ Codex),
  another machine or cloud container, another person, or a side task forked to
  a second agent. When the work stays in the same harness and checkout, use
  `/compact`.
- **Where:** `.claude/handoff/<yyyy-mm-dd>-<topic>.md` on the working branch.
  Commit and push it, then give the next session the branch and the path; a
  new cloud session gets the branch as its `source_revision`. One file per
  piece of work: a later handoff replaces the earlier one.
- **What:** the state, the open decisions, the next step, and the skills the
  next agent should load (the Superpowers skill for the current phase, the
  `flutter-*` skills the task touches). Plans, specs, ADRs, PRs and commits
  appear as paths or URLs, never copied. Label every claim this session did
  not verify as an assumption, because the next agent takes the file as fact.
  Leave out secrets and personal data.
- **Lifetime:** delete the file when completing the branch, before the merge,
  so `master` never carries a handoff.
