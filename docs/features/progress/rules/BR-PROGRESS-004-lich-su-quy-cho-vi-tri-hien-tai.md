---
id: BR-PROGRESS-004
title: Lịch sử quy cho vị trí hiện tại của thẻ
status: active
summary: Lịch sử quy cho vị trí hiện tại của thẻ; chuyển thẻ thì toàn bộ lịch sử đi theo.
superseded_by:
---
## Rule

Lịch sử MUST được quy cho **vị trí hiện tại của thẻ**: đường đi `review_log → card → deck`. Chuyển một thẻ hoặc một subtree sang deck khác MUST làm **toàn bộ** lịch sử của thẻ xuất hiện dưới deck và root mới, không chỉ các lượt sau khi chuyển. `review_log` MUST NOT nhận thêm cột deck lịch sử và hệ thống MUST NOT thêm bảng analytics riêng để né rule này; hệ quả được chấp nhận là "tháng Ba deck này trông thế nào" không trả lời được và không thuộc v1. Tổng của một deck MUST gồm thẻ trực tiếp của nó và mọi descendant theo cây thật — root resolve qua `root_id`, cấp trung gian resolve bằng recursive walk, MUST NOT dùng `COALESCE(parent_id, id)` (BR-DECK-003). Deck đã xoá MUST biến mất khỏi mọi số, và điều đó MUST đến từ cascade của schema chứ không từ một predicate lọc; khi một cơ chế Trash tồn tại thì deck trong Trash và mọi descendant của nó MUST bị loại theo cùng cách, restore MUST làm activity xuất hiện lại theo vị trí hiện tại của thẻ, và purge vĩnh viễn MUST loại nó vĩnh viễn.

**Enforced by:** store
**Liên quan:** BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-018

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Chuyển thẻ sang root khác sau khi đã học | Toàn bộ lịch sử của thẻ chuyển theo; deck cũ về 0 (BR-PROGRESS-004) |
| Xoá deck đang có hoạt động | Cascade xoá card rồi answers; số về 0, không phải bị lọc (BR-PROGRESS-004) |
