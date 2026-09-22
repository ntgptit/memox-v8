# Docs V8 Reset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip `docs/` down to the business material V8 is built from — delete every V7/V3 implementation, process and design document, scrub the references they leave behind in the survivors, and promote `data-model.md` to V8's data-model authority.

**Architecture:** Deletion first, then a grep-based gate that fails on every V7 leftover, then one scrub task per document group until the gate is green. The gate is a single ~110-line Python script under `tools/`; no framework, no fixtures. `data-model.md` is upgraded last, because it owns the invariant numbering the scrub tasks cite.

**Tech Stack:** Markdown, Python 3 stdlib (`re`, `pathlib`) for the gate. No new dependency.

**Spec:** `docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md` is the V8 authority this plan defers to. No separate spec was written for the cleanup itself; the four decisions that drive it were taken in the session of 2026-09-23 and are recorded verbatim in Global Constraints below.

## Global Constraints

Every task's requirements implicitly include these.

- **Documentation language is Vietnamese with diacritics**, matching the existing documents. Table column headers, `Status` values (`active`), and the MUST/SHOULD/MAY keywords stay English, as they already are.
- **The keep-set is exactly these 27 existing files** plus `docs/README.md` rewritten and this plan. Nothing else under `docs/` survives:
  `docs/README.md` · `docs/document-conventions.md` · `docs/product.md` · `docs/business-rules.md` · `docs/business-rules/study-mode.md` · `docs/use-cases.md` · `docs/master-flow.md` · `docs/data-model.md` · the 17 files of `docs/it-scenarios/` · `docs/superpowers/plans/2026-09-21-memox-v8-foundation.md` · `docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md`.
- **All of BR-01…BR-270 is kept**, including rules for Trash, import/export, tags, daily reminders, starter decks and extended statistics. Those are later V8 sub-projects, not dropped features. No rule text is deleted for being out of V8.0 scope.
- **BR, UC and invariant numbers are permanent.** Never renumber, never reuse a retired number, never close a gap in the sequence. A previous renumber silently broke implicit references; the documents say so themselves.
- **No `AD-nn` reference survives anywhere in the keep-set.** `docs/architecture.md` is deleted. Where a citation carried business meaning rather than V7 layering, the meaning is restated in place (see Review Focus item 1).
- **No V7 WBS task ID (`M<digits>.<digits>`) survives**, and no header value cites one.
- **No V7 source path (`lib/…`) survives.** V8 has no `lib/` tree yet.
- **V8 requires no V7 data compatibility** and has no migration path from V7 (spec §1). Any V7 migration-order or schema-version material is V7 history.
- **Verification gate:** `python tools/check_docs_refs.py` exits 0. Every task that edits a keep-set file runs it on the files that task touched before committing.

## Review Focus

Five ways this cleanup can look finished and not be. Each has a test in the task that owns it.

1. **A business rule loses its meaning when its AD citation is deleted.** Of the 19 cited AD ids, some encode V7 architecture (AD-12 nested Clean Architecture, AD-13, AD-15, AD-17, AD-23) but others encode *business* the V8 spec preserves verbatim — AD-06 scheduler locked after first review, AD-09 reset and generation, AD-10 deck tree with `root_id` and `content_type`, AD-11 state stored not inferred. Blanket-deleting `AD-06` from BR-13 leaves a rule that no longer says why the scheduler locks. Owned by Task 4.
2. **Invariant `Q<n>` citations outlive their definitions.** `business-rules.md` cites `invariant Q15`; the invariants are numbered SQL comments (`-- 15.`) inside `data-model.md`, which Task 8 rewrites. A renumber there silently breaks 40-odd citations written in Task 4. Owned by Task 8, checked by the gate from Task 2.
3. **V7 implementation status is read as V8 status.** `product.md` §S1–S3 and §N2–N3 say "**Đã triển khai** (M4.11)". In V8 nothing is implemented. De-referencing `M4.11` while leaving "Đã triển khai" turns a V7 fact into a V8 lie. Owned by Task 3.
4. **`docs/README.md` indexes files that no longer exist.** It currently lists `wbs.md`, `architecture.md`, `checklist.md`, `wireframes/`, `reviews/`, `claude-design/` and a "Not written yet" table naming four `flutter-*` skills. Owned by Task 7.
5. **A `BR-nnn` or `UC-nn` citation points at a number that was never defined.** 261 BR ids are defined but the sequence runs to 270, so gaps exist; a citation into a gap resolves to nothing and nothing currently reports it. Owned by Task 2.

