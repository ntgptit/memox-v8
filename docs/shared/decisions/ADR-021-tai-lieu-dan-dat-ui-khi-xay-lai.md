---
id: ADR-021
title: Tài liệu dẫn UI khi xây lại; DESIGN.md và screen spec là chuẩn
status: accepted
supersedes: [ADR-019]
---
## Bối cảnh

ADR-019 đặt app làm chuẩn UI: `DESIGN.md` được sinh từ code, file chi tiết của mỗi màn ghi
lại màn đã build kèm golden. Ngày 2026-10-04 chủ dự án quyết định xoá UI và build lại vì nợ
code ở lớp presentation, giữ nguyên hệ thống hình ảnh và UX, và bỏ toàn bộ golden hiện có
([spec](../../superpowers/specs/2026-10-04-ui-docs-restructure-design.md), R1, R2). Khi code
và golden không còn, chuẩn mà ADR-019 dựa vào cũng mất.

## Quyết định

- Thứ tự ưu tiên: BR, FN và UC > `DESIGN.md` > screen spec (`docs/screens/spec/`) > golden đã
  được chủ dự án duyệt. Golden lệch với spec là lỗi ở một trong hai; chủ dự án quyết bên nào.
- `DESIGN.md` là tài liệu viết tay, không sinh từ code; code theo nó. PR đổi hệ thống hình ảnh
  sửa `DESIGN.md` trước.
- PR đổi một màn sửa screen spec của màn đó và hàng của nó trong
  `docs/screens/SCREEN_CATALOG.md`.
- Artifact "Mobile UI Kit v3" vẫn retired, không được đọc.

## Hệ quả

- ADR-019 giữ nguyên văn với `status: superseded`, `superseded_by: ADR-021`.
- Trạng thái ADR là `draft | accepted | superseded | deprecated`; ADR thay thế ADR khác ghi
  `supersedes`.
- Cấu trúc tài liệu, quan hệ một chiều và thứ tự migration theo spec ở trên.
  `docs/shared/ui/screen-handoff/` chỉ thôi là nơi ghi màn sau khi migration được kiểm chứng
  (spec §7.1).
