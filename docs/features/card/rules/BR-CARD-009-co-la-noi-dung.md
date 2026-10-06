---
id: BR-CARD-009
title: Cờ là nội dung
status: active
summary: Cờ là nội dung: sửa thẻ và reset không đụng tới, xoá thẻ thì xoá cờ theo cascade; hệ thống có thể bật nhưng không tự tắt.
superseded_by:
---
## Rule

Cờ đánh dấu thẻ MUST là nội dung: sửa thẻ và reset learning progress MUST NOT đụng tới nó; xoá thẻ MUST xoá nó theo cascade. Hệ thống MAY **bật** cờ (BR-STUDY-073) nhưng MUST NOT tự tắt — bỏ dấu là hành động của người dùng. Vì thế phần ghi của *sửa thẻ* MUST NOT mang cờ: nút cờ trong editor (màn 09) là hành động Flag / Remove flag riêng (UC-CARD-001 A7), ghi đúng giá trị người dùng vừa chọn, không ghi lại cờ mà editor mở ra với (DEV-220).

**Enforced by:** db + store
**Liên quan:** BR-CARD-005, BR-SRS-021, BR-STUDY-073

## Lý do

BR-CARD-009 và BR-TAG-001 nói cùng một điều mà BR-SRS-021 đã nói cho reset, nhưng ở chiều khác:
BR-SRS-021 nói reset giữ chúng lại, hai rule này nói *vì sao* — chúng thuộc nội dung,
cùng phía với `front`/`back`, chứ không thuộc lịch. Đó cũng là lý do cờ nằm trên
`card` chứ không trên `card_schedule`.

## Ví dụ

Editor của thẻ X mở khi cờ tắt; trong lúc đó một máy khác (hoặc BR-STUDY-073) bật cờ của X. Người dùng chỉ sửa mặt sau rồi Lưu: mặt sau đổi, cờ **vẫn bật**. Nếu người dùng bấm nút cờ trong editor rồi Lưu, cờ ghi theo lựa chọn đó.

## Edge case

Không áp dụng
