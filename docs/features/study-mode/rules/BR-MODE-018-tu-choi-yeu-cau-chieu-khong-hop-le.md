---
id: BR-MODE-018
title: Từ chối yêu cầu chiều không hợp lệ
status: active
summary: Thiếu chiều khi đủ điều kiện là lỗi validation; có chiều khi không đủ điều kiện là conflict; không ghi session.
superseded_by:
---
## Rule

Yêu cầu mở phiên **đủ điều kiện** mà thiếu chiều MUST bị từ chối là lỗi validation, và MUST NOT ghi session. Yêu cầu **không đủ điều kiện** mà kèm chiều MUST bị từ chối là conflict, và MUST NOT ghi session. Cả hai kiểm tra MUST chạy trước mọi ghi.

**Enforced by:** rule
**Liên quan:** BR-STUDY-020, BR-STUDY-054, BR-MODE-013

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Mở phiên `self_assess` trên deck `sm2` nhưng chưa chọn chiều | Từ chối là validation, không ghi session (BR-MODE-018) |
