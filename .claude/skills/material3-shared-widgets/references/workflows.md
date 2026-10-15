# Workflows: BUILD, AUDIT, FIX

Each workflow applies the 12 mandatory steps of `SKILL.md`. The step names are
the same; what each step means differs. Before step 1 of any workflow:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH
cat .fvmrc    # the SDK pin; the source path below uses it
```

Vocabulary:

- **Classes** (ledger): `ADOPT`, `ALREADY_COMPLIANT`, `CONFLICT` (with
  `KEEP_EXISTING`), `BLOCKED`, `NOT_APPLICABLE`, `SDK_CHECK`.
- **Compliance** (inventory): `PASS`, `FIXED`, `CONFLICT`, `BLOCKED`, `N/A`,
  `UNVERIFIED`, `FAIL`.
- **Evidence** is one of: an executed test (name the file and the command), a
  golden, or code read (say "read", never "run").

Forbidden in every workflow: editing `design/tokens.json`, adding a token
without an owner decision, re-declaring a name in
`tools/design/removed_symbols.json`, `--no-verify`, `// ignore`, a lowered
severity, a golden tolerance, a skipped or deleted test.

## BUILD

Use for a new or changed `Mx*` widget, a component theme, or a screen
composition.

1. **Read specs and decisions.**
   - The spec section for the component (`docs/shared/design/m3-shared-widget-spec-v2.6.1.md`, sections 3 to 7 and 12).
   - Its ledger rows: grep the component name in `docs/shared/design/m3-adoption-ledger.md` and read every `DSD` and `M3C` row that names it.
   - The screen's detail file if a screen is involved, and flutter-theme-design's reference for the component.
2. **Inspect code.** The theme slot in `lib/core/theme/`, the existing `Mx*` widget in `lib/shared/widgets/`, and their tests.
3. **Ownership and call sites.**
   - `rg -n "<Symbol>\(" lib` for every consumer.
   - Decide the owner: theme slot, `Mx*` widget, or the screen. Adding or promoting code into `lib/core/` or `lib/shared/` goes to the owner through `AskUserQuestion` (CLAUDE.md).
4. **Pinned SDK behaviour.**
   - Find the M3 defaults the widget inherits: `rg -n "class _\w+DefaultsM3" /root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/material/<file>.dart`.
   - Read the resolve order in the widget's `build`. Record `file:line` for each fact you rely on. Check `references/flutter-m3-pitfalls.md` for the component.
5. **Classify.** Each spec rule for the component is `ADOPT`, `CONFLICT`, `BLOCKED`, `NOT_APPLICABLE` or `SDK_CHECK`, read from the ledger. A rule with no ledger row gets one in step 6.
6. **Design the correction.** Name the theme field (not a widget parameter) that carries each value, the token that supplies it, and the variants the API exposes. `CONFLICT` and `BLOCKED` parts keep the existing value. A missing token is an owner question, never a silent addition.
7. **Regression tests first.** One test per state in the spec state matrix that applies (resting, hovered, focused, pressed, selected, disabled, error, loading). Rendered behaviour is proved by pumping the widget under the production theme; a theme-field assertion alone does not count. Run it and see it fail.
8. **The smallest shared-layer fix.** Theme slot in `lib/core/theme/`, widget in `lib/shared/widgets/`. Features get no escape hatch.
9. **Targeted verification.**
   - `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>` for each new or changed test.
   - `dart run tools/m3_lint/m3_lint.dart`.
10. **Check degrade and similar.** List every consumer from step 3 and prove each still behaves. Search the same mechanism (the SDK default left to fall through, the same parameter exposed) in the other `Mx*` widgets and slots, and class each hit.
11. **Broader gates.** `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` must print `mechanical gates passed`. If a golden changed: `run_goldens.sh --update` (Linux container only), the golden-compare page, then a green rerun without `--update`. See `references/gates.md`.
12. **Report evidence and blockers.** Add or update the ledger row. List every test with its command and result, every `UNVERIFIED` item, and every `BLOCKED` decision.

## AUDIT

Use to judge shared widgets, theme slots, tokens, anatomy, states,
accessibility or M3 conformance across the app. The output is inventory rows
and findings, written into ledger sections 3 to 5.

1. **Read specs and decisions.** The spec, the whole ledger (sections 1, 2, 6, 7), `references/flutter-m3-pitfalls.md`, `PRODUCT.md`, `DESIGN.md`.
2. **Inspect code.** Enumerate the components: `ls lib/shared/widgets`, the slots in `lib/core/theme/`, and the `ThemeData` assembly. One inventory row per component and variant (see Inventory row). Also list:
   - the `ThemeData` **ambient fields** the assembly does not set (`iconTheme`, `hoverColor`, `focusColor`, `visualDensity`, `materialTapTargetSize`, `disabledColor`, `shadowColor`, `canvasColor`, `splashFactory`): Material widgets read them without a slot (pitfall 15);
   - for every `Mx*` widget that replaces an SDK widget, what the SDK widget publishes and the replacement does not: route name, role and position, selected, tooltip, overlay style, state layers (pitfall 19);
   - for every state the app simulates outside its widget (an error drawn by hand), the decorator state it never sets (pitfall 17).
