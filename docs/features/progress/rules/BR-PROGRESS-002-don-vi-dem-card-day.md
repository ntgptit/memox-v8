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

> ⚠️ OPEN QUESTION: nguồn định nghĩa cùng khái niệm ở hai rule của hai section (Progress by Deck và Progress overview): card-day ở BR-PROGRESS-002 và BR-PROGRESS-011; phân hoạch Learning/Reviewing ở BR-PROGRESS-005 và BR-PROGRESS-014; chỉ-đọc ở BR-PROGRESS-007 và BR-PROGRESS-009. Chưa rõ rule nào là nguồn duy nhất. Nguồn: `business-rules/progress.md`. (Plan OQ-19)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Trả lời cùng một thẻ sáu lần trong một buổi tối | Một card-day, một active day (BR-PROGRESS-002) |
| Học hai deck khác nhau trong cùng một ngày | Mỗi deck một active day; tổng của cấp trên vẫn là một (BR-PROGRESS-002) |
