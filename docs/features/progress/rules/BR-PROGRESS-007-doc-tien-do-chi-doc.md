---
id: BR-PROGRESS-007
title: Đọc tiến độ là chỉ đọc
status: active
summary: Đọc tiến độ theo deck là chỉ đọc: không ghi, không mở hay đóng session.
superseded_by:
---
## Rule

Đọc tiến độ MUST là thao tác chỉ-đọc: mở, rời hay đổi khoảng trên màn hình MUST NOT ghi hay chạm tới nội dung card, timestamp, `content_type`, study state, review history, session hay quan hệ tag; MUST NOT mở hay đóng session nào. Một lần đọc thất bại vì thế MUST NOT làm hỏng dữ liệu, và copy lỗi MUST NOT gợi ý ngược lại.

**Enforced by:** store + UI
**Liên quan:** BR-TRANSFER-011

> ⚠️ OPEN QUESTION: nguồn định nghĩa cùng khái niệm ở hai rule của hai section (Progress by Deck và Progress overview): card-day ở BR-PROGRESS-002 và BR-PROGRESS-011; phân hoạch Learning/Reviewing ở BR-PROGRESS-005 và BR-PROGRESS-014; chỉ-đọc ở BR-PROGRESS-007 và BR-PROGRESS-009. Chưa rõ rule nào là nguồn duy nhất. Nguồn: `business-rules/progress.md`. (Plan OQ-19)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
