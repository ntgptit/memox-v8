---
id: BR-STUDY-047
title: Pill New/Due dùng cùng định nghĩa
status: active
summary: Pill New và Due trên danh sách thẻ dùng cùng định nghĩa của BR-STUDY-051, hai tập rời nhau.
superseded_by:
---
## Rule

Pill lọc trên danh sách thẻ MUST dùng cùng định nghĩa: **New** = `learned_at IS NULL` (BR-CARD-007); **Due** = `learned_at IS NOT NULL AND due_at <= now`. Hai tập MUST rời nhau.

**Enforced by:** UI + db
**Liên quan:** BR-CARD-007, BR-STUDY-051

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
