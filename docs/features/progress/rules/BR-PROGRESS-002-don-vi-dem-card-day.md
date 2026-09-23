---
id: BR-PROGRESS-002
title: Đơn vị đếm card-day (theo deck)
status: active
summary: Đơn vị đếm là card-day — cặp phân biệt (card, ngày địa phương), không phải số lượt trả lời.
superseded_by:
---
## Rule

Đơn vị đếm MUST là **card-day**: một cặp phân biệt `(card, ngày địa phương)` theo đúng định nghĩa ngày của BR-STUDY-074, MUST NOT là số lượt trả lời. Trả lời cùng một thẻ sáu lần trong một buổi tối MUST đếm là **một** card-day. `unique active cards` MUST là số card phân biệt có ít nhất một lượt trong khoảng; `active days` MUST là số ngày địa phương phân biệt có ít nhất một lượt trong khoảng. Hai số này đo hai thứ khác nhau và MUST NOT cộng vào nhau. `active days` MUST NOT được tính bằng cách cộng các deck con: cùng một ngày xuất hiện ở hai deck vẫn là một ngày học, nên mọi tổng MUST đọc trực tiếp từ cùng một câu lệnh chứ không fold từ các hàng.

**Enforced by:** rule + store
**Liên quan:** BR-STUDY-074

## Lý do

Cùng khái niệm card-day với BR-PROGRESS-011, rule tương ứng của Progress overview; hai rule áp cho hai màn và được giữ cả hai (chủ dự án chốt khi xử lý OQ-19 (2026-09-23)). Sửa một rule thì kiểm tra rule kia.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Trả lời cùng một thẻ sáu lần trong một buổi tối | Một card-day, một active day (BR-PROGRESS-002) |
| Học hai deck khác nhau trong cùng một ngày | Mỗi deck một active day; tổng của cấp trên vẫn là một (BR-PROGRESS-002) |
