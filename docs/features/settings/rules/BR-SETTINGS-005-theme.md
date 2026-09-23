---
id: BR-SETTINGS-005
title: Theme
status: active
summary: Theme là `system`, `light` hoặc `dark`, mặc định `system`, bền qua restart.
superseded_by:
---
## Rule

Theme MUST là một trong ba giá trị lưu được: `system`, `light`, `dark`; mặc định `system`. `system` MUST giải theo brightness của platform tại thời điểm hiện tại và MUST đổi theo khi platform đổi mà người dùng không thao tác gì. Lựa chọn tường minh MUST bền qua restart và MUST thắng brightness của platform. Đổi theme MUST áp ngay trong cùng phiên chạy: MUST NOT cần restart, MUST NOT dựng lại router và MUST NOT làm mất navigation stack hay vị trí cuộn.

**Enforced by:** db + UI
**Liên quan:** BR-SETTINGS-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
