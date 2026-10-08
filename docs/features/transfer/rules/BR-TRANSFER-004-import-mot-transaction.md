---
id: BR-TRANSFER-004
title: Import trong một transaction
status: active
summary: Một lần import ghi toàn bộ card, study state và tag trong đúng một transaction.
superseded_by:
---
## Rule

Một lần import MUST ghi trong **đúng một** Drift transaction: toàn bộ card, **đúng một** study state mới cho mỗi card theo bảng khởi tạo BR-CARD-004 với scheduler, version và generation đọc từ root **trong chính transaction đó** (mỗi card một lần đọc qua `initializeCard`, cùng savepoint — MUST NOT đọc trước khi transaction mở), tag tạo mới hoặc dùng lại theo tên đã fold (BR-TAG-001), và `content_type` của deck đích. Một write thất bại MUST rollback toàn bộ — không có partial card, state, tag hay content type. Không còn hàng hợp lệ nào để ghi thì MUST NOT có mutation nào. Import MUST NOT mang theo lịch học: không due date, không box, không SM-2 state, không history — card import là card mới. Card của một lần import có cùng `created_at`, nên thứ tự dòng nguồn MUST được giữ qua `id`: id sinh theo thứ tự ghi và tăng dần (ADR-007), để danh sách card (`created_at DESC, id DESC`) và export (BR-TRANSFER-010) phản ánh đúng thứ tự file nguồn.

Với nguồn có dòng sao, cùng **một** transaction đó MUST tạo các deck con theo thứ tự nguồn (BR-DECK-006, vị trí sau các deck con sẵn có) rồi ghi card của từng nhóm; mọi kiểm tra đích MUST chạy xong trước write đầu tiên, và một write lỗi MUST rollback cả deck lẫn card.

**Enforced by:** store
**Liên quan:** BR-CARD-004, BR-TAG-001, BR-CARD-011, BR-TRANSFER-010, ADR-007, BR-TRANSFER-015, BR-DECK-006

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Import mà mọi hàng đều trùng hoặc invalid | Không mutation nào; `content_type` giữ nguyên (BR-TRANSFER-004, BR-TRANSFER-005) |
| Một write giữa batch thất bại | Rollback toàn bộ — không partial card/state/tag (BR-TRANSFER-004) |
| Import nhiều dòng trong một lần | Danh sách card và export giữ đúng thứ tự dòng nguồn (BR-TRANSFER-004, ADR-007) |
