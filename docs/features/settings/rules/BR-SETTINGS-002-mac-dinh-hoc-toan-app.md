---
id: BR-SETTINGS-002
title: Mặc định học toàn app
status: active
summary: Mặc định học gồm `card_limit` và `new_card_order`, dùng lại validation và enum production.
superseded_by:
---
## Rule

Mặc định học toàn app MUST gồm đúng hai giá trị: `card_limit` và `new_card_order`. Chúng MUST dùng lại đúng validation và enum production của BR-STUDY-003 và BR-STUDY-057 — MUST NOT có bản sao thứ hai của bound, của giá trị mặc định hay của tên enum. Ghi mặc định toàn app MUST NOT ghi vào `deck.study_config` của bất kỳ deck nào.

**Enforced by:** rule
**Liên quan:** BR-STUDY-003, BR-STUDY-056, BR-STUDY-057

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
