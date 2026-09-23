---
id: BR-TRANSFER-011
title: Export là chỉ đọc
status: active
summary: Export không ghi hay chạm tới dữ liệu nào.
superseded_by:
---
## Rule

Export MUST là thao tác chỉ-đọc: MUST NOT ghi hay chạm tới nội dung card, `updated_at` hay bất kỳ timestamp nào, `content_type` của deck (BR-DECK-015), study state, review history, session, cờ hay quan hệ tag. Export thành công MUST NOT xoá selection hiện tại — BR-CARD-012 chỉ bắt xoá selection sau một **mutation** thành công, và export không phải mutation.

**Enforced by:** store + UI
**Liên quan:** BR-DECK-015, BR-CARD-012

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
