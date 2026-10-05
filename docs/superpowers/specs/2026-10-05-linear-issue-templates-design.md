# Linear issue templates

Status: draft 2026-10-05, design approved by the owner in chat; awaiting
review of this spec. Extends
[ADR-021](../../shared/decisions/ADR-021-linear-theo-doi-tien-do.md), which
fixes the *structure* of the Linear project MemoX (two levels, `WBS` labels,
milestones, states) but not what an issue *says*.

## 1. Intent

- **Goal:** every create, read, update and close of a MemoX issue follows one
  written shape, whoever does it: a Claude session through the Linear MCP or
  the owner in the Linear UI.
- **Problem today:** no template exists in Linear (team DevelopmentTool has
  none). The 128 migrated issues (DEV-6…DEV-133) carry their whole content in
  a long title ("BE-A4 · …"); DEV-149…DEV-154 use an ad-hoc *Việc cần làm /
  Bằng chứng / Điều kiện xong* shape that nothing records. Done comments, block
  comments and cancel reasons are written freehand.
- **Success:**
  - one reference file holds every template and the per-field checklist;
  - a session creating an issue needs no other source to fill it correctly;
  - the owner can pick the same four templates in the Linear UI.
- **Owner rulings (2026-10-05):**
  - templates serve both agents and the owner;
  - sub-issues come in three kinds, Task, Bug and Chore/Docs, each with its
    own template.

## 2. Where the templates live

| Copy | Role |
|---|---|
| `.claude/skills/flutter-workflow/references/linear-templates.md` | **Source of truth.** Agents read it before any Linear write. |
| Four issue templates in Linear, team DevelopmentTool | A mirror for the owner, created by hand from the file. The Linear MCP can read and apply templates, not create them. |

- If the two copies disagree, the repo wins. A PR that changes a template
  says in its body that the Linear mirror must be updated; the owner does it.
- ADR-021 gains one decision line pointing to the file. `CLAUDE.md`
  ("Progress on Linear") and `flutter-workflow/SKILL.md` gain one pointer each.
- Rejected:
  - **an ADR-022 holding the templates:** templates are procedure, not a
    decision, and wording fixes would churn an ADR;
  - **a `docs/agent/linear/` folder:** a new knowledge store, against
    `CLAUDE.md` "Where knowledge lives".

## 3. Create

### 3.1 Field checklist

| Field | Epic | Sub-issue |
|---|---|---|
| Team | DevelopmentTool | DevelopmentTool |
| Project | MemoX | MemoX |
| Parent | none | exactly one epic (`parentId`); never a sub-issue |
| Milestone | `V8.0`, `Sau V8.0`, `Sync & tài khoản`, or none for infrastructure | the epic's |
| Labels | `Epic` only | one `WBS` label (`BE`, `FE`, `Supabase`) and one kind label (§3.3) |
| Priority | always set | always set; Medium unless the work says otherwise |
| State | Todo | Todo, or Backlog when blocked or waiting on the owner (reason in the description) |
| Links | spec and plan once they exist | PR once it opens |

Priority is always set because ADR-021 makes it the order of work.

### 3.2 Title

- Vietnamese, sentence case, starting with a verb ("Viết…", "Sửa…", "Thêm…").
- About 70 characters at most; detail goes in the description.
- No legacy WBS code, no `DEV-n`, no trailing period.
- An epic's title names its feature or theme, not an action ("Học và SRS").

### 3.3 Kinds of sub-issue

| Kind | Label | Use for |
|---|---|---|
| Task | `Feature` | one task of a plan, or new behaviour backed by a BR/UC |
| Bug | `Bug` | behaviour that contradicts a BR, UC, `DESIGN.md` or a test |
| Chore/Docs | `Improvement` | documentation, tooling, clean-up, test infrastructure |

These three labels already exist in the workspace and are unused. The `WBS`
label still says *which layer*; the kind label says *what sort of work*.

### 3.4 Description templates

All bodies are Markdown in Vietnamese. Paths are repo-relative in backticks.
A section with nothing to say is deleted, not left empty, except
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

### 3.5 Before creating

1. Search the project with `list_issues` and a `query`; never duplicate.
2. Pick the nearest existing epic. A new epic is opened only for a new
   feature or spec, after the owner approves the spec (ADR-021).
3. A small defect found along the way goes into the issue in hand first.

## 4. Read

- Before starting work: the open sub-issues of the relevant epic (Todo,
  In Progress, Backlog), ordered by priority.
- Before writing: `get_issue` on the issue, so a comment or edit builds on
  its current state.

## 5. Update

States move by themselves once the branch and PR name the `DEV-n`: Linear's
GitHub integration sets In Progress, then In Review, then Done on merge
(seen on DEV-154). A session sets a state by hand only when no PR drives it
(Backlog when blocked, Canceled, Duplicate). Every update below is a comment;
the description is edited only to correct it, never to log progress.

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

- The owner's answer is recorded as a reply on the same thread.
- After saving, check any PR link Linear made; if `#n` points at `memox-v6`,
  rewrite it as "pull request số n của `ntgptit/memox-v8`" (ADR-021).

## 6. Delete

An issue is never deleted.

**Canceled** (only on the owner's decision, asked through `AskUserQuestion`)

```markdown
Canceled theo quyết định của chủ dự án ngày <yyyy-mm-dd>: <lý do>.
```

**Duplicate**: set `duplicateOf`, then comment:

```markdown
Trùng với DEV-<n>: <một dòng vì sao>.
```

## 7. Linear UI mirror

The owner creates four issue templates in team DevelopmentTool, Settings ›
Templates:

| Template | Default labels | Default state | Body |
|---|---|---|---|
| MemoX · Epic | `Epic` | Todo | §3.4 Epic |
| MemoX · Task | `Feature` | Todo | §3.4 Task |
| MemoX · Bug | `Bug` | Todo | §3.4 Bug |
| MemoX · Chore | `Improvement` | Todo | §3.4 Chore/Docs |

- The `WBS` label, parent and milestone are chosen per issue, so the
  templates leave them blank.
- Agents may pass `template` to `save_issue` to get the default labels, but
  must still write the full `description`: a description passed with a
  template replaces the template body.

## 8. Out of scope

- Rewriting DEV-6…DEV-133: they are migrated history.
- DEV-149…DEV-154 are close enough to the new shape and stay as they are.
- A mechanical check: the gate cannot reach Linear (ADR-021).
- Project, document and status-update templates.

## 9. Verification

- `python3 tools/docs/generate.py` then `python3 tools/docs/check.py`: PASS,
  0 errors.
- `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`: PASS.
- The sub-issues of this spec's own epic are created from the templates
  through the MCP and read back with `get_issue`: labels, milestone, parent
  and body as §3 says. No throwaway test issue is created.
