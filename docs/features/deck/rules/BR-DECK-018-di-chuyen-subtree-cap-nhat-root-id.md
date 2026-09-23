---
id: BR-DECK-018
title: Di chuyển subtree cập nhật root_id
status: active
summary: Di chuyển subtree cập nhật `root_id` cho toàn bộ subtree trong một transaction.
superseded_by:
---
## Rule

Di chuyển subtree MUST cập nhật `root_id` cho toàn bộ subtree trong một transaction.

**Enforced by:** store

> ⚠️ OPEN QUESTION: `data-model.md` mục "`root_id` — vì sao tồn tại" nói di chuyển subtree phải cập nhật `root_id` **và** `depth` (trích BR-DECK-018), nhưng rule này và UC-DECK-005 bước 3 chỉ nói `root_id`. (Plan OQ-8)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
