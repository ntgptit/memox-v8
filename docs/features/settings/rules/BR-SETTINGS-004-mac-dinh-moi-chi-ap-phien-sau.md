---
id: BR-SETTINGS-004
title: Mặc định mới chỉ áp phiên tạo sau
status: active
summary: Đổi mặc định học chỉ có hiệu lực với phiên tạo sau đó.
superseded_by:
---
## Rule

Đổi bất kỳ mặc định học nào MUST chỉ có hiệu lực với phiên **được tạo sau đó**. Phiên đang chạy MUST giữ nguyên `study_session.card_limit` đã chốt lúc mở (BR-STUDY-024), MUST NOT dựng lại hàng đợi, MUST NOT đổi thứ tự đã sinh và MUST NOT đổi round đang chạy. UI MUST nói rõ điều đó tại chỗ đổi.

**Enforced by:** store + UI
**Liên quan:** BR-STUDY-024, BR-STUDY-022, BR-STUDY-057

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
