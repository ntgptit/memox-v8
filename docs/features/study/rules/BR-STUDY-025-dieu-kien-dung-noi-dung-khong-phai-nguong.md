---
id: BR-STUDY-025
title: Điều kiện dựng nội dung không phải ngưỡng thẻ
status: active
summary: Điều kiện dựng được nội dung quyết định stage chạy hay bỏ qua, không quyết định số thẻ.
superseded_by:
---
## Rule

Điều kiện **dựng được nội dung** của một stage (BR-STUDY-071, BR-STUDY-037, BR-STUDY-040) MUST NOT được hiểu là ngưỡng thẻ của stage đó. Chúng quyết định stage có chạy được hay bị bỏ qua, không quyết định lấy bao nhiêu thẻ.

**Enforced by:** rule
**Liên quan:** BR-MODE-009, BR-STUDY-024

## Lý do

**Mỗi mode có một ngưỡng riêng, và chúng không giống nhau.** BR-STUDY-025 nói không mode
nào có ngưỡng **số thẻ lấy ra** riêng — mọi mode của một phiên dùng chung
một tập. Nhưng điều kiện
**dựng được nội dung** thì có, và khác nhau: `guess` cần năm nghĩa khác nhau trong cây
(BR-STUDY-037, BR-STUDY-038); `fill` cần thẻ có `example` (BR-STUDY-071); `match` cần hai cặp (BR-STUDY-045).
`recall`, `self_assess` và `browse` chạy được với một thẻ.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
