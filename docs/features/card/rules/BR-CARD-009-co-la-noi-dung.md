---
id: BR-CARD-009
title: Cờ là nội dung
status: active
summary: Cờ là nội dung: sửa thẻ và reset không đụng tới; hệ thống có thể bật nhưng không tự tắt.
superseded_by:
---
## Rule

Cờ đánh dấu thẻ MUST là nội dung: sửa thẻ và reset learning progress MUST NOT đụng tới nó; xoá thẻ MUST xoá nó theo cascade. Hệ thống MAY **bật** cờ (BR-STUDY-073) nhưng MUST NOT tự tắt — bỏ dấu là hành động của người dùng.

**Enforced by:** db + store
**Liên quan:** BR-CARD-005, BR-SRS-021, BR-STUDY-073

## Lý do

BR-CARD-009 và BR-TAG-001 nói cùng một điều mà BR-SRS-021 đã nói cho reset, nhưng ở chiều khác:
BR-SRS-021 nói reset giữ chúng lại, hai rule này nói *vì sao* — chúng thuộc nội dung,
cùng phía với `front`/`back`, chứ không thuộc lịch. Đó cũng là lý do cờ nằm trên
`card` chứ không trên `card_schedule`.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
