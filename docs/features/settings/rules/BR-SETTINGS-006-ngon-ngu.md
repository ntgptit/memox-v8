---
id: BR-SETTINGS-006
title: Ngôn ngữ
status: active
summary: Ngôn ngữ là `system`, `en` hoặc `vi`, mặc định `system`, fallback `en`.
superseded_by:
---
## Rule

Ngôn ngữ MUST là một trong ba giá trị lưu được: `system`, `en`, `vi`; mặc định `system`. `system` MUST đi qua resolution của platform trên `supportedLocales` và MUST fallback về `en` khi không khớp. Lựa chọn tường minh MUST bền qua restart. Đổi ngôn ngữ MUST áp ngay trong cùng phiên chạy với đúng các ràng buộc của BR-SETTINGS-005, và MUST NOT đổi bất kỳ giá trị canonical nào được lưu — nhãn hiển thị MUST NOT trở thành dữ liệu (BR-STUDY-035).

**Enforced by:** db + UI
**Liên quan:** BR-STUDY-035, BR-SETTINGS-001, BR-SETTINGS-005

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