3. **Ownership and call sites.** For each component: theme owner and consumers (`rg -n "<Symbol>\(" lib`). A slot with no consumer is classed in the row, not dropped.
4. **Pinned SDK behaviour.** For each material widget a slot configures, read its defaults and resolve order in the pinned source (`rg -n "class _\w+DefaultsM3" /root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/material/<file>.dart`). Cite `file:line`. Never cite from memory.
5. **Classify.** For each cell of the spec's role map and state matrix, take the class from the ledger. The project value wins over the spec in `CONFLICT` rows; record the existing value as observed and mark `CONFLICT`, not `FAIL`. If the approved value differs and the ledger has no `M3C` row, the cell is a new conflict candidate, never a `FAIL`; add the row to ledger section 2 with both values and their sources (next free id), and to section 6 when an owner decision is needed. A candidate that cannot be proved is `UNVERIFIED` with the run that would settle it; it is not a finding.
6. **Design the correction.** Not walked: an audit does not design or make fixes. For each `FAIL` cell the finding names the fix owner layer (see Finding).
7. **Tests that expose findings.** Where a cell is `UNVERIFIED` and a test can prove it, write the test and run it. A failing test is the evidence for the finding. Do not turn a failing test green by weakening it.
   - **Probe.** An audit proves a rendered claim with a throwaway widget test under the production theme (recipes: pitfall 20), run on the tree and deleted before the commit; quote its output in the cell or finding. A claim copied from another auditor is `UNVERIFIED` until a probe or a read of the cited lines confirms it.
   - **A test that pins a wrong value** (a theme-field assertion of a role that fails a rendered check) is corrected by the FIX task, with the finding as the reason. That is not weakening: weakening removes or loosens a check that a correct value still has to pass.
