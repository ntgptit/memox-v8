# Linear Issue Templates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One repo-owned reference file holds the templates and checklists for
creating, reading, updating and closing MemoX issues on Linear; the rule files
point to it, and the owner mirrors the four issue templates in the Linear UI.

**Architecture:** Documentation only. A new reference of the `flutter-workflow`
skill is the source of truth; ADR-021, `CLAUDE.md` and `flutter-workflow/SKILL.md`
each gain a pointer; the Linear UI copy is created by the owner and checked
through the Linear MCP.

**Tech Stack:** Markdown, the repo docs guard (`tools/docs/check.py`), the gate
(`dod_check.sh`), the Linear MCP (`list_templates`, `get_template`, `save_issue`).

**Spec:** `docs/superpowers/specs/2026-10-05-linear-issue-templates-design.md`

**Epic:** DEV-161 "Template issue Linear" (no milestone: infrastructure).

## Global Constraints

- The repo file wins over the Linear UI mirror when they disagree (spec §2).
- Issue titles: Vietnamese, sentence case, verb first, about 70 characters at most, no legacy WBS code, no `DEV-n`, no trailing period (spec §3.2).
- Sub-issue labels: exactly one `WBS` label (`BE`, `FE`, `Supabase`) plus exactly one kind label (`Feature`, `Bug`, `Improvement`) (spec §3.3).
- Priority is always set; Medium by default (spec §3.1).
- Issue bodies and comments are Vietnamese; the reference's own prose is English, like the other `flutter-workflow` references.
- No issue is ever deleted (spec §6).
- Branch and PR name `DEV-161` or the sub-issue's `DEV-n`.

## Review Focus

- A sub-issue created with only its `WBS` label and no kind label: the reference's checklist must list the kind label as required, and `CLAUDE.md` must say so too (Task 2, step 3 checks both).
- A session that reads only `CLAUDE.md`: the "Create" and "Update" bullets must point to the reference, or the templates are never found (Task 2, step 3).
- A template passed to `save_issue` together with a `description`: the reference must say the description replaces the template body (Task 1, step 2 content; step 4 grep).
- A PR link Linear rewrites to `memox-v6`: the Done template must use "pull request số n của `ntgptit/memox-v8`", never `#n` (Task 1, step 4 grep).
- Templates edited in the repo but not in Linear: the reference must tell the PR to say the mirror needs updating (Task 1, step 4 grep).

---

### Task 1: The reference file

Sub-issue: Chore/Docs, label `Improvement` + `BE` (agent tooling and docs, as DEV-85).

**Files:**
- Create: `.claude/skills/flutter-workflow/references/linear-templates.md`

**Interfaces:**
- Produces: the path `.claude/skills/flutter-workflow/references/linear-templates.md` and its section names `Create`, `Read`, `Update`, `Close`, `Linear UI mirror`, which Task 2 links to.

- [ ] **Step 1: Confirm the file does not exist yet**

Run: `test ! -e .claude/skills/flutter-workflow/references/linear-templates.md && echo absent`
Expected: `absent`

- [ ] **Step 2: Write the file**

Content, verbatim:

````markdown
# Linear issue templates

The shape of every MemoX issue and comment on Linear (project MemoX, team
DevelopmentTool, key `DEV`). [ADR-021](../../../../docs/shared/decisions/ADR-021-linear-theo-doi-tien-do.md)
fixes the structure; this file fixes the content. Read it before any Linear
write. Design: [the spec](../../../../docs/superpowers/specs/2026-10-05-linear-issue-templates-design.md).

