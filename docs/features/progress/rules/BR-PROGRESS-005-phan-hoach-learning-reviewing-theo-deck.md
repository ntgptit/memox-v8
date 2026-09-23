---
id: BR-PROGRESS-005
title: Phân hoạch Learning/Reviewing (theo deck)
status: active
summary: Learning và Reviewing là phân hoạch loại trừ và vét cạn của card-days, ưu tiên Learning.
superseded_by:
---
## Rule

Learning và Reviewing MUST là một phân hoạch **loại trừ và vét cạn** của card-days: mỗi card-day MUST thuộc đúng một nửa, nên `Learning + Reviewing` MUST bằng tổng card-days. Ưu tiên thuộc về Learning: một ngày có ít nhất một lượt `kind = 'learning'` MUST là Learning day dù ngày đó còn lượt nào khác; mọi ngày còn lại — `scheduled` và `relearning` — MUST là Reviewing day. Phân loại MUST đọc cột `kind` đã lưu (BR-SRS-015), MUST NOT suy ra bằng cách so sánh trạng thái trước/sau.

**Enforced by:** rule + store
**Liên quan:** BR-SRS-015, BR-STUDY-051

## Lý do

Cùng khái niệm phân hoạch Learning/Reviewing với BR-PROGRESS-014, rule tương ứng của Progress overview; hai rule áp cho hai màn và được giữ cả hai (chủ dự án chốt khi xử lý OQ-19 (2026-09-23)). Sửa một rule thì kiểm tra rule kia.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Một ngày có cả lượt `learning` và lượt `scheduled` trên cùng thẻ | Là Learning day (BR-PROGRESS-005) |