---

### Task 1: Delete the V7 and V3 documents

**Files:**
- Delete: 255 files under `docs/` — everything except the keep-set named in Global Constraints
- Delete: `tools/check_spec.py`, `tools/__pycache__/`
- Test: `tools/` and `docs/` file listings, verified by the commands in the steps

`tools/check_spec.py` is the audit gate for `docs/design/memox-v3` and reads that directory at import time. With the directory gone the script cannot run at all, so it goes with it.

**Interfaces:**
- Consumes: nothing
- Produces: the keep-set — the exact file list every later task operates on

- [ ] **Step 1: Confirm the baseline commit exists**

```bash
cd /d/workspace/memox-v8
git log --oneline -1
```

Expected: one line ending `chore: baseline snapshot before docs cleanup for V8`. If it is missing, stop — there is no restore point.

- [ ] **Step 2: Delete the V7/V3 document trees**

```bash
cd /d/workspace/memox-v8
git rm -r -q --ignore-unmatch \
  docs/architecture.md docs/checklist.md \
  docs/wbs.md docs/wbs-study.md docs/wbs-archive \
  docs/claude-design docs/design docs/design-system \
  docs/prompt docs/reviews docs/wireframes
```

- [ ] **Step 3: Delete the V7-era plans and specs, keeping the two V8 ones**

```bash
cd /d/workspace/memox-v8
git ls-files 'docs/superpowers/*' \
  | grep -v '2026-09-21-memox-v8-foundation' \
  | grep -v '2026-09-23-docs-v8-reset' \
  | xargs -r git rm -q
```

- [ ] **Step 4: Delete the V3 spec gate**

```bash
cd /d/workspace/memox-v8
git rm -q tools/check_spec.py
rm -rf tools/__pycache__
```

- [ ] **Step 5: Verify exactly the keep-set remains**

```bash
cd /d/workspace/memox-v8
git ls-files docs | sort
```

Expected: 28 lines and no others — `docs/README.md`, `docs/business-rules.md`, `docs/business-rules/study-mode.md`, `docs/data-model.md`, `docs/document-conventions.md`, `docs/it-scenarios/` (17 files), `docs/master-flow.md`, `docs/product.md`, `docs/superpowers/plans/2026-09-21-memox-v8-foundation.md`, `docs/superpowers/plans/2026-09-23-docs-v8-reset.md`, `docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md`, `docs/use-cases.md`.

If the count differs, list the difference and fix it before committing — do not proceed with a wrong keep-set.

- [ ] **Step 6: Commit**

