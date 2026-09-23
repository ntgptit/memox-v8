---
id: BR-REMINDER-012
title: Nền tảng không hỗ trợ
status: active
summary: Nền tảng không hỗ trợ báo capability có kiểu, không crash, UI hiện trạng thái không khả dụng.
superseded_by:
---
## Rule

Nền tảng không hỗ trợ nhắc học MUST báo capability bằng một giá trị có kiểu và MUST NOT crash, MUST NOT im lặng coi như đã bật. UI MUST hiện trạng thái không khả dụng thay vì một toggle bật được nhưng không có tác dụng. Nghiệp vụ và UI MUST NOT import kiểu của plugin notification, MUST NOT kiểm tra nền tảng và MUST NOT chạm platform IO.

**Enforced by:** rule + store + UI

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Chạy trên Web | Capability báo không hỗ trợ; không có toggle bật được mà vô tác dụng (BR-REMINDER-012) |
