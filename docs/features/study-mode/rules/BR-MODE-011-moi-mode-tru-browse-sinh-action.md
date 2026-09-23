---
id: BR-MODE-011
title: Mọi mode trừ browse sinh action
status: active
summary: Mọi mode trừ `browse` sinh action thuộc `supportedActions`; `self_assess` lấy action từ người dùng.
superseded_by:
---
## Rule

Mọi mode **trừ `browse`** MUST sinh một `action` thuộc `supportedActions` của thuật toán. `self_assess` MUST lấy action **trực tiếp từ người dùng**; `match`/`guess`/`recall`/`fill` MUST chấm ra kết quả nhị phân rồi ánh xạ theo BR-MODE-012.

**Enforced by:** rule
**Liên quan:** BR-SRS-008, BR-STUDY-009, BR-MODE-005

## Lý do

**BR-MODE-011 gỡ một mâu thuẫn nghe rất hợp lý.** `self_assess` thường được mô tả là "không
có đúng/sai" — đúng, theo nghĩa **không có máy chấm**: người học tự đánh giá. Nhưng
nó vẫn sinh ra `forgotten`/`remembered`, và nếu đọc thành "không sinh action" thì
**không mode nào cập nhật lịch** và toàn bộ SRS biến mất cùng M3 của `product.md`.

Khác biệt thật giữa các mode vì thế nằm gọn ở **nguồn** của action, không phải ở
việc có hay không có action — và đó cũng chính là toàn bộ phần mỗi handler phải
tự viết. `self_assess` không còn là ngoại lệ của luồng chung; nó là mode mà
`evaluate` trả về đúng cái người dùng vừa bấm.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