```bash
cd /d/workspace/memox-v8
git add -A
git commit -m "docs: delete V7 and V3 documents, keep the V8 business set

Removes architecture, WBS ledgers, task prompts, review reports, wireframes,
the V3 design spec and its gate. Keeps product, business rules, use cases,
master flow, data model, IT scenarios, document conventions and the two V8
foundation documents.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: The reference gate

**Files:**
- Create: `tools/check_docs_refs.py`
- Test: the script is its own test — it is run against the real keep-set and must report the known leftovers

There is no test framework in this repo and the thing under test is a document set, so the gate is the check. It must fail loudly now and pass only when Tasks 3–8 are done.

**Interfaces:**
- Consumes: the keep-set from Task 1
- Produces: `python tools/check_docs_refs.py [path ...]` — exits 0 when clean, 1 otherwise; prints `<file>:<line>: <reason>` per problem. With no argument it checks the whole keep-set. Tasks 3–8 run it on the files they touch.

- [ ] **Step 1: Write the gate**

```python
#!/usr/bin/env python3
"""Gate: the V8 docs keep-set may not cite anything that no longer exists.

    python tools/check_docs_refs.py [path ...]

With no argument, checks the whole keep-set. Exits 0 only when every check
passes. Nothing here edits a file.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

BR_FILES = [DOCS / "business-rules.md", DOCS / "business-rules" / "study-mode.md"]
UC_FILE = DOCS / "use-cases.md"
DM_FILE = DOCS / "data-model.md"

KEEP_SET = [
    DOCS / "README.md",
    DOCS / "document-conventions.md",
    DOCS / "product.md",
    UC_FILE,
    DOCS / "master-flow.md",
    DM_FILE,
    *BR_FILES,
    *sorted((DOCS / "it-scenarios").glob("*.md")),
]

# Each pattern names something V8 no longer has. Order is report order.
BANNED = [
    (re.compile(r"AD-\d+"), "AD reference — architecture.md is deleted"),
    (re.compile(r"\bM\d+(?:\.\d+)+\b"), "V7 WBS task ID — the ledgers are deleted"),
    (re.compile(r"\blib/"), "V7 source path — V8 has no lib/ yet"),
    (re.compile(r"\b(?:wbs-study|wbs|architecture|checklist)\.md\b"), "deleted document"),
    (
        re.compile(r"\b(?:wbs-archive|wireframes|reviews|claude-design|design-system)/"),
        "deleted directory",
    ),
]

BR_DEF = re.compile(r"^\|\s*BR-(\d+)\s*\|", re.M)
UC_DEF = re.compile(r"^#+\s*UC-(\d+)\b", re.M)
INV_DEF = re.compile(r"^--\s*(\d+)\.", re.M)
BR_ROW = re.compile(r"^\|\s*BR-\d+\s*\|")

problems: list[str] = []


def fail(path: Path, line_no: int, reason: str) -> None:
    problems.append(f"{path.relative_to(ROOT).as_posix()}:{line_no}: {reason}")


def defined_ids(path: Path, pattern: re.Pattern[str]) -> set[int]:
    if not path.exists():
        return set()
    return {int(m) for m in pattern.findall(path.read_text(encoding="utf-8"))}


def check_file(path: Path, br: set[int], uc: set[int], inv: set[int]) -> None:
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        for pattern, reason in BANNED:
            for hit in pattern.findall(line):
                fail(path, line_no, f"{reason}: {hit}")
        # A rule's definition row still cites other rules in its Related
        # column — 171 of them do — so drop only the leading `| BR-nnn |`
        # and scan the rest. Skipping the whole row blinds the check.
        body = BR_ROW.sub("", line.strip(), count=1)
        for n in re.findall(r"\bBR-(\d+)\b", body):
            if int(n) not in br:
                fail(path, line_no, f"BR-{n} is cited but never defined")
        for n in re.findall(r"\bUC-(\d+)\b", line):
            if int(n) not in uc:
                fail(path, line_no, f"UC-{n} is cited but never defined")
        for n in re.findall(r"\binvariant Q(\d+)\b", line):
            if int(n) not in inv:
                fail(path, line_no, f"invariant Q{n} is cited but data-model.md has no `-- {n}.`")


def main() -> int:
    targets = [Path(a).resolve() for a in sys.argv[1:]] or KEEP_SET
    br: set[int] = set()
    for f in BR_FILES:
        br |= defined_ids(f, BR_DEF)
    uc = defined_ids(UC_FILE, UC_DEF)
    inv = defined_ids(DM_FILE, INV_DEF)

    for path in targets:
        if not path.exists():
            problems.append(f"{path}: missing")
            continue
        check_file(path, br, uc, inv)

    for p in problems:
        print(p)
    print(f"\n{len(br)} BR · {len(uc)} UC · {len(inv)} invariants defined")
    if problems:
        print(f"FAIL — {len(problems)} problem(s)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 2: Run it and verify it fails on the known leftovers**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py; echo "exit=$?"
```

Expected: `exit=1`, a summary line reading exactly `261 BR · 22 UC · 37 invariants defined`, and roughly 300 problem lines dominated by `AD reference` hits in `docs/business-rules.md` and `V7 WBS task ID` hits in `docs/product.md` and `docs/master-flow.md`.

Those three counts are measured facts about this repo, not estimates. If any of them comes back different, the definition regexes do not match this repo's formatting — fix the regex against the real file before continuing, because every later task depends on these resolving correctly.

- [ ] **Step 3: Verify it passes on a file with no leftovers**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/document-conventions.md; echo "exit=$?"
```

Expected: `exit=0` and `PASS`. `document-conventions.md` has zero AD, M and `lib/` references today, so it is the control case: a green run here proves the gate is not passing everything by accident.

- [ ] **Step 4: Commit**

```bash
cd /d/workspace/memox-v8
git add tools/check_docs_refs.py
git commit -m "test: add the docs reference gate

Fails on AD references, V7 WBS task IDs, V7 source paths, deleted documents
and directories, and on BR/UC/invariant citations that resolve to nothing.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Scrub `product.md` and `master-flow.md`

Both carry V7 *implementation status* rather than business rules: `product.md` has 25 task IDs and `master-flow.md` 38, almost all inside "đã triển khai ở M99.29" style claims. In V8 nothing is implemented, so the claim goes with the ID.

**Files:**
- Modify: `docs/product.md` (9 AD, 25 task IDs, 7 Flutter/Riverpod/Drift mentions)
- Modify: `docs/master-flow.md` (38 task IDs, 2 `lib/` paths)
- Test: `python tools/check_docs_refs.py docs/product.md docs/master-flow.md`

**Interfaces:**
- Consumes: the gate from Task 2
- Produces: the rewritten seven-line header form that Tasks 4–8 copy — `Updated by task` is replaced by `**Updated by**` whose value is a plan filename, never a task ID

- [ ] **Step 1: Run the gate to see the full list for these two files**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/product.md docs/master-flow.md
```

Expected: FAIL, ~74 lines. Keep this output; it is the worklist.

- [ ] **Step 2: Rewrite both seven-line headers**

Replace the `| **Updated by task** | M100.96 (…) · M100.95 (…) … |` row with:

```markdown
| **Updated by** | `docs/superpowers/plans/2026-09-23-docs-v8-reset.md` — V8 reset: V7 implementation status and references removed |
```

In `product.md`'s `Depends on` row, drop `architecture.md`. Set `| **Last updated** | 2026-09-23 |` in both.

- [ ] **Step 3: Turn every V7 status claim into a V8 scope statement**

For each row whose status cites a task ID, drop the ID and restate the row as scope, not progress. The rule: **what the feature is** survives, **whether V7 shipped it** does not.

```markdown
| S1 | Tìm kiếm card trong deck | Trong phạm vi: tìm theo nội dung mặt trước/sau trong deck đang mở, không phân biệt hoa thường và giữ dấu. Tìm toàn thư viện là UC-20 |
| S2 | Thống kê ôn tập cơ bản | Trong phạm vi (UC-12, BR-190…BR-199): số card đã học hôm nay tách Learning/Reviewing, streak theo ngày, và hoạt động bảy ngày gần nhất. Ngoài phạm vi: accuracy, longest streak, goal, XP, heatmap và lọc theo deck (BR-191) |
| S3 | Đảo chiều card (nghĩa → từ) | Trong phạm vi (UC-15, BR-203…BR-209): chọn chiều hỏi trước lượt đầu, chỉ cho phiên ôn tập `self_assess` của deck `sm2` |
| N2 | Nhắc nhở ôn tập hằng ngày | Sub-project sau (UC-17, BR-218…BR-229): opt-in, mặc định tắt, một tóm tắt mỗi ngày dựng từ workload đến hạn tại thời điểm hiện tại. Quyền notification chỉ được xin **sau** khi người dùng bật (BR-228) |
| N3 | Tag/phân loại card | Sub-project sau (UC-18, BR-230…BR-238): catalog phạm vi library, lọc nhiều tag theo OR, đổi tên có gộp, và xoá. Ngoài phạm vi: tag phân cấp, màu tag, taxonomy chia sẻ |
```

Use `Sub-project sau` for the six features the V8 spec defers (Trash, import/export, tags, daily reminders, starter decks, extended statistics) and `Trong phạm vi` for the rest.

- [ ] **Step 4: Replace the AD citations in `product.md`**

Nine citations, all to platform decisions the V8 spec restates in its §3 Decisions table. Replace the pointer with the decision itself:

- `AD-01` local-first → `local-only, không network`
- `AD-03` auth-ready → `chưa có auth`
- `AD-04` Android target → `Android là target release`
- `AD-05` no network dependency → `chưa thêm dependency mạng`
- any remaining → state the decision in words

At the end of the section that held them, add one line:

```markdown
Các quyết định nền tảng trên nằm ở `superpowers/specs/2026-09-21-memox-v8-foundation-design.md` §3.
```

- [ ] **Step 5: Remove the two `lib/` paths from `master-flow.md`**

Replace each with the feature name the path pointed at — `master-flow.md` describes journeys, so a source path is never load-bearing there.

- [ ] **Step 6: Run the gate**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/product.md docs/master-flow.md; echo "exit=$?"
```

Expected: `exit=0`, `PASS`.

- [ ] **Step 7: Commit**

```bash
cd /d/workspace/memox-v8
git add docs/product.md docs/master-flow.md
git commit -m "docs: scrub V7 references from product and master-flow

V7 implementation status becomes V8 scope; task IDs, AD citations and source
paths removed. Deferred features are marked as later sub-projects.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Scrub `business-rules.md` and `business-rules/study-mode.md`

The heaviest task: 117 AD citations across 261 rule rows, plus an `Enforced by` column written in V7 layer vocabulary. This is where Review Focus item 1 bites.

**Files:**
- Modify: `docs/business-rules.md` (113 AD, 20 task IDs, 1 `lib/`)
- Modify: `docs/business-rules/study-mode.md` (4 AD, 1 task ID)
- Test: `python tools/check_docs_refs.py docs/business-rules.md docs/business-rules/study-mode.md`

**Interfaces:**
- Consumes: the header form from Task 3
- Produces: the `Enforced by` vocabulary that Task 8 must keep consistent with `data-model.md`'s invariant numbering

- [ ] **Step 1: Run the gate for the worklist**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/business-rules.md docs/business-rules/study-mode.md
```

Expected: FAIL, ~138 lines.

- [ ] **Step 2: Rewrite the `Enforced by` column into V8 vocabulary**

The column currently names V7 layers. The V8 spec has no repository layer and no use-case layer; it has pure-Dart rules, feature stores over one `AppDatabase`, and UI. Map every value, leaving the `invariant Qn` suffix untouched:

| V7 value | V8 value |
|---|---|
| `repository` | `store` |
| `domain` | `rule` |
| `presentation` | `UI` |
| `db` | `db` |
| `UI` | `UI` |
| `script` | `script` |

`| BR-62 | active | … | repository | AD-10, UC-08 |` becomes `| BR-62 | active | … | store | UC-08 |`.

**Do not touch `invariant Q<n>`.** Those numbers are permanent and Task 8 is bound to preserve them.

- [ ] **Step 3: Delete the AD citations that carry only V7 architecture**

`AD-02`, `AD-12`, `AD-13`, `AD-14`, `AD-15`, `AD-17`, `AD-18`, `AD-19`, `AD-23` describe V7 layering, widget buckets and theming. Remove the id from the `Related` column and, where a rule's prose names one (`… theo AD-15`), delete the clause. Do not restate them: CLAUDE.md forbids carrying V7 architecture into V8.

- [ ] **Step 4: Inline the AD citations that carry business**

These ten encode rules the V8 spec preserves. Deleting the pointer without the content is the failure in Review Focus item 1. For each, fold the rule into the BR text:

| AD | What the rule must still say after the citation is gone |
|---|---|
| `AD-06` | Scheduler được chọn khi tạo root deck và **khoá sau lượt review đầu tiên**; đổi scheduler cần Reset learning progress |
| `AD-07` | Starter deck là **template**; người dùng nhận một bản sao, không dùng chung hàng gốc |
| `AD-08` | Dữ liệu là riêng tư; nội dung card **MUST NOT** xuất hiện trong log ở bất kỳ level nào |
| `AD-09` | Reset learning progress **tăng `generation`**; review ghi từ session mang `generation` cũ MUST bị từ chối, không bao giờ được áp |
| `AD-10` | Cây deck nhiều cấp, tối đa 10 cấp; `root_id` được **lưu**, không suy ra bằng `COALESCE(parent_id, id)`; `content_type` là `unset` \| `card` \| `deck` |
| `AD-11` | Trạng thái là dữ liệu **được lưu tường minh**, không suy luận — `kind`, `status`, `end_reason` đều được ghi |
| `AD-16` | "Đầu ngày học" và offset múi giờ do composition root cấp; scheduler trả **số ngày**, không trả thời điểm; MUST NOT đọc đồng hồ trực tiếp |
| `AD-20` | Card Transfer dùng **sáu field nội dung canonical** chung (`front · back · example · note · hint · source`), thứ tự cố định, header chữ thường tiếng Anh |
| `AD-21` | Nhắc học chạy trong **background worker**, không phải notification đặt sẵn |
| `AD-22` | Trash là **tombstone một cột trên hàng**, batch là bảng riêng; loại trừ tombstone là hợp đồng của mọi query đọc |

`AD-01`, `AD-03`, `AD-04`, `AD-05` are platform decisions already stated in `product.md` by Task 3 — delete the citation without restating.

- [ ] **Step 5: Rewrite both headers and remove the remaining task IDs and `lib/` path**

Same header form as Task 3. Drop `architecture.md` from `Depends on`. Remove the 21 task IDs (all inside the header's `Updated by task` value and a handful of prose notes) and the single `lib/` path.

- [ ] **Step 6: Run the gate**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/business-rules.md docs/business-rules/study-mode.md; echo "exit=$?"
```

Expected: `exit=0`, `PASS`.

- [ ] **Step 7: Spot-check that no rule lost its meaning**

```bash
cd /d/workspace/memox-v8
grep -nE "^\| BR-(13|55|56|57|58|62) \|" docs/business-rules.md
```

Expected: BR-13 states the scheduler lock in its own words; BR-55 still says max 10 levels; BR-56/BR-57 still say `root_id` is stored and `COALESCE` is forbidden. If any reads as a bare rule with its reason deleted, fix it before committing.

- [ ] **Step 8: Commit**

```bash
cd /d/workspace/memox-v8
git add docs/business-rules.md docs/business-rules/study-mode.md
git commit -m "docs: scrub V7 references from business rules

AD citations that carried business are inlined into the rules; the ones that
carried only V7 layering are dropped. Enforced-by column moves to V8
vocabulary. Invariant numbers untouched.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Scrub `use-cases.md` and `document-conventions.md`

**Files:**
- Modify: `docs/use-cases.md` (4 AD, 19 task IDs, 1 link to `master-flow.md` which survives)
- Modify: `docs/document-conventions.md` (0 banned references, but it mandates the `Updated by task` header and the AD template)
- Test: `python tools/check_docs_refs.py docs/use-cases.md docs/document-conventions.md`

`document-conventions.md` trips no pattern today, yet it is the document that *tells later writers* to use `Updated by task` and to keep an AD register. Leaving it unchanged would re-import V7 process the moment someone writes a new doc.

**Interfaces:**
- Consumes: the header form established in Task 3
- Produces: the written contract for that header form, which Task 7's rewritten README points at

- [ ] **Step 1: Run the gate for the worklist**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/use-cases.md docs/document-conventions.md
```

Expected: FAIL on `use-cases.md` only, ~23 lines.

- [ ] **Step 2: Scrub `use-cases.md`**

Rewrite the header as in Task 3, drop `architecture.md` from `Depends on`, remove the 19 task IDs, and handle the 4 AD citations by the Task 4 rule: inline if business, delete if V7 architecture.

- [ ] **Step 3: Update the header contract in `document-conventions.md`**

Replace the `Updated by task` row in the seven-line template with:

```markdown
| **Updated by** | `<đường dẫn plan>` — mô tả ngắn thay đổi |
```

State that the value is a plan path under `docs/superpowers/plans/`, never a WBS task ID, because V8 has no WBS ledger.

- [ ] **Step 4: Remove the AD template and register from `document-conventions.md`**

V8 records architecture decisions in its specs under `docs/superpowers/specs/`, not in a numbered AD register. Delete the AD template section and any rule requiring an `AD-nn` citation. Leave the BR and UC templates untouched — both documents survive and both keep their numbering.

- [ ] **Step 5: Run the gate**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/use-cases.md docs/document-conventions.md; echo "exit=$?"
```

Expected: `exit=0`, `PASS`.

- [ ] **Step 6: Commit**

```bash
cd /d/workspace/memox-v8
git add docs/use-cases.md docs/document-conventions.md
git commit -m "docs: scrub use cases and retire the AD register from conventions

V8 records architecture decisions in specs, not a numbered AD register. The
header's Updated-by value becomes a plan path instead of a WBS task ID.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Scrub `docs/it-scenarios/`

17 files carrying 24 AD citations, 36 task IDs, 1 `lib/` path and 20 Flutter/Drift mentions. All 60 internal links point inside `it-scenarios/`, so none of them dangle.

**Files:**
- Modify: all 17 `.md` files under `docs/it-scenarios/`
- Test: `python tools/check_docs_refs.py docs/it-scenarios/*.md`

**Interfaces:**
- Consumes: the AD-handling rule from Task 4 — apply it identically here
- Produces: nothing later tasks read

- [ ] **Step 1: Run the gate for the worklist**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/it-scenarios/*.md
```

Expected: FAIL, ~61 lines across the 17 files.

- [ ] **Step 2: Apply the AD rule file by file**

V7-architecture AD (`AD-02`, `AD-12`, `AD-13`, `AD-14`, `AD-15`, `AD-17`, `AD-18`, `AD-19`, `AD-23`) → delete the citation and any clause that exists only because of V7 layering.

Business AD → inline the rule. The wording, repeated here so this task reads standalone:

| AD | What the scenario must still say after the citation is gone |
|---|---|
| `AD-06` | Scheduler được chọn khi tạo root deck và **khoá sau lượt review đầu tiên**; đổi scheduler cần Reset learning progress |
| `AD-07` | Starter deck là **template**; người dùng nhận một bản sao, không dùng chung hàng gốc |
| `AD-08` | Dữ liệu là riêng tư; nội dung card **MUST NOT** xuất hiện trong log ở bất kỳ level nào |
| `AD-09` | Reset learning progress **tăng `generation`**; review ghi từ session mang `generation` cũ MUST bị từ chối, không bao giờ được áp |
| `AD-10` | Cây deck nhiều cấp, tối đa 10 cấp; `root_id` được **lưu**, không suy ra bằng `COALESCE(parent_id, id)`; `content_type` là `unset` \| `card` \| `deck` |
| `AD-11` | Trạng thái là dữ liệu **được lưu tường minh**, không suy luận — `kind`, `status`, `end_reason` đều được ghi |
| `AD-16` | "Đầu ngày học" và offset múi giờ do composition root cấp; scheduler trả **số ngày**, không trả thời điểm; MUST NOT đọc đồng hồ trực tiếp |
| `AD-20` | Card Transfer dùng **sáu field nội dung canonical** chung (`front · back · example · note · hint · source`), thứ tự cố định, header chữ thường tiếng Anh |
| `AD-21` | Nhắc học chạy trong **background worker**, không phải notification đặt sẵn |
| `AD-22` | Trash là **tombstone một cột trên hàng**, batch là bảng riêng; loại trừ tombstone là hợp đồng của mọi query đọc |

`AD-01`, `AD-03`, `AD-04`, `AD-05` are platform decisions stated in `product.md` — delete the citation without restating.

- [ ] **Step 3: Remove the 36 task IDs and the `lib/` path**

Scenario files cite task IDs to say which V7 milestone a scenario landed in. That is V7 history; delete the parenthetical, keep the scenario.

- [ ] **Step 4: Update the seven-line headers**

Same form as Task 3 across all 17 files.

- [ ] **Step 5: Run the gate**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py docs/it-scenarios/*.md; echo "exit=$?"
```

Expected: `exit=0`, `PASS`.

- [ ] **Step 6: Commit**

```bash
cd /d/workspace/memox-v8
git add docs/it-scenarios
git commit -m "docs: scrub V7 references from IT scenarios

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Rewrite `docs/README.md` as the V8 index

**Files:**
- Modify: `docs/README.md` — currently indexes 11 top-level documents and 5 subdirectories, most of them deleted
- Test: `python tools/check_docs_refs.py docs/README.md`, plus the link-resolution check below

**Interfaces:**
- Consumes: the final keep-set from Tasks 1–6
- Produces: the entry point a reader lands on; it must name every surviving document and nothing else

- [ ] **Step 1: List what actually survives**

```bash
cd /d/workspace/memox-v8
git ls-files docs | sort
```

Use this output as the index's contents — not the old table.

- [ ] **Step 2: Rewrite the index**

Keep the seven-line header form. The `What exists` table lists exactly: `document-conventions.md`, `product.md`, `use-cases.md`, `master-flow.md`, `business-rules.md` (+ `business-rules/study-mode.md`), `data-model.md`, `it-scenarios/`, and the two V8 documents under `superpowers/`.

Delete outright: the `wbs.md` / `wbs-study.md` / `wbs-archive/` / `architecture.md` / `checklist.md` rows, the `wireframes/` `reviews/` `claude-design/` table, the `design-system/` table, the `Not written yet` table naming four `flutter-*` skills, and the sentence about `check_docs.py`'s scan scope.

Keep and restate in V8 terms: the "ID là vĩnh viễn" paragraph (BR/UC/invariant numbers are permanent) and the closing rule that documents and code are updated in the same commit.

Add one row for the gate:

```markdown
| [`../tools/check_docs_refs.py`](../tools/check_docs_refs.py) | Gate: không tài liệu nào được trích dẫn thứ đã bị xoá; BR/UC/invariant được trích dẫn phải phân giải được | active |
```

- [ ] **Step 3: Verify every link in the README resolves**

```bash
cd /d/workspace/memox-v8/docs
grep -oE '\]\(([^)#]+)' README.md | sed 's/](//' | while read -r p; do
  [ -e "$p" ] || echo "DANGLING: $p"
done
```

Expected: no output.

- [ ] **Step 4: Run the gate on the whole keep-set**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py; echo "exit=$?"
```

Expected: `exit=1` still, with problems **only** in `docs/data-model.md` — every other file is done. If any other file reports, that task's scrub was incomplete; fix it there, not here.

- [ ] **Step 5: Commit**

```bash
cd /d/workspace/memox-v8
git add docs/README.md
git commit -m "docs: rewrite the index for the V8 document set

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: Upgrade `data-model.md` to V8's data model

The one content task. The V8 spec's §5 table names five tables and stops; `data-model.md` carries eleven tables, the query-checkable invariants, and the reasoning behind the session-queue design. The decision taken on 2026-09-23 is that **`data-model.md` is right and the spec is thin** — so this document becomes V8's data-model authority, updated to V8's naming and decisions, not replaced by the spec's summary.

**Files:**
- Modify: `docs/data-model.md` (967 lines; 20 AD, 20 task IDs, 4 `lib/` paths)
- Test: `python tools/check_docs_refs.py docs/data-model.md`, plus the invariant-numbering check below

**Interfaces:**
- Consumes: the `invariant Q<n>` citations written by Task 4 — every one must still resolve after this rewrite
- Produces: the V8 table and column names that later V8 implementation plans build against

- [ ] **Step 1: Record the current invariant numbering before touching anything**

```bash
cd /d/workspace/memox-v8
grep -oE "^-- [0-9]+\." docs/data-model.md | grep -oE "[0-9]+" | sort -n | tr '\n' ' '
```

Keep this list. Step 7 compares against it. **No invariant may be renumbered, reordered out of its number, or dropped** — Task 4 wrote citations against these numbers.

- [ ] **Step 2: Apply the V8 table names from the spec**

The spec chose singular table names and moved schedule out of the card. Rename throughout, including inside every SQL invariant:

| V7 | V8 | Note |
|---|---|---|
| `decks` | `deck` | `parent_deck_id` → `parent_id`, `root_deck_id` → `root_id` |
| `cards` | `card` | content only — no SRS columns |
| `card_study_states` | `card_schedule` | box, or ease/interval; `due_at`; `generation` |
| `study_answers` | `review_log` | append-only; `kind` stored, never inferred |
| `study_sessions` | `study_session` | `status` and `end_reason` stored, never inferred |

- [ ] **Step 3: Keep the tables the spec omits, marked by scope**

`study_queue_items`, `app_settings`, `tags` + `card_tags`, `deck_templates` and `delete_batches` are absent from the spec's five-table summary. They are not wrong — they are what the spec is missing. Keep each, with a scope line naming when it lands:

```markdown
**Phạm vi:** V8.0 — hàng đợi phiên học.
**Phạm vi:** sub-project sau — Tags. Bảng giữ ở đây để nghiệp vụ không phải đào lại.
```

`study_queue_items` and `app_settings` are V8.0. `tags`, `card_tags`, `deck_templates` and `delete_batches` belong to later sub-projects.

- [ ] **Step 4: Delete V7 migration history and V7 source references**

Remove the `Thứ tự migration dự kiến` section and every `schema v<n>` claim: V8 designs its own schema from scratch and has no migration path from V7 (spec §1). Remove the 4 `lib/core/database/` paths, the 20 AD citations (Task 4 rule), and the 20 task IDs.

- [ ] **Step 5: Rewrite the header**

```markdown
| **Status** | active |
| **Purpose** | Chốt hình dạng dữ liệu V8 và các bất biến phải luôn đúng |
| **Scope** | Bảng, cột, index, quan hệ, query bất biến. Ngoài phạm vi: SQL runtime |
| **Source of truth for** | Schema V8 · cột và kiểu · index · query bất biến |
| **Depends on** | `document-conventions.md`, `business-rules.md` |
| **Updated by** | `docs/superpowers/plans/2026-09-23-docs-v8-reset.md` — nâng lên data model V8 |
| **Last updated** | 2026-09-23 |
```

Add one line under it recording that this document, not the foundation spec's §5 summary, is the V8 data-model authority.

- [ ] **Step 6: Run the gate**

```bash
cd /d/workspace/memox-v8
python tools/check_docs_refs.py; echo "exit=$?"
```

Expected: `exit=0`, `PASS` — the whole keep-set, every file.

- [ ] **Step 7: Verify the invariant numbering survived**

```bash
cd /d/workspace/memox-v8
grep -oE "^-- [0-9]+\." docs/data-model.md | grep -oE "[0-9]+" | sort -n | tr '\n' ' '
```

Expected: byte-identical to Step 1's list. A different list means Task 4's `invariant Q<n>` citations now point somewhere else — the gate catches a *missing* number but not a *shifted meaning*, so this comparison is the only check for it.

- [ ] **Step 8: Commit**

```bash
cd /d/workspace/memox-v8
git add docs/data-model.md
git commit -m "docs: upgrade the data model to V8

V8 table names and the stored root_id/generation/kind decisions applied. The
tables the foundation spec omits are kept and marked by scope. V7 migration
history removed — V8 has no migration path from V7. Invariant numbering is
unchanged.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```
