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

> ⚠️ OPEN QUESTION: nguồn định nghĩa cùng khái niệm ở hai rule của hai section (Progress by Deck và Progress overview): card-day ở BR-PROGRESS-002 và BR-PROGRESS-011; phân hoạch Learning/Reviewing ở BR-PROGRESS-005 và BR-PROGRESS-014; chỉ-đọc ở BR-PROGRESS-007 và BR-PROGRESS-009. Chưa rõ rule nào là nguồn duy nhất. Nguồn: `business-rules/progress.md`. (Plan OQ-19)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Một ngày có cả lượt `learning` và lượt `scheduled` trên cùng thẻ | Là Learning day (BR-PROGRESS-005) |
