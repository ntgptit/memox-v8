# SP1: retire the UI kit, make DESIGN.md the UI authority — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the "MemoX — Mobile UI Kit v3" artifact, its images, the design handoff and the kit capture tooling as UI authority, and make a `DESIGN.md` generated from the app the single visual record, with every live document and gate updated.

**Architecture:** Docs and tooling only; no Dart, no goldens. `check.py` stops checking links under `docs/superpowers/` (history keeps its dead links) and loses its design-handoff check. `DESIGN.md` is generated from `lib/core/theme/` and `lib/shared/widgets/` before the handoff is deleted. The 28 screen detail files are rewritten to describe the app and name goldens. ADR-019 records the decision; `CLAUDE.md`, `PRODUCT.md`, `docs/README.md`, `docs/wbs_FE.md` and the guard rule header follow.

**Tech Stack:** Markdown, Python 3 (`tools/docs/check.py`, `unittest`), the Impeccable `document` command, the code-verification guard.

**Spec:** `docs/superpowers/specs/2026-09-30-retire-ui-kit-design.md`

## Global Constraints

- No file under `docs/superpowers/` or `.impeccable/critique/` changes, except the SP1 spec and this plan.
- No `.dart` file and no `test/**/goldens/*.png` changes.
- The folder `docs/shared/ui/screen-handoff/` keeps its name.
- ADRs are written in Vietnamese with frontmatter `id`, `title`, `status: active`, `superseded_by:` and sections `## Bối cảnh`, `## Quyết định`, `## Hệ quả` (as ADR-018).
- `docs/wbs_FE.md`, `docs/README.md` and the screen detail files keep their existing language (Vietnamese for the first two, English for the detail files).
- Commit messages: conventional, English, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Every task ends with `python tools/docs/check.py` printing `PASS`.

## Review Focus

- A broken link in a **live** document (outside `docs/superpowers/`) must still fail `check.py` after the skip is added — Task 1 pins it with a test.
- A detail-file state whose kit image had no matching golden must say "no golden", never keep a dangling `img/` link or silently vanish — Tasks 3–5 end with a grep for `img/`.
- A deviation row that recorded real app behaviour (e.g. "empty card list → the deck is unset again") must survive in Layout/States/Rulings, not be deleted with the table — Tasks 3–5 check every removed row against the body.
- `DESIGN.md` must keep rules the code enforces that the handoff also stated (contrast pairs, 48 dp targets, local-first failure copy) — Task 2 compares before the handoff is deleted.
- ADR-019 enters `docs/_generated/`; forgetting `generate.py` makes `check.py` fail with "stale" — Task 6 runs it.

---

### Task 1: check.py skips links under docs/superpowers/ and drops the design-handoff check

**Files:**
- Modify: `tools/docs/check.py` (docstring lines 1–31, import line 43, `SKIP_ID_CHECK` line 82, `check_text` lines 259–278, `SPLIT`…`check_design_handoff` lines 316–336, `run()` line 519)
- Modify: `tools/docs/test_check.py` (add a test class)
- Delete: `tools/docs/split_handoff.py`, `tools/docs/test_split_handoff.py`, `tools/docs/__pycache__/split_handoff*.pyc`
- Modify: `docs/README.md` section `## Kiểm chứng` (around lines 368–384)

**Interfaces:**
- Produces: `check.SKIP_LINK_CHECK: tuple[str, ...] = ("superpowers",)` and `check.is_skipped_for_links(path: Path) -> bool`.

- [ ] **Step 1: Write the failing test** — append to `tools/docs/test_check.py`, before any `if __name__ == "__main__":` block:

```python
class LinkScopeTest(unittest.TestCase):
    def setUp(self):
        self.root = tree({
            "superpowers/plans/old.md": "see [img](img/gone.png)\n",
            "shared/ui/x.md": "see [img](img/gone.png)\n",
        })
        self.saved = check.g.DOCS
        check.g.DOCS = self.root

    def tearDown(self):
        check.g.DOCS = self.saved

    def test_history_is_skipped_for_links(self):
        self.assertTrue(check.is_skipped_for_links(self.root / "superpowers/plans/old.md"))

    def test_a_live_document_is_still_checked(self):
        self.assertFalse(check.is_skipped_for_links(self.root / "shared/ui/x.md"))
        report = check.Report()
        path = self.root / "shared/ui/x.md"
        check.check_links(path, path.read_text(encoding="utf-8"), "x", report)
        self.assertEqual(report.errors, 1)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `python -m unittest discover -s tools/docs -p "test_check.py"`
Expected: FAIL/ERROR with `AttributeError: module 'check' has no attribute 'is_skipped_for_links'`.

- [ ] **Step 3: Implement** in `tools/docs/check.py`:

After `SKIP_ID_CHECK = ("superpowers", "_generated")` add:

```python
# Historical plans and specs keep links to files later retired (ADR-019); they are
# records, not maintained docs, so their links are not checked.
SKIP_LINK_CHECK = ("superpowers",)
```

After `is_skipped_for_ids` add:

```python
def is_skipped_for_links(path: Path) -> bool:
    return path.relative_to(g.DOCS).parts[0] in SKIP_LINK_CHECK
