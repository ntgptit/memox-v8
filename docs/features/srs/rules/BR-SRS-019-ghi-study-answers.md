---
id: BR-SRS-019
title: Ghi study answers
status: active
summary: Mỗi lượt `scheduled` và `relearning` ghi một dòng `review_log` với các cột đã định.
superseded_by:
---
## Rule

Mỗi lượt đánh giá — cả `scheduled` lẫn `relearning` — MUST ghi một dòng vào
`review_log` gồm `card_id`, `session_id`, `scheduler_type`,
`generation`, `kind`, `action`, `answered_at`, `next_due_at`, và
cặp trạng thái trước/sau của scheduler tương ứng.

**Enforced by:** store

## Lý do

Ghi cả lượt `relearning` là có chủ đích: nó là dữ liệu thật về việc người dùng
phải lặp mấy lần mới nhớ — thứ cần để đánh giá chất lượng thuật toán sau này.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
