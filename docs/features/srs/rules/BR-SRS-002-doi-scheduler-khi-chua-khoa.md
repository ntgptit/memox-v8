---
id: BR-SRS-002
title: Đổi scheduler khi chưa khoá
status: active
summary: Scheduler, version và config đổi trực tiếp được khi `first_answered_at IS NULL`, không đi qua Reset.
superseded_by:
---
## Rule

Scheduler, version và config MAY đổi trực tiếp chừng nào root deck chưa có lượt học nào ở generation hiện tại (`first_answered_at IS NULL`). Đây là thao tác **riêng**, MUST NOT đi qua Reset: `generation` MUST giữ nguyên (UC-DECK-002). Điều kiện mở khoá MUST được đọc lại bên trong transaction ghi, không tin trạng thái màn hình. Chọn đúng scheduler deck đang chạy MUST là no-op: MUST NOT seed lại cây (BR-SRS-004) và MUST NOT đóng session đang mở (BR-STUDY-016).

**Enforced by:** store
**Liên quan:** BR-SRS-004, BR-STUDY-016

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
