---
id: BR-REMINDER-008
title: Chạm notification mở Study Home
status: active
summary: Chạm notification mở Study Home, không tự mở phiên hay ghi gì; vuốt bỏ không đổi gì.
superseded_by:
---
## Rule

Chạm notification MUST mở Study Home theo đúng route contract của app và MUST NOT tự mở phiên học, tự chọn deck hay tự ghi gì. Vuốt bỏ notification MUST NOT thay đổi study state, không đánh dấu đã học, không dời lịch thẻ và không ghi history.

**Enforced by:** UI + rule
**Liên quan:** BR-STUDY-004

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Chạm notification | Mở Study Home, không tự mở phiên (BR-REMINDER-008) |
| Vuốt bỏ notification | Không đụng study state, không ghi history (BR-REMINDER-008) |
