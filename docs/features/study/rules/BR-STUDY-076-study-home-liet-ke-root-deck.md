---
id: BR-STUDY-076
title: Study Home liệt kê root deck
status: active
summary: Study Home liệt kê root deck với workload toàn subtree, xếp theo ba khoá.
superseded_by:
---
## Rule

Danh sách Study Home MUST chỉ liệt kê root deck, mỗi root một hàng, workload tổng hợp **toàn subtree** qua `root_id` (BR-DECK-002, BR-DECK-003) và MUST NOT dùng shortcut coalesce parent. Thứ tự MUST giảm dần theo ba khoá xếp hạng, đúng thứ tự đó: số Overdue, rồi số Due today, rồi số New — MUST NOT xếp theo tổng. Bằng nhau cả ba thì tie-break theo tên deck đã fold chữ hoa/thường theo Unicode (cùng quy ước BR-TAG-001), rồi theo `id`; tie-break MUST NOT dựa vào `lower()` của SQL vì hàm đó chỉ fold ASCII. Deck không còn workload MUST vẫn nằm trong danh sách, đứng cuối theo chính thứ tự trên, và MUST giữ hành động mở nếu subtree còn ít nhất một card (BR-STUDY-008). Deck không còn card nào MUST NOT được trao hành động mở. Ba con số MUST luôn hiển thị kể cả khi bằng 0, mỗi con số MUST có icon và nhãn chữ riêng, và màu MUST NOT là tín hiệu duy nhất.

**Enforced by:** store + UI
**Liên quan:** BR-STUDY-008, BR-DECK-002, BR-DECK-003, BR-TAG-001, BR-STUDY-068

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
