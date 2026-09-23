---
id: BR-TAG-009
title: Thao tác catalog không đụng nội dung thẻ
status: active
summary: Đổi tên, gộp, xoá tag không ghi nội dung thẻ hay dữ liệu học.
superseded_by:
---
## Rule

Mọi thao tác catalog — đổi tên, gộp, xoá — MUST là read-only đối với nội dung thẻ và dữ liệu học: MUST NOT ghi `front`, `back`, ba trường phụ, `is_flagged`, `card.updated_at`, `content_type` của deck (BR-DECK-015), study state, review history hay session. Thứ duy nhất được ghi là hàng `tags` và hàng `card_tags`.

**Enforced by:** store
**Liên quan:** BR-CARD-005, BR-SRS-021, BR-CARD-009, BR-DECK-015, BR-TRANSFER-011

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
