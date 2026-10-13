---
id: BR-TRANSFER-005
title: Deck unset thành card khi import
status: active
summary: Deck đích `unset` thành `card` cùng transaction nếu ghi được ít nhất một card.
superseded_by:
---
## Rule

Deck đích đang `unset` MUST thành `card` trong cùng transaction với batch nếu có ít nhất một card được ghi (BR-DECK-008 áp cho lô); một lần import ghi zero card MUST NOT đổi `content_type`.

Với nguồn có dòng sao, deck đích `unset` MUST thành `deck` trong cùng transaction khi ít nhất một deck con được tạo (BR-DECK-015); không tạo deck con nào thì `content_type` MUST giữ nguyên.

**Enforced by:** store
**Liên quan:** BR-DECK-008, BR-DECK-015, BR-TRANSFER-015

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Import vào deck `unset`, có ít nhất một card ghi được | Deck thành `card` trong cùng transaction (BR-TRANSFER-005) |