```

In `check_text`, replace `check_links(path, line, where, report)` with:

```python
            if not skip_links:
                check_links(path, line, where, report)
```

and add `skip_links = is_skipped_for_links(path)` next to `check_ids = not is_skipped_for_ids(path)`.

Delete `import split_handoff as sh  # noqa: E402`, the `SPLIT` constant, `HANDOFF_DRIFT`, `check_design_handoff`, and the `check_design_handoff(report)` call in `run()`. In the module docstring delete the two lines starting `- docs/shared/ui/design-handoff/ not exactly…` and change `links are checked everywhere.` to `links are checked everywhere except docs/superpowers/.`

`Report.errors` is a `@property` (line 94), so the test reads `report.errors`.

- [ ] **Step 4: Delete the split tool**

```bash
git rm tools/docs/split_handoff.py tools/docs/test_split_handoff.py
rm -f tools/docs/__pycache__/split_handoff*.pyc tools/docs/__pycache__/test_split_handoff*.pyc
```

- [ ] **Step 5: Update `docs/README.md` `## Kiểm chứng`** — delete the `python tools/docs/split_handoff.py …` line from the code block, and in the paragraph after it delete the clause `, và \`shared/ui/design-handoff/\` có khớp từng byte với bản sinh lại từ JSON không (thiếu, bị sửa tay hay thừa file đều là ERROR)`; add the sentence `Link trong \`docs/superpowers/\` không được kiểm (tài liệu lịch sử, ADR-019).` Change `docstring của ba script` to `docstring của hai script`. (The ADR-019 link is added as plain text here; it becomes a link in Task 6.)

- [ ] **Step 6: Run tests and the docs gate**

Run: `python -m unittest discover -s tools/docs -p "test_*.py"` → Expected: OK.
Run: `python tools/docs/check.py` → Expected: `PASS — 0 error(s)`.

- [ ] **Step 7: Commit**

```bash
git add -A tools/docs docs/README.md
git commit -m "chore(docs): skip link checks in docs/superpowers, drop the design-handoff check"
```

---

### Task 2: Generate DESIGN.md from the app

**Files:**
- Create: `DESIGN.md` (repository root) and any sidecar the Impeccable `document` command writes.

**Interfaces:**
- Produces: `DESIGN.md` with sections for foundations (colour roles light/dark, type scale, spacing, radius, elevation, motion), theme binding (Material 3 component theme per slot), the Mx widget catalogue, and a "Copy voice" section holding the local-first failure rule.

- [ ] **Step 1: Run the generator.** Invoke the `impeccable:impeccable` skill with argument `document` (it reads `lib/core/theme/` and `lib/shared/widgets/`; per its instructions it may dispatch the `impeccable-documenter` agent). Tell it the source of truth is the shipped code and that `docs/shared/ui/design-handoff/` is being retired and must not be copied.

- [ ] **Step 2: Compare with the handoff.** Read `docs/shared/ui/design-handoff/01-foundations.md`, `02-theme-binding.md` and `widgets/error-state.md`. For each rule that the code enforces (grep `lib/core/theme/` and `test/core/theme/token_contrast_test.dart` to confirm) but `DESIGN.md` omits — contrast floors, 48 dp minimum touch target, the error-state copy voice ("say first that nothing was lost, then offer the retry") — add it to `DESIGN.md` in the generator's style. Do not add handoff rules the code does not implement.

- [ ] **Step 3: Verify.** `DESIGN.md` contains no link into `docs/shared/ui/design-handoff/`, `screen-handoff/img/` or the kit URL:

Run: `grep -nE "design-handoff|screen-handoff/img|UCesgHkzYHKsZwhwVshKRE|UI Kit v3" DESIGN.md`
Expected: no output.
Run: `python tools/docs/check.py` → `PASS`.

- [ ] **Step 4: Commit**

