---
id: ADR-021
title: Tiến độ công việc nằm trên Linear, không còn trong file WBS
status: active
superseded_by:
---
## Bối cảnh

Tiến độ được ghi trong ba file `docs/wbs_BE.md`, `docs/wbs_FE.md` và
`docs/wbs_supabase.md` (`docs/wbs_API.md` đã đóng băng theo ADR-015). Đến
2026-10-05 ba file có 130 hạng mục, phần lớn đã `xong`. Mỗi PR phải sửa một dòng
bảng dài, hai file có thể cùng ghi một hạng mục (BE-E1 và BE-E8 có ở cả
`wbs_BE.md` lẫn `wbs_supabase.md`), và việc cần làm tiếp không lọc hay sắp xếp
được. Chủ dự án đã nối Linear với Claude qua MCP.

## Quyết định

- Tiến độ công việc nằm trong project **MemoX** của team **DevelopmentTool**
  (key `DEV`) trên Linear. Mỗi hạng mục là một issue.
- Project có hai cấp issue, không hơn:
  - **Epic**: issue cha mang label `Epic`, gom một tính năng hoặc một chủ đề
    (ví dụ "Học và SRS", "Sync với Supabase"), không mang label `WBS`. Epic
    nằm trong một milestone của project (`V8.0`, `Sau V8.0`, `Sync & tài
    khoản`) hoặc không thuộc milestone nào nếu là hạ tầng.
  - **Hạng mục**: sub-issue của đúng một epic, cùng milestone với epic, mang
    đúng một label của nhóm `WBS`: `BE` (domain, data, use case), `FE`
    (presentation), `Supabase` (sync và login trên Supabase).
- Chống tạo issue tràn lan: việc mới là sub-issue của một epic có sẵn. Chỉ mở
  epic mới khi có một tính năng hay spec mới (một spec, một epic); các task của
  plan cho spec đó là sub-issue của epic, mỗi task một sub-issue, không tách
  bước nhỏ hơn. Lỗi nhỏ phát hiện trong lúc làm đi vào issue đang làm, hoặc
  thành một sub-issue của epic gần nhất. Không tạo sub-issue của sub-issue.
- Epic sang Done khi mọi sub-issue đã Done hoặc Canceled.
- Trạng thái của issue thay cho cột Trạng thái: `xong` → Done (chỉ khi đạt
  Definition of Done và đã merge vào `master`); `đang làm` → In Progress, rồi
  In Review khi có PR; `chưa bắt đầu` → Todo; `bị chặn`, `hoãn`, `tạm dừng` →
  Backlog, lý do ghi trong issue; `cắt` → Canceled, lý do ghi trong issue.
- Thứ tự làm tiếp là priority của issue. Điểm chặn và câu hỏi còn mở là comment
  trên issue đó.
- Issue mới chỉ dùng mã `DEV-n` của Linear. ID cũ (`BE-03`, `FE-A2`, `SB-S8`…)
  chỉ còn ở dòng `Mã WBS cũ` cuối mô tả của 128 issue đã chuyển (DEV-6…DEV-133);
  tìm bằng `list_issues` với mã đó làm query. Đến 2026-10-05 ID cũ nằm ở đầu tiêu
  đề; đợt migrate DEV-165 chuyển nó xuống mô tả. BE-E1 và BE-E8
  có ở hai file, mỗi cái thành một issue mang label `Supabase`. 128 issue này
  được gom vào 15 epic (DEV-134…DEV-148). Nhánh và PR nhắc `DEV-n` để Linear tự
  liên kết.
- Nội dung issue và comment theo các template trong
  `.claude/skills/flutter-workflow/references/linear-templates.md`: bốn loại
  issue (Epic; sub-issue Task, Bug, Chore/Docs, mang thêm đúng một label loại
  `Feature`, `Bug` hoặc `Improvement` ngoài label `WBS`), mẫu comment khi Done,
  bị chặn, có câu hỏi, Canceled và Duplicate. Bốn template cùng tên có trong
  Linear UI là bản sao; khi lệch thì file trong repo thắng.
- Ba file WBS đóng băng ngày 2026-10-05, giữ nguyên làm lịch sử: các spec và plan
  có ngày đều dẫn tới chúng.
- Màn hình vẫn có dòng trong screen handoff index. Quyết định kiến trúc vẫn là
  ADR. Linear chỉ thay cho sổ tiến độ.

## Hệ quả

- Nhánh và PR làm một hạng mục nhắc `DEV-n` của nó: issue ở In Progress rồi In
  Review trong lúc làm (tích hợp GitHub của Linear tự chuyển), sang Done khi PR
  merge, kèm bằng chứng (PR, commit, test) và phần bị cắt kèm lý do. Không còn
  sửa file WBS.
- Agent cần connector Linear để đọc và ghi tiến độ. Session không có connector
  thì báo chủ dự án, không tự ghi tiến độ vào file khác.
- Gate (`dod_check.sh`) không kiểm được Linear. Việc issue có nói đúng sự thật
  hay không vẫn là phần người phải kiểm của Definition of Done.
- Tích hợp GitHub của workspace có thể biến `#n`, kể cả URL đầy đủ của một PR
  trong repo này, thành liên kết tới PR cùng số của repo khác (DEV-66 bị gắn
  sang `memox-v6#157`). Sau khi lưu issue, kiểm lại liên kết; nếu sai, viết
  "pull request số n của `ntgptit/memox-v8`", không có `#`.
- Rollback: bỏ đóng băng ba file WBS và chép trạng thái các issue về lại bảng.
