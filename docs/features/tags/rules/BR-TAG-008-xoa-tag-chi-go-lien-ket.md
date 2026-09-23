---
id: BR-TAG-008
title: Xoá tag chỉ gỡ liên kết
status: active
summary: Xoá tag chỉ gỡ `card_tags` rồi xoá `tags`, không đụng thẻ nào.
superseded_by:
---
## Rule

Xoá tag MUST **chỉ** gỡ mọi hàng `card_tags` của tag đó rồi xoá hàng `tags`, trong một transaction. MUST NOT xoá, ẩn hay đụng tới bất kỳ thẻ nào, kể cả thẻ chỉ mang duy nhất tag đó. Xác nhận MUST nêu rõ số thẻ sẽ bị gỡ tag và MUST NOT dùng lời lẽ ngụ ý mất thẻ; hành động MUST được mô tả là gỡ tag khỏi thẻ. Xoá tag không còn thẻ nào MUST thành công không cần xác nhận khác biệt về nghĩa.

**Enforced by:** store + UI
**Liên quan:** BR-TAG-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