8. **The smallest shared-layer fix.** Not walked: an audit does not fix. The FIX workflow does the change from the finding.
9. **Targeted verification.**
   - Run what you rely on: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>` and `dart run tools/m3_lint/m3_lint.dart`.
   - Every cell is `PASS` only with an executed test or a golden. Code you read is evidence marked "read"; a cell proved only by reading is `UNVERIFIED` unless the fact is static (a literal in a theme file).
   - A colour a widget derives (an alpha blend, an ink chosen by a boolean, a glyph that reads `primary`) is checked by computing its pair from `design/tokens.json` with the WCAG formula and by rendering it; `token_contrast_test.dart` checks token pairs only. Computed figures are marked "computed".
   - A test file that landed after the baseline counts as `test:` evidence only when it was run; an untracked or unrun file does not.
10. **Check degrade and similar.** For each finding search the same mechanism by symbol and by behaviour across `lib/`, class each hit (same root cause, similar but unaffected, suspect, unrelated), and merge findings that share one root cause into one.
11. **Broader gates.** Run the gates the inventory leans on (`references/gates.md`) and paste their output into the report. A gate not run is not claimed.
12. **Report evidence and blockers.** Fill ledger sections 3 (inventory), 4 (compliance matrix), 5 (findings by root cause). Report totals by compliance value and severity. A report with any material `UNVERIFIED` row is not `VERIFIED`.

## FIX

Use to correct a confirmed design-system violation or to fence its
regression. Start from a finding (or a failing test), not from a symptom on one
screen.

1. **Read specs and decisions.** The finding, its ledger rows (`M3C`, `DSD`), and the screen detail file if a screen shows it. If the ledger says `CONFLICT` or `BLOCKED`, stop: this is not a fix, it is an owner decision.
2. **Inspect code.** Reproduce. Read the code that produces the symptom and the code underneath it. Run `superpowers:systematic-debugging`; the reported widget is where the search starts, not where the fix belongs.
3. **Ownership and call sites.** `rg -n "<Symbol>\(" lib` for every consumer of the suspected owner. Look from the shared layers down: tokens and theme, shared widgets, shared state, then the screen.
4. **Pinned SDK behaviour.** Read the resolve order that produces the observed value in `/root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/` and record `file:line`. Check `references/flutter-m3-pitfalls.md` for a known trap.
5. **Classify.** Same root cause, different root cause, or a ledger class that forbids the change. State the root cause as a mechanism: where (`file:line`), why, which contract it breaks, why the change removes it, which symptoms it explains.
6. **Design the correction.** The lowest shared owner that removes the cause for every consumer. A local fix says why the shared layer is not the owner.
7. **Regression tests first.** A test that fails before the fix and passes after, for the rendered behaviour (pump under the production theme, read the effective value). Run it and see it fail for the stated reason.
8. **The smallest shared-layer fix.** Change only the owner. No local override, magic value or conditional that hides a shared defect.
9. **Targeted verification.** `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>` for the new test and every test of the touched files; `dart run tools/m3_lint/m3_lint.dart` when a lint rule applies.
10. **Check degrade and similar.** Degrade: list every consumer from step 3 and prove each. Similar: search the mechanism, not the symptom, and class every hit. A same-cause hit is fixed in the same PR; a different-cause hit becomes a sub-issue. Rerun both on the final diff.
11. **Broader gates.** `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`; goldens through `run_goldens.sh` and the golden-compare page when a picture changed (`references/gates.md`).
12. **Report evidence and blockers.** Update the ledger (the finding's status, the inventory row, the compliance cell). Final state: `VERIFIED`, `BLOCKED` or `UNRESOLVED`. Never report an unproven fix as fixed.

## Inventory row

One row per component and variant. Fields, in this order:

`Component | Source | Category | Variants | States | Theme owner | Consumers | Spec mapping | Compliance (PASS/FIXED/CONFLICT/BLOCKED/N/A/UNVERIFIED/FAIL) | Severity (Critical/Major/Minor) | Evidence | Action`

- **Source**: `lib/shared/widgets/<file>.dart`, or the SDK widget for a slot with no `Mx*` wrapper.
- **Spec mapping**: the spec section and the ledger `DSD` or `M3C` ids.
- **Severity** is empty for `PASS`, `FIXED`, `N/A`.
- **Evidence** names the test file and command, the golden, or "read" with `file:line`.
- **Action** is `none`, `FIX <finding id>`, `ask owner <ledger id>`, or `write test`.
- **Compliance of a mixed row** names each part's value (`FAIL (M3F-nn) · CONFLICT(M3C-nn) · PASS (rest)`); Severity is the highest of its findings. A theme slot with no consumer is `N/A (slot without consumer)`. A component with no spec row is `N/A (no spec row)`. A component whose state the app simulates, or that no test renders, is `UNVERIFIED` for that state, with the run that would settle it.

## Finding

ID `M3F-nn` (two digits, in order of discovery).

```
### M3F-nn  <one-line title>
- Component and variant:
- Spec reference:        <section, rule>
- Approved reference:    <ADR, token, ledger id; "none" if only the spec>
- Observed:              <file:line, or the executed test and its result>
- Expected:
- Class:                 <ADOPT | ALREADY_COMPLIANT | CONFLICT | BLOCKED | NOT_APPLICABLE | SDK_CHECK>
- Severity:              <Critical | Major | Minor>
- Root cause (mechanism): <where file:line, why, which contract it breaks>
- Fix owner layer:       <tokens | theme slot | Mx widget | feature | tooling>
- Consumers:             <file count, call count, first five>
- Similar sites:         <each hit with its class>
- Failing test first:    <the concrete assertion the FIX task writes first, and its value today>
```

A finding is raised for a rule that binds the project (`ADOPT`) and that a verified observation contradicts. A rule the ledger classes `CONFLICT` or `BLOCKED` is a conflict row, not a finding. Findings that share one mechanism are one group, ordered by the spec §6 priority (accessibility and interaction, bypasses, tokens and themes, states and variants, layout, hierarchy, optical).

## Severity

Adapted from spec 9.4, with `transparent` removed per M3C-11 and its three levels mapped to the project's names.

- **Critical** (the spec's "Blocked if any of"): a missing approved 45-role palette or scrim alpha when modal barriers are in scope; missing pinned SDK verification; a missing explicit `surfaceTint` declaration or assertion; an AppBar scrolled-under contract failure; missing Dialog, BottomSheet or Drawer theme scrim wiring, or a missing effective route or drawer scrim test; an adaptive or Cupertino modal bypass, or an overlay bypass through an unapproved route constructor; a missing AppBar action-icon precedence test; a missing SearchView elevation override when `SearchAnchor` is used; a Critical UI or accessibility violation; an unreviewed theme override; an unresolved design conflict; a missing relevant component-state test.
- **Major**: a mismatch in component role mapping, repeated arbitrary radii or spacing, double padding, a competing primary CTA, or a golden diff that was not reviewed.
- **Minor**: a purely optical alignment issue that does not affect access or action.

A missing state test alone is `UNVERIFIED` coverage, not Critical (controller ruling 2026-10-15): the Critical "missing relevant component-state test" is a release gate that the FIX tasks meet by adding the test. Within Major and Minor: Major when a rendered colour role, contrast or state that the spec or an approved source fixes is wrong on a path a user reaches by touch or with a screen reader, with no equivalent cue left; Minor when only a pointer or keyboard reaches it while another cue remains, when it is a latent hazard with no violating consumer, or when it is optical or a consistency deviation.

Where the ledger classes a spec rule `CONFLICT`, `KEEP_EXISTING`, the item is
not a violation and carries no severity. Where it classes it `BLOCKED`, the
item is reported as a blocker, not a finding.