The owner keeps a copy of the four issue templates in the Linear UI
([Linear UI mirror](#linear-ui-mirror)). This file wins when they disagree; a PR
that changes a template says in its body that the mirror needs updating.

## Create

### Fields

| Field | Epic | Sub-issue |
|---|---|---|
| Team | DevelopmentTool | DevelopmentTool |
| Project | MemoX | MemoX |
| Parent | none | exactly one epic (`parentId`); never a sub-issue |
| Milestone | `V8.0`, `Sau V8.0`, `Sync & tài khoản`, or none for infrastructure | the epic's |
| Labels | `Epic` only | one `WBS` label (`BE`, `FE`, `Supabase`) and one kind label |
| Priority | always set | always set; Medium unless the work says otherwise |
| State | Todo | Todo, or Backlog when blocked or waiting on the owner (reason in the description) |
| Links | spec and plan once they exist | PR once it opens |

Priority is the order of work (ADR-021), so it is never left empty.

### Title

- Vietnamese, sentence case, starting with a verb ("Viết…", "Sửa…", "Thêm…").
- About 70 characters at most; detail goes in the description.
- No legacy WBS code, no `DEV-n`, no trailing period.
- An epic's title names its feature or theme, not an action ("Học và SRS").

### Kind of sub-issue

| Kind | Label | Use for |
|---|---|---|
| Task | `Feature` | one task of a plan, or new behaviour backed by a BR/UC |
| Bug | `Bug` | behaviour that contradicts a BR, UC, `DESIGN.md` or a test |
| Chore/Docs | `Improvement` | documentation, tooling, clean-up, test infrastructure |

The `WBS` label says which layer; the kind label says what sort of work.

### Before saving

1. Search the project with `list_issues` and a `query`; never duplicate.
2. Pick the nearest existing epic. A new epic is opened only for a new
   feature or spec, once the owner approves the spec.
3. A small defect found along the way goes into the issue in hand first.

### Description templates

Bodies are Markdown in Vietnamese; paths are repo-relative in backticks. A
section with nothing to say is deleted, not left empty, except
**Điều kiện xong**, which every issue has.

**Epic**

```markdown
## Mục tiêu
<một hai câu: tính năng hoặc chủ đề này mang lại gì>

## Phạm vi
- Trong: <…>
- Ngoài: <…>

## Tài liệu
- Spec: `docs/superpowers/specs/<…>.md`
- Plan: `docs/superpowers/plans/<…>.md`
- ADR, BR/UC: <…>

## Điều kiện xong
- Mọi sub-issue Done hoặc Canceled.
- <tiêu chí riêng của epic, nếu có>
```

**Task**

```markdown
## Việc cần làm
<làm gì, ở đâu; một đoạn ngắn>

## Căn cứ
- BR/UC: <BR-…, UC-…>
- Plan: `docs/superpowers/plans/<…>.md`, task <n>
- Màn hình: `docs/shared/ui/screen-handoff/<…>.md`

## Điều kiện xong
- [ ] <tiêu chí chấp nhận 1>
- [ ] <tiêu chí chấp nhận 2>
- [ ] `dod_check.sh` PASS
- [ ] Golden đã qua golden review (khi đổi UI)

## Ghi chú
<chọn epic hay label không hiển nhiên thì ghi lý do ở đây>
```

**Bug**

```markdown
## Hiện tượng
<một câu: sai ở đâu>

## Tái hiện
1. <bước>
2. <bước>
- Môi trường: <thiết bị/emulator, Android x, commit `abc1234`>

## Kỳ vọng
<theo BR/UC/DESIGN.md nào>

## Thực tế
<điều xảy ra>

## Bằng chứng
- <log, ảnh, `file:line`, test đang fail>

## Điều kiện xong
- [ ] Có test hồi quy fail trước khi sửa, pass sau khi sửa
- [ ] `dod_check.sh` PASS
```

**Chore/Docs**

```markdown
## Việc cần làm
<làm gì>

## Bằng chứng
- `<đường dẫn>`: <vì sao cần làm>

## Điều kiện xong
- [ ] <kết quả kiểm được, ví dụ `python3 tools/docs/check.py` PASS>
```

## Read

- Before starting work: the open sub-issues of the relevant epic (Todo,
  In Progress, Backlog), ordered by priority.
- Before writing: `get_issue` on the issue, so a comment or edit builds on
  its current state.

## Update

Once the branch and PR name the `DEV-n`, Linear's GitHub integration sets In
Progress, then In Review, then Done on merge. Set a state by hand only when no
PR drives it: Backlog when blocked, Canceled, Duplicate. Every update below is
a comment; edit the description only to correct it, never to log progress.

**Done** (after the merge into `master`)

```markdown
Done: đã merge vào `master`.

- PR: pull request số <n> của `ntgptit/memox-v8`
- Merge commit: `<sha7>`
- Kiểm chứng:
  - `dod_check.sh`: <kết quả, số test>
  - <test riêng, `run_auth_it.sh`, `check.py`…>
  - Golden review: <link trang review, hoặc "không đổi golden">
- Bị cắt: <phần, lý do> (bỏ dòng nếu không có)
- Làm sau: DEV-<n>, DEV-<m> (bỏ dòng nếu không có)
```

**Bị chặn** (state Backlog)

```markdown
Bị chặn: <nguyên nhân>.

- Cần: <điều gì, từ ai>
- Đã thử: <…> (bỏ dòng nếu không có)
```

**Câu hỏi mở**

```markdown
Câu hỏi: <câu hỏi>

- A: <phương án>
- B: <phương án>
- Đề xuất: <A hoặc B, vì sao>
```

- Record the owner's answer as a reply on the same thread.
- After saving, check any PR link Linear made. If `#n` points at `memox-v6`,
  rewrite it as "pull request số n của `ntgptit/memox-v8`", without `#`.

## Close

An issue is never deleted.

**Canceled**: only on the owner's decision, asked through `AskUserQuestion`.

```markdown
Canceled theo quyết định của chủ dự án ngày <yyyy-mm-dd>: <lý do>.
```

**Duplicate**: set `duplicateOf`, then comment:

```markdown
Trùng với DEV-<n>: <một dòng vì sao>.
```

## Linear UI mirror

Four issue templates in team DevelopmentTool (Settings › Templates), each body
copied from [Description templates](#description-templates):

| Template | Default labels | Default state | Body |
|---|---|---|---|
| MemoX · Epic | `Epic` | Todo | Epic |
| MemoX · Task | `Feature` | Todo | Task |
| MemoX · Bug | `Bug` | Todo | Bug |
| MemoX · Chore | `Improvement` | Todo | Chore/Docs |

- The `WBS` label, parent and milestone are chosen per issue; the templates
  leave them blank.
- An agent may pass `template` to `save_issue` to get the default labels, but
  still writes the full `description`: a description passed with a template
  replaces the template body.
````

- [ ] **Step 3: Run the docs guard**

Run: `python3 tools/docs/generate.py >/dev/null && python3 tools/docs/check.py 2>&1 | tail -1`
Expected: `PASS — 0 error(s), 29 warning(s)` (the 29 warnings are the existing unused-BR ones, DEV-149).

- [ ] **Step 4: Check the Review Focus lines are in the file**

Run:
```bash
f=.claude/skills/flutter-workflow/references/linear-templates.md
grep -c "one kind label" "$f"
grep -c "replaces the template body" "$f"
grep -c "pull request số <n> của \`ntgptit/memox-v8\`" "$f"
grep -c "mirror needs updating" "$f"
```
Expected: every count is `1` or more.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/flutter-workflow/references/linear-templates.md
git commit -m "docs(skill): DEV-<n> Linear issue templates reference"
```

---

### Task 2: Point the rule files at the reference

Sub-issue: Chore/Docs, label `Improvement` + `BE`.

**Files:**
- Modify: `docs/shared/decisions/ADR-021-linear-theo-doi-tien-do.md` (section `## Quyết định`, after the bullet that starts "- Issue mới chỉ dùng mã `DEV-n`")
- Modify: `CLAUDE.md` (section `## Progress on Linear`, bullets **Create** and **Update**)
- Modify: `.claude/skills/flutter-workflow/SKILL.md` (section `## Keeping the ledger honest`, second paragraph)

**Interfaces:**
- Consumes: `.claude/skills/flutter-workflow/references/linear-templates.md` from Task 1.

- [ ] **Step 1: ADR-021 gains one decision bullet**

Insert after the bullet "- Issue mới chỉ dùng mã `DEV-n` …" (it ends with "Nhánh và PR nhắc `DEV-n` để Linear tự liên kết."):

```markdown
- Nội dung issue và comment theo các template trong
  `.claude/skills/flutter-workflow/references/linear-templates.md`: bốn loại
  issue (Epic; sub-issue Task, Bug, Chore/Docs, mang thêm đúng một label loại
  `Feature`, `Bug` hoặc `Improvement` ngoài label `WBS`), mẫu comment khi Done,
  bị chặn, có câu hỏi, Canceled và Duplicate. Bốn template cùng tên có trong
  Linear UI là bản sao; khi lệch thì file trong repo thắng.
```

- [ ] **Step 2: CLAUDE.md**

In **Create**, replace the bullet

```markdown
  - New work is a sub-issue of an existing epic: team, project, `parentId`,
    the epic's milestone, one `WBS` label, a plain title named by its `DEV-n`
    only.
```

with

```markdown
  - New work is a sub-issue of an existing epic: team, project, `parentId`,
    the epic's milestone, one `WBS` label, one kind label (`Feature`, `Bug`
    or `Improvement`), a plain title named by its `DEV-n` only.
  - Titles, descriptions and comments follow
    [linear-templates.md](.claude/skills/flutter-workflow/references/linear-templates.md).
```

- [ ] **Step 3: Check CLAUDE.md now names the kind label and the reference**

Run:
```bash
grep -c "one kind label" CLAUDE.md
grep -c "references/linear-templates.md" CLAUDE.md
```
Expected: `1` and `1`.

- [ ] **Step 4: flutter-workflow/SKILL.md**

In `## Keeping the ledger honest`, second paragraph, replace

```markdown
New work is a sub-issue of an existing epic, with its `WBS` label and the epic's milestone, named by its `DEV-n` only.
```

(the sentence is wrapped across lines in the file; match it as wrapped) with

```markdown
New work is a sub-issue of an existing epic, with its `WBS` label, a kind label
and the epic's milestone, named by its `DEV-n` only; its title, description and
comments follow [`references/linear-templates.md`](references/linear-templates.md).
```

- [ ] **Step 5: Run the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: every mechanical gate PASS and the full suite passes. Docs-only
change: no golden run is needed.

- [ ] **Step 6: Commit**

```bash
git add docs/shared/decisions/ADR-021-linear-theo-doi-tien-do.md CLAUDE.md .claude/skills/flutter-workflow/SKILL.md
git commit -m "docs: DEV-<n> rule files point to the Linear templates"
```

---

### Task 3: The Linear UI mirror

Sub-issue: Chore/Docs, label `Improvement` + `BE`. The owner does the UI part;
the MCP cannot create templates.

**Files:** none.

**Interfaces:**
- Consumes: the "Linear UI mirror" section of the reference (Task 1).

- [ ] **Step 1: Ask the owner to create the four templates**

Through `AskUserQuestion`, give the owner the table of the "Linear UI mirror"
section and ask them to create the four templates in Settings › Templates of
team DevelopmentTool, bodies copied from the reference on `master`.

- [ ] **Step 2: Check them through the MCP**

Run `list_templates` with `team: DevelopmentTool`, then `get_template` on each
of "MemoX · Epic", "MemoX · Task", "MemoX · Bug", "MemoX · Chore".
Expected: four templates; each default label as in the table; each body equal
to the matching template in the reference.

- [ ] **Step 3: Record the result**

Comment on the sub-issue with the Done template, "Kiểm chứng" listing the four
template names and that their bodies match the reference.

---

## Execution notes

- Before Task 1, the three sub-issues of DEV-161 are created from the spec's
  §3.4 Chore/Docs template (the same text Task 1 writes), so the branch and
  commits can name their `DEV-n`; reading them back with `get_issue` is the
  spec's §9 check. Replace `DEV-<n>` in the commit messages with the task's id.
- Tasks 1 and 2 go in one PR; Task 3 starts after it merges, so the owner
  copies from `master`.
