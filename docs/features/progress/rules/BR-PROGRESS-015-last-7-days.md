---
id: BR-PROGRESS-015
title: Last 7 days
status: active
summary: "Last 7 days" là hôm nay và sáu ngày trước, đúng bảy phần tử cũ → mới, zero-fill.
superseded_by:
---
## Rule

"Last 7 days" gồm **hôm nay và sáu ngày trước đó**, đúng bảy phần tử, thứ tự **cũ → mới**. Ngày không có card-day nào MUST xuất hiện với giá trị 0 (zero-fill), MUST NOT bị bỏ khỏi dãy và MUST NOT làm dãy ngắn lại. Dãy MUST đúng khi cửa sổ bắc qua ranh giới tháng, ranh giới năm và ở mọi UTC offset.

**Enforced by:** store
**Liên quan:** BR-PROGRESS-011, BR-PROGRESS-013

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