```bash
git add DESIGN.md
git commit -m "docs(design): DESIGN.md generated from the app's theme and shared widgets"
```

---

### Task 3: Rewrite screen detail files 01–12 (Library and cards)

**Files:**
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md` … `12-card-export.md`

Golden folders: 01, 02 → `test/features/deck/presentation/goldens/`; 03 → `test/features/starter_decks/presentation/goldens/`; 04 → `test/features/search/presentation/goldens/`; 05 → `test/features/tags/presentation/goldens/`; 06 → `test/features/trash/presentation/goldens/`; 07–10 → `test/features/card/presentation/goldens/`; 11, 12 → `test/features/transfer/presentation/goldens/`.

Apply these rules to each file:

1. **States table.** Replace the header `| State | Light | Dark | V8 |` with `| State | Golden (light) | Golden (dark) | App |`. In each row replace `![](img/<screen>/<id>-light.png)` / `-dark.png` with the matching golden names in backticks, chosen by listing the folder (`ls <folder> | grep <feature prefix>`) and matching the state meaning (e.g. 07 `loaded` → `` `card_list_light.png` `` / `` `card_list_dark.png` ``; `selection` → `card_selection_*`; `trashed` → `card_list_trashed_*`). When no golden shows that state write `no golden` in both cells. Under the table add one line: `The goldens are in \`<folder>\`.` (skip if the file already says it).
2. **App column.** Replace "As drawn." with a short statement of what the app shows (take it from the Layout table), or `—` when Layout already covers it. Remove "as drawn" / "the kit draws" / "the artifact" phrasing everywhere in the file, rewording to describe the app.
3. **Other image links.** Any other `![](img/…)` (e.g. the card-edit dialog under 07's "Not captured") is replaced by the golden name in backticks or removed with its sentence if no golden exists.
4. **Deviations.** For each row of `## Deviations`: if the "V8" text states behaviour the file's Layout/States does not already state, add it there as behaviour. If the "Wins" cell names a ruling (E-L*, D*, FE-*, A*, BR-*), add a bullet to `## Rulings` (create the section before `## Copy` if missing) stating the rule, e.g. `- **E-L1:** an empty card list makes the deck unset again (BR-DECK-015); screen 01's unset state shows.` Then delete the `## Deviations` section.
5. **Keep** Layout, Copy, BR/UC references, accessibility notes and the tag-filter/golden tables untouched except for rules 1–3.

- [ ] **Step 1:** Rewrite `01-deck-list.md` … `06-trash.md` by the rules.
- [ ] **Step 2:** Rewrite `07-card-list.md` … `12-card-export.md` by the rules.
- [ ] **Step 3: Verify no kit residue**

Run: `grep -nE "img/|## Deviations|[Aa]s drawn|[Aa]rtifact|the kit" docs/shared/ui/screen-handoff/0[1-9]-*.md docs/shared/ui/screen-handoff/1[0-2]-*.md`
Expected: no output.
Run: `python tools/docs/check.py` → `PASS` (golden names are in backticks, so they are not link-checked).

- [ ] **Step 4: Verify every golden name exists**

Run:
```bash
for f in docs/shared/ui/screen-handoff/0[1-9]-*.md docs/shared/ui/screen-handoff/1[0-2]-*.md; do
  grep -oE '`[a-z0-9_]+_(light|dark)\.png`' "$f" | tr -d '`' | sort -u | while read n; do
    ls test/features/*/presentation/goldens/"$n" >/dev/null 2>&1 || echo "$f: missing $n"; done; done
```
Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add docs/shared/ui/screen-handoff
git commit -m "docs(ui): screen files 01-12 describe the app and name goldens, no kit deviations"
```

---

### Task 4: Rewrite screen detail files 13–21 and 16a (Study)

**Files:**
- Modify: `docs/shared/ui/screen-handoff/13-study-home.md`, `14-study-entry.md`, `16-study-browse.md`, `16a-study-self-assess.md`, `17-study-match.md`, `18-study-guess.md`, `19-study-recall.md`, `20-study-fill.md`, `21-session-summary.md`

Golden folder: `test/features/study/presentation/goldens/` (prefixes `study_home_`, `study_entry_`, `study_browse`, `study_self_assess_`, `study_match_`, `study_guess_`, `study_recall_`, `study_fill_`, `summary_`).

- [ ] **Step 1:** Apply rules 1–5 of Task 3 to each file. In `16a-study-self-assess.md` replace "not in the kit" wording with "Shaped by Impeccable before the plan".
- [ ] **Step 2: Verify**

Run: `grep -nE "img/|## Deviations|[Aa]s drawn|[Aa]rtifact|the kit|in the kit" docs/shared/ui/screen-handoff/1[3-9]-*.md docs/shared/ui/screen-handoff/16a-*.md docs/shared/ui/screen-handoff/2[01]-*.md`
Expected: no output.
Run the golden-existence loop of Task 3 Step 4 over these files. Expected: no output.
Run: `python tools/docs/check.py` → `PASS`.

- [ ] **Step 3: Commit**

```bash
git add docs/shared/ui/screen-handoff
git commit -m "docs(ui): study screen files describe the app and name goldens"
```

---

### Task 5: Rewrite 15, 22–27 and the screen index

**Files:**
- Modify: `docs/shared/ui/screen-handoff/15-study-options.md`, `22-progress.md`, `23-settings.md`, `24-daily-reminder.md`, `25-theme.md`, `26-language.md`, `27-sync.md`, `00-index.md`

Golden folders: 15, 23, 25, 26, 27 → `test/features/settings/presentation/goldens/` (prefixes `study_options_`, `settings_`, `settings_theme_`, `settings_language_`, `sync_`); 22 → `test/features/progress/presentation/goldens/`; 24 → `test/features/reminders/presentation/goldens/`.

- [ ] **Step 1:** Apply rules 1–5 of Task 3 to 15 and 22–27. In `27-sync.md` replace "not in the kit" with "Shaped by Impeccable before the plan".
- [ ] **Step 2: Rewrite `00-index.md`:**
  - Rename the title `# MemoX V3 screen handoff — index` to `# MemoX screen index`.
  - Replace the intro and the Source/Authority/Detail files/Images/State checklist bullets with: the index lists every screen; each detail file records the screen's layout, states with their goldens, rulings and copy; the visual system is in `[DESIGN.md](../../../../DESIGN.md)` and the authority order is ADR-019 (plain text until Task 6 adds the ADR).
  - `## Status values`: keep only `built` (the app has the screen and its detail file describes it) and `out of V8`.
  - Every row's Status becomes `built`; row 16a and 27 drop "(not in the kit)" / "(shape brief)" qualifiers.
  - `## Rules shared by every screen`: reword "built as the artifact draws them" to "built as follows" and "Copy is the artifact's English" to "Copy is written in English first".
- [ ] **Step 3: Verify**

Run: `grep -nE "img/|## Deviations|[Aa]s drawn|[Aa]rtifact|the kit|UCesgHkzYHKsZwhwVshKRE|aligned|to align" docs/shared/ui/screen-handoff/`
Expected: no output.
Run the golden-existence loop of Task 3 Step 4 over 15 and 22–27. Expected: no output.
Run: `python tools/docs/check.py` → `PASS`.

- [ ] **Step 4: Commit**

```bash
git add docs/shared/ui/screen-handoff
git commit -m "docs(ui): settings and progress screen files and the index follow the app"
```

---

### Task 6: ADR-019, references, deletions

**Files:**
- Create: `docs/shared/decisions/ADR-019-app-la-chuan-ui.md`
- Modify: `CLAUDE.md`, `PRODUCT.md`, `docs/README.md`, `docs/wbs_FE.md`, `docs/shared/ui/screen-handoff/00-index.md` (ADR link), `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml` (header comment lines 3–5)
- Regenerate: `docs/_generated/`
- Delete: `docs/shared/ui/screen-handoff/img/`, `docs/shared/ui/design-handoff/`, `docs/shared/ui/design-handoff.json`, `docs/shared/ui/screen-state-checklist.md`, `tools/design/`

- [ ] **Step 1: Write the ADR**

```markdown
---
id: ADR-019
title: App là chuẩn UI; retire kit v3 và design handoff
status: active
superseded_by:
---
## Bối cảnh

Đến 2026-09-30, chuẩn hình ảnh của V8 là artifact "MemoX — Mobile UI Kit v3" và bản
design handoff tách từ nó (`docs/shared/ui/design-handoff/`). Mọi chỗ app khác kit phải
ghi thành deviation trong file chi tiết của màn. Đợt critique Impeccable toàn bộ 28 màn
ngày 2026-09-30 thấy nhiều điểm yếu do chính kit vẽ (khối tiến độ ba lớp ở màn 07, số
liệu lặp ba lần ở màn 21, hai nút Save ở màn 08/09). Sửa chúng nghĩa là ghi thêm
deviation.

## Quyết định

- Kit v3 và design handoff không còn là chuẩn. Artifact vẫn nằm trên claude.ai như lịch
  sử, không được đọc làm nguồn.
- Thứ tự ưu tiên: BR/UC > [`DESIGN.md`](../../../DESIGN.md) cùng golden đã được chủ dự án
  duyệt > file chi tiết của màn trong `docs/shared/ui/screen-handoff/`.
- `DESIGN.md` được sinh từ code (`lib/core/theme/`, `lib/shared/widgets/`) và cập nhật
  cùng PR với mọi thay đổi hệ thống hình ảnh. File chi tiết của màn cập nhật cùng PR với
  thay đổi của màn đó. Không còn khái niệm deviation so với kit.
- Impeccable đánh giá UI so với `DESIGN.md` và quality floor.

## Hệ quả

- Xoá `docs/shared/ui/screen-handoff/img/`, `docs/shared/ui/design-handoff/`,
  `docs/shared/ui/design-handoff.json`, `tools/docs/split_handoff.py`, `tools/design/`
  và checklist state theo kit; bỏ các mục Deviations của file chi tiết.
- `tools/docs/check.py` không kiểm link trong `docs/superpowers/`: spec và plan cũ là hồ
  sơ lịch sử, giữ nguyên link tới các file đã xoá.
- Sổ nợ UI-base (spec 2026-09-23 §9) vẫn là danh sách nợ UI đã biết, không còn ghi lệch
  với kit.
```

- [ ] **Step 2: `CLAUDE.md`** — edit these parts (keep everything else):
  - Layers bullet: `- **Impeccable judges UI against the kit, not against its own taste.** The kit is the design authority ([UI source of truth](#ui-source-of-truth)). Impeccable checks the work against the kit and against the quality floor.` → `- **Impeccable judges UI against \`DESIGN.md\`, not against its own taste.** \`DESIGN.md\` is the design authority ([UI source of truth](#ui-source-of-truth)). Impeccable checks the work against it and against the quality floor.`
  - "A screen's workflow": step 1 → `Read the screen's detail file, its goldens and \`DESIGN.md\`.`; step 3 first sub-bullet → `critique the design against \`DESIGN.md\` (what the plan must adopt or rule on);`; second → `use \`shape\` only for a screen or state not built yet.`; step 5 → `Run Impeccable after the build: critique and audit the goldens against \`DESIGN.md\`.`
  - "Where knowledge lives" row `| Deviations from the kit or a UI spec | the screen's detail file or the UI-base register (§9) |` → three rows: `| The visual system | \`DESIGN.md\` |`, `| A screen's layout, states, rulings and copy | its detail file in \`docs/shared/ui/screen-handoff/\` |`, `| Known UI debt | the UI-base register (§9) |`.
  - Session handoff bullet "It is unrelated to the design and screen handoffs under `docs/shared/ui/`" → "It is unrelated to the screen files under `docs/shared/ui/screen-handoff/`".
  - Replace the whole `## UI source of truth` section body with:

```markdown
The visual authority for every V8 screen is the app itself, recorded in
[`DESIGN.md`](DESIGN.md) and in the goldens the owner reviewed
([ADR-019](docs/shared/decisions/ADR-019-app-la-chuan-ui.md)). The artifact
"MemoX — Mobile UI Kit v3" is retired and is never read as a source.

- **Precedence:** a BR or UC beats `DESIGN.md`; `DESIGN.md` and the reviewed
  goldens beat a screen's detail file.
- **Where it is described:**
  - [`DESIGN.md`](DESIGN.md) holds the foundations, the theme binding, the
    shared widgets and the copy voice;
  - the [screen index](docs/shared/ui/screen-handoff/00-index.md) holds the
    screen numbers, FE items, status and the rules every screen shares; each
    screen's detail file holds its layout, states with goldens, rulings and copy.
- **Changing UI:** update `DESIGN.md` when the visual system changes and the
  screen's detail file when the screen changes, in the same PR.
- **After building a screen,** update its row in the screen index.
```

- [ ] **Step 3: `PRODUCT.md`** — Brand Commitments: the copy-voice bullet's source becomes `(\`DESIGN.md\`, Copy voice)`; `- The visual system is the V3 design handoff (…) , implemented by the Flutter UI base. It is recorded there, not here.` → `- The visual system is recorded in \`DESIGN.md\`, generated from the Flutter UI base (ADR-019). It is recorded there, not here.` Evidence on Hand: replace the "V3 design handoff" bullet with `- \`DESIGN.md\`: foundations, theme binding, shared widgets and copy voice, generated from the code.` and the "kit's screens and states as images" bullet with `- Each screen's detail file with its states, goldens and rulings (\`docs/shared/ui/screen-handoff/\`).`

- [ ] **Step 4: `docs/README.md`** — in the tree delete the `design-handoff.json` and `design-handoff/` lines (and `screen-state-checklist.md` if listed). Replace the paragraph that starts with `shared/ui/design-handoff/ là bản tách nguyên văn` (through its end) and the paragraph that starts with `Thư mục cạnh đó, shared/ui/screen-handoff/` with the text below. Turn the plain-text "ADR-019" added in Task 1 into the same ADR link. Add ADR-019 wherever the file lists ADRs.

```markdown
`shared/ui/screen-handoff/` ghi từng màn của app: layout, state kèm golden, ruling và copy
([index](shared/ui/screen-handoff/00-index.md)). Hệ thống hình ảnh ở [`DESIGN.md`](../DESIGN.md);
thứ tự ưu tiên theo [ADR-019](shared/decisions/ADR-019-app-la-chuan-ui.md).
```

- [ ] **Step 5: `docs/wbs_FE.md`** — line 11: replace `[handoff V3](shared/ui/design-handoff/00-index.md)` with `[\`DESIGN.md\`](../DESIGN.md)`; lines 37–38: replace the checklist bullet with `- Mỗi màn có file chi tiết trong [screen-handoff](shared/ui/screen-handoff/00-index.md), liệt kê state kèm golden.`; line 121 (FE-D4): replace `[design handoff](shared/ui/design-handoff/00-index.md)` with `design handoff (đã retire theo ADR-019)`. Add a row after FE-D4:

```markdown
| FE-D5 | Retire UI Kit v3 và design handoff; `DESIGN.md` sinh từ app là chuẩn UI (ADR-019); file chi tiết màn mô tả app và ghi golden | xong | — | M | [spec](superpowers/specs/2026-09-30-retire-ui-kit-design.md) và [plan](superpowers/plans/2026-09-30-retire-ui-kit.md); SP1 của đợt sửa theo critique 2026-09-30 (SP2 shared, SP3a/SP3b màn hình theo sau) | — |
```

- [ ] **Step 6: `00-index.md`** — turn the plain-text ADR-019 into `[ADR-019](../../decisions/ADR-019-app-la-chuan-ui.md)`.

- [ ] **Step 7: Guard rule header** — in `memox-design-token-rules.yaml` replace lines 3–5 with:

```yaml
# The visual system (`DESIGN.md`): no hardcoded colours, text styles or
# padding — everything comes from design tokens.
```

- [ ] **Step 8: Delete retired files**

```bash
git rm -r -q docs/shared/ui/screen-handoff/img docs/shared/ui/design-handoff tools/design
git rm -q docs/shared/ui/design-handoff.json docs/shared/ui/screen-state-checklist.md
```

- [ ] **Step 9: Regenerate and check**

Run: `python tools/docs/generate.py` then `python tools/docs/check.py` → Expected: `PASS — 0 error(s)`.
Run: `python -m unittest discover -s tools/docs -p "test_*.py"` → OK.

- [ ] **Step 10: Residue grep** (spec §4.7)

```bash
grep -rnE "UCesgHkzYHKsZwhwVshKRE|UI Kit v3|design-handoff|screen-handoff/img|screen-state-checklist|tools/design" \
  --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool --exclude-dir=superpowers --exclude-dir=.impeccable . \
  | grep -v "docs/shared/decisions/ADR-019-app-la-chuan-ui.md" | grep -v "docs/_generated/"
```
Expected: no output, except `docs/wbs_FE.md` lines that name the retired handoff in prose without a path (acceptable; remove any path).

- [ ] **Step 11: History untouched**

Run: `git diff --stat origin/master -- docs/superpowers .impeccable`
Expected: only `docs/superpowers/specs/2026-09-30-retire-ui-kit-design.md` and `docs/superpowers/plans/2026-09-30-retire-ui-kit.md`.

- [ ] **Step 12: Full local gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: every step passes (docs, guard, guard self-tests, CI tooling tests, hook tests, analyze, tests without goldens). If the Flutter part cannot run on this machine, report which step and why, and at minimum run the guard: `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`.

- [ ] **Step 13: Commit**

```bash
git add -A
git commit -m "docs: ADR-019 makes the app the UI authority; retire the kit, its images and the design handoff"
```
