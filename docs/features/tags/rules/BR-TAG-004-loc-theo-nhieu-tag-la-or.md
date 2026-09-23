---
id: BR-TAG-004
title: Lọc theo nhiều tag là OR
status: active
summary: Lọc nhiều tag là OR giữa các tag, AND với filter trạng thái và search term.
superseded_by:
---
## Rule

Lọc thẻ theo nhiều tag MUST là **OR giữa các tag đã chọn** — thẻ mang ít nhất một tag trong tập chọn là thẻ khớp. Vị từ tag MUST được **AND** với filter trạng thái đang bật (All/Due/New/Flagged) và với search term. **Tập chọn rỗng MUST là phần tử đơn vị**: không có vị từ tag nào được áp, và kết quả MUST bằng đúng kết quả khi tính năng chưa tồn tại. Vị từ tag MUST hiện thực bằng một phép kiểm tồn tại trên `card_tags` (`EXISTS` hoặc tương đương trả về nhiều nhất một hàng cho mỗi thẻ), MUST NOT bằng một join nhân bản: một thẻ mang ba tag đã chọn MUST xuất hiện đúng **một** lần trong danh sách, đếm đúng **một** lần trong count và chiếm đúng **một** chỗ trong cửa sổ phân trang. Danh sách, count và "select all" (BR-CARD-012) MUST dùng chung một vị từ.

**Enforced by:** store
**Liên quan:** BR-CARD-012

## Lý do

BR-TAG-004 là rule dễ hiện thực sai nhất trong nhóm này, và cả hai cách sai đều
trông đúng ở dữ liệu nhỏ. Một `INNER JOIN card_tags` với `tag_id IN (…)` cho
đúng tập thẻ nhưng **nhân bản hàng** theo số tag khớp, nên `LIMIT 50` trả về ít
hơn 50 thẻ và `COUNT(*)` đếm to hơn sự thật; `DISTINCT` chữa được count nhưng
vẫn buộc SQLite vật chất hoá rồi khử trùng, làm mất chính điểm dừng sớm mà
`LIMIT` và index `(deck_id, created_at, id)` mua được. `EXISTS` không có cả hai
vấn đề: nó là một phép kiểm boolean cho mỗi thẻ.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
