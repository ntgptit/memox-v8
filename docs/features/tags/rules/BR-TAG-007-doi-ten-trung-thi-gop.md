---
id: BR-TAG-007
title: Đổi tên trùng thì gộp
status: active
summary: Đổi tên trùng tag khác thì gộp nguồn vào đích nguyên tử trong một transaction.
superseded_by:
---
## Rule

Nếu tên đã fold trùng với một tag **khác** đang tồn tại, đổi tên MUST gộp tag nguồn vào tag đích **nguyên tử trong đúng một transaction**: mọi thẻ mang tag nguồn mà chưa mang tag đích MUST được nối tới tag đích, liên kết trùng MUST được dedupe (cặp `(card_id, tag_id)` là khoá), mọi liên kết còn lại của tag nguồn MUST bị gỡ, và **hàng tag nguồn MUST bị xoá**. Tag đích MUST giữ nguyên `id`, `name` và `name_folded` — gộp không đổi cách viết của đích. Gộp MUST NOT làm bất kỳ thẻ nào vượt trần BR-TAG-002: số tag của một thẻ sau khi gộp MUST bằng hoặc nhỏ hơn trước khi gộp, vì mỗi thẻ đổi nguồn lấy đích chứ không cộng thêm. Một write thất bại MUST rollback toàn bộ, để lại đúng đồ thị tag ban đầu — MUST NOT có trạng thái nửa gộp trong đó cả hai tag cùng tồn tại với liên kết đã dời một phần.

**Enforced by:** store
**Liên quan:** BR-TAG-001, BR-TAG-002

## Lý do

BR-TAG-007 gộp bằng đổi tên chứ không có một hành động `Merge` riêng, và đó là quyết
định về giao diện được nâng thành rule. Người dùng gõ `Noun` lên tag `nouns` là
đang nói "hai cái này là một"; bắt họ tìm một menu khác để nói đúng điều vừa gõ
là thêm một bước cho cùng một ý định.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
