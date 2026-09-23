---
id: BR-DECK-018
title: Di chuyển subtree cập nhật root_id và depth
status: active
summary: Di chuyển subtree cập nhật `root_id` và `depth` cho toàn bộ subtree trong một transaction.
superseded_by:
---
## Rule

Di chuyển subtree MUST cập nhật `root_id` và `depth` cho toàn bộ subtree trong một transaction.

**Enforced by:** store

## Lý do

`deck.depth` là cột lưu thật (xem `shared/data/schema.md`, bảng `deck`); cập nhật `root_id` mà không cập nhật `depth` để lại độ sâu sai trên mọi descendant. Chủ dự án chốt khi xử lý open question OQ-8 (2026-09-23): thêm `depth` vào rule cho khớp schema.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
