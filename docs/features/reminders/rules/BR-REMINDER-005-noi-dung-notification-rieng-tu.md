---
id: BR-REMINDER-005
title: Nội dung notification giữ riêng tư
status: active
summary: Notification có thể nêu tên root deck cấp bách nhất, tổng số thẻ đến hạn, số deck còn lại; không chứa nội dung thẻ.
superseded_by:
---
## Rule

Nội dung notification MAY nêu **tên root deck cấp bách nhất**, **tổng số thẻ đến hạn** và **số deck còn lại**. Nội dung MUST NOT chứa mặt trước/sau của thẻ, ví dụ, gợi ý, phiên âm, tag, lịch sử ôn hay bất kỳ dữ liệu học nào của từng thẻ, kể cả trên lock screen. Log ở mọi level MUST NOT chứa nội dung thẻ, tên deck hay bản thân chuỗi copy; diagnostic chỉ MAY ghi lý do có kiểu và số đếm.

**Enforced by:** store + UI
**Liên quan:** BR-STARTER-002, BR-CORE-001, BR-CORE-002

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
