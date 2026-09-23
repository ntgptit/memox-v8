---
id: BR-MODE-019
title: Chiều không đổi lịch hay nội dung
status: active
summary: Chiều hỏi không đổi tập action, ánh xạ chất lượng, lịch hay nội dung thẻ.
superseded_by:
---
## Rule

Chiều hỏi MUST NOT đổi tập action của scheduler (BR-STUDY-009), ánh xạ chất lượng (BR-SRS-010), `ease_factor`, `interval_days`, `repetitions`, `due_at`, hay `current_box`. Cùng một thẻ với cùng một action MUST cho ra cùng một lịch bất kể chiều. Chiều MUST NOT ghi hay sửa nội dung thẻ (`front`, `back`, cột folded) và MUST NOT chạm `card.updated_at`.

**Enforced by:** rule + store
**Liên quan:** BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-STUDY-009, BR-SRS-021

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
