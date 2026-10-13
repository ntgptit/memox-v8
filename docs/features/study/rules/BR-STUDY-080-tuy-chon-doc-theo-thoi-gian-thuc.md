---
id: BR-STUDY-080
title: Tuỳ chọn đọc áp dụng theo thời gian thực
status: active
summary: Ngôn ngữ phát âm và công tắc đọc được lấy tại thời điểm đọc; đổi áp dụng cho thẻ kế tiếp, không cần phiên mới.
superseded_by:
---
## Rule

Ngôn ngữ phát âm và công tắc tự động đọc MUST được đọc tại thời điểm phát (một câu lệnh ghép dòng root deck và dòng `app_settings`); một thay đổi MUST áp dụng cho thẻ kế tiếp của phiên đang mở, khác với trần thẻ và thứ tự thẻ mới (BR-SETTINGS-004) vốn chốt khi mở phiên.

**Enforced by:** store + UI
**Liên quan:** BR-SETTINGS-004, BR-SETTINGS-009, BR-SETTINGS-010

## Lý do

Phiên không ghi gì từ hai giá trị này, nên không có lý do để khoá chúng theo phiên.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
