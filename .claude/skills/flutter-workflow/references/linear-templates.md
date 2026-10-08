# Linear issue templates

The shape of every MemoX issue and comment on Linear (project MemoX, team
DevelopmentTool, key `DEV`). [ADR-021](../../../../docs/shared/decisions/ADR-021-linear-theo-doi-tien-do.md)
fixes the structure; this file fixes the content. Read it before any Linear
write. Design: [the spec](../../../../docs/superpowers/specs/2026-10-05-linear-issue-templates-design.md).

The owner keeps a copy of the four issue templates in the Linear UI
([Linear UI mirror](#linear-ui-mirror)). This file wins when they disagree; a PR
that changes a template says in its body that the mirror needs updating.

## Language

Titles, descriptions and comments are written in Vietnamese, with Vietnamese
sentence structure; never a whole sentence in English. Common IT terms stay as
they are and are not translated:

- process and tools: PR, commit, merge, branch, review, test, golden,
  emulator, log, label, epic, sub-issue, spec, plan;
- Linear state names: Todo, In Progress, In Review, Done, Canceled, Backlog,
  Duplicate;
- identifiers: file names, paths, `DEV-n`, BR/UC/ADR codes, commands.

For example "Sửa test golden của màn 07 sau khi merge PR", not "Sửa kiểm thử
ảnh mẫu…" and not "Fix the golden test of screen 07".

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
| Chore/Docs | `Improvement` | an improvement to existing behaviour or UI, documentation, tooling, clean-up, test infrastructure |

The `WBS` label says which layer; the kind label says what sort of work.

### Before saving

1. Search the project with `list_issues` and a `query`; never duplicate.
2. Pick the nearest existing epic. A new epic is opened only for a new
   feature or spec, once the owner approves the spec.
3. A small defect found along the way goes into the issue in hand first.
4. Never open a coordination issue: no execution group over other issues and
   no `[REF]` pointer to one. Progress lives on the issue itself, and a
   finding along the way is a comment on it (owner's ruling 2026-10-07: the
   free plan caps the workspace at 250 unarchived issues, and that layer used
   42 of them).

### Description templates

Bodies are Markdown, in the language of [Language](#language); paths are
repo-relative in backticks. A
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

Sections I to V are the owner's minimum (2026-10-08, DEV-315) and are never
dropped; a section that cannot be filled yet says why. They are filled as the
work goes, in this order, and section V closes the issue. "Check non degrade"
is CLAUDE.md's check degrade.

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

## I. Phân tích nguyên nhân
<qua `superpowers:systematic-debugging`; chưa chứng minh thì ghi "chưa rõ",
những gì đã loại trừ và giả thuyết còn lại>
1. Nguyên nhân trực tiếp: <dòng code, giá trị hay sự kiện trực tiếp gây ra
   triệu chứng, ở `file:line`>
2. Nguyên nhân cốt lõi: <vì sao nguyên nhân trực tiếp tồn tại được: hợp đồng
   hoặc invariant nào bị vi phạm, chủ sở hữu dùng chung nào thiếu gì; nó giải
   thích những triệu chứng nào>

## II. Check similar
1. Quan điểm define đối tượng check: <cơ chế làm tiêu chí (pattern, lời gọi,
   cách dùng sai) và vì sao chọn nó, không theo triệu chứng>
2. Đối tượng check: <phạm vi đã quét (thư mục, symbol, widget, query, RPC) và
   cách tìm, theo symbol và theo hành vi>
3. Nội dung check: <với mỗi đối tượng, kiểm điều gì để biết có cùng gốc>
4. Kết quả check:

| Chỗ | Loại | Xử lý |
|---|---|---|
| `<file:line>` | cùng gốc / giống nhưng không bị / đáng ngờ, đã kiểm / không liên quan | sửa trong PR này / DEV-<n> / không cần |

## III. Corrective action
- Chỗ sửa: <chủ sở hữu dùng chung thấp nhất; nếu sửa cục bộ thì vì sao tầng
  dùng chung không phải chủ sở hữu>
- Thay đổi: <sửa gì và vì sao nó loại bỏ nguyên nhân cốt lõi>
- Test hồi quy: <test nào; fail trước khi sửa, pass sau khi sửa>

## IV. Check non degrade
- Nơi dùng phần đã đổi: <caller, màn hình, widget, query, RPC>
- Bằng chứng: <test của từng nơi, `dod_check.sh`, goldens khi đổi UI>
- Kết quả: <không có hồi quy; không test nào bị làm yếu hay xoá>
- Chạy lại: <có/không; sửa thêm sau khi check thì chạy lại cả II và IV>

## V. Output
- PR, commit: <pull request số n của `ntgptit/memox-v8`, `<sha7>`>
- Kiểm chứng: <`dod_check.sh` và số test, test riêng, golden review>
- Trạng thái cuối: <`VERIFIED` / `BLOCKED` / `UNRESOLVED`, kèm lý do nếu không
  phải `VERIFIED`>
- Rủi ro còn lại: <hoặc "không có">

## Điều kiện xong
- [ ] I: nguyên nhân trực tiếp và cốt lõi đã chứng minh
- [ ] II: mọi chỗ tìm được đã phân loại; chỗ cùng gốc đã sửa, chỗ khác gốc
  đã mở sub-issue
- [ ] III: sửa ở chủ sở hữu dùng chung thấp nhất, có test hồi quy fail trước
  pass sau
- [ ] IV: mọi nơi dùng phần đã đổi vẫn đúng, đã chạy lại nếu sửa thêm
- [ ] V: trạng thái cuối `VERIFIED`, `dod_check.sh` PASS
```

**Chore/Docs**

An improvement carries sections II to V of the Bug template, numbered the same
so that "mục II" means check similar on every issue (owner, 2026-10-08,
DEV-316). It has no section I: the reason for the work is under Bằng chứng.
The sections are never dropped; one that cannot be filled yet says why.

```markdown
## Việc cần làm
<làm gì, ở đâu>

## Bằng chứng
- `<đường dẫn>`: <vì sao cần làm; hiện trạng và kết quả mong muốn>

## II. Check similar
1. Quan điểm define đối tượng check: <điều được cải tiến, dùng làm tiêu chí:
   pattern, component, quy ước; chỗ nào có cùng điều đó thì cần cùng cải tiến>
2. Đối tượng check: <phạm vi đã quét (thư mục, symbol, widget, query, tài
   liệu) và cách tìm, theo symbol và theo hành vi>
3. Nội dung check: <với mỗi đối tượng, kiểm điều gì để biết nó cần cùng cải
   tiến>
4. Kết quả check:

| Chỗ | Loại | Xử lý |
|---|---|---|
| `<file:line>` | cùng vấn đề / giống nhưng không cần / đáng ngờ, đã kiểm / không liên quan | làm trong PR này / DEV-<n> / không cần |

## III. Corrective action
- Chỗ làm: <chủ sở hữu dùng chung thấp nhất; nếu làm cục bộ thì vì sao tầng
  dùng chung không phải chủ sở hữu>
- Thay đổi: <làm gì>
- Test: <test nào chứng minh cải tiến>

## IV. Check non degrade
- Nơi dùng phần đã đổi: <caller, màn hình, widget, query, RPC, tài liệu>
- Bằng chứng: <test của từng nơi, `dod_check.sh`, goldens khi đổi UI>
- Kết quả: <không có hồi quy; không test nào bị làm yếu hay xoá>
- Chạy lại: <có/không; làm thêm sau khi check thì chạy lại cả II và IV>

## V. Output
- PR, commit: <pull request số n của `ntgptit/memox-v8`, `<sha7>`>
- Kiểm chứng: <`dod_check.sh` và số test, test riêng, golden review>
- Trạng thái cuối: <`VERIFIED` / `BLOCKED` / `UNRESOLVED`, kèm lý do nếu không
  phải `VERIFIED`>
- Rủi ro còn lại: <hoặc "không có">

## Điều kiện xong
- [ ] II: mọi chỗ tìm được đã phân loại; chỗ cùng vấn đề đã làm, chỗ khác đã
  mở sub-issue
- [ ] III: làm ở chủ sở hữu dùng chung thấp nhất, có test chứng minh
- [ ] IV: mọi nơi dùng phần đã đổi vẫn đúng, đã chạy lại nếu làm thêm
- [ ] V: trạng thái cuối `VERIFIED`, `dod_check.sh` PASS
- [ ] <kết quả kiểm được riêng của việc này, ví dụ `python3 tools/docs/check.py` PASS>
```

## Read

- Before starting work: the open sub-issues of the relevant epic (Todo,
  In Progress, Backlog), ordered by priority.
- Before writing: `get_issue` on the issue, so a comment or edit builds on
  its current state.

## Update

Once the branch and PR name the `DEV-n`, Linear's GitHub integration sets In
Progress, then In Review, then Done on merge. Set a state by hand only when no
PR drives it: Backlog when blocked, Canceled, Duplicate, and Done for an epic
once every sub-issue is Done or Canceled (an epic has no PR). Every update below
is a comment; edit the description only to correct it, never to log progress.

**Done** (after the merge into `master`). A bug fix or an improvement always
carries the two check lines and the final state (CLAUDE.md, "Fixing bugs and
improving"); only the root-cause line is dropped when the work is not a bug.
The lines point at the description's sections, which hold the detail: I to V
on a bug, II to V on an improvement.
An issue whose state is `BLOCKED` or `UNRESOLVED` is not Done: it stays open
with a Bị chặn comment.

```markdown
Done: đã merge vào `master`.

- PR: pull request số <n> của `ntgptit/memox-v8`
- Merge commit: `<sha7>`
- Kiểm chứng:
  - `dod_check.sh`: <kết quả, số test>
  - <test riêng, `run_auth_it.sh`, `check.py`…>
  - Golden review: <link trang review, hoặc "không đổi golden">
- Nguyên nhân gốc (mục I): <trực tiếp và cốt lõi, `file:line`; bỏ dòng nếu
  không phải bug>
- Check non degrade (mục IV): <những nơi dùng phần đã đổi và bằng chứng mỗi
  nơi vẫn đúng>
- Check similar (mục II): <đã tìm theo cơ chế nào; mỗi chỗ tìm được và loại của nó
  (cùng gốc, giống nhưng không bị, đáng ngờ đã kiểm, không liên quan); chỗ
  cùng gốc đã sửa; chỗ khác gốc thành DEV-<n>; hoặc "không có chỗ nào khác">
- Trạng thái cuối: `VERIFIED`
- Bị cắt: <phần, lý do> (bỏ dòng nếu không có)
- Làm sau: DEV-<n>, DEV-<m> (bỏ dòng nếu không có)
```

**Done của epic** (set by hand, after its last sub-issue closes)

```markdown
Done: mọi sub-issue đã Done hoặc Canceled (DEV-<a>…DEV-<b>).
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

An issue is never deleted. The one exception was the owner's own: the 42
coordination issues (execution groups and `[REF]`, DEV-234…DEV-275), deleted on
2026-10-08 to get back under the free plan's 250-issue cap.

**Epic Done**: once every sub-issue is Done or Canceled, set the epic Done,
then move the epic and all its sub-issues to the project `MemoX · Lưu trữ`
(status Completed) with `save_issue` (`project`). Parent links stay; the
milestone goes with the old project. Linear archives an issue only by itself,
and never while its project is open, so this is what keeps closed work from
counting against the cap.

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
- An agent passes `template` to `save_issue` only if `list_templates` shows it
  for team DevelopmentTool; the mirror may be missing. It always passes
  `labels` explicitly and writes the full `description`: a description passed
  with a template replaces the template body.
