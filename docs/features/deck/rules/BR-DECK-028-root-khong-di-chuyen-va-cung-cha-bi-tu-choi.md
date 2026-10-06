---
id: BR-DECK-028
title: Root không di chuyển và di chuyển về cùng cha bị từ chối
status: active
summary: Root deck không di chuyển được; di chuyển một deck về đúng cha hiện tại bị từ chối và không ghi gì.
superseded_by:
---
## Rule

Root deck MUST NOT di chuyển: một root không có cha, và đưa một deck lên hay xuống vị trí root nằm ngoài phạm vi phép di chuyển (UC-DECK-005 A2; `DeckRejection.rootCannotMove`). Di chuyển một deck về đúng cha nó đang có MUST bị từ chối (`DeckRejection.sameParent`) và MUST NOT ghi gì — không đổi `updated_at`, không đổi vị trí sibling, không hàng outbox. Cả hai kiểm tra MUST chạy trong transaction ghi, sau kiểm tra tồn tại của nguồn và đích (`notFound`) và trước mọi kiểm tra về đích (BR-DECK-017, BR-SRS-006).

**Enforced by:** store
**Liên quan:** BR-DECK-017, BR-SRS-006

## Lý do

Hai luật này có trong code và test từ gói deck/card (spec deck–card backend) nhưng chưa có BR; ghi lại để UI và API command protocol (từ chối `VALIDATION_FAILED` cho cùng hai trường hợp) có một nguồn.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Kéo một root deck vào deck khác | Từ chối `rootCannotMove`, không ghi gì (BR-DECK-028) |
| Thả deck vào đúng cha hiện tại | Từ chối `sameParent`, không ghi gì — không phải no-op im lặng (BR-DECK-028) |
