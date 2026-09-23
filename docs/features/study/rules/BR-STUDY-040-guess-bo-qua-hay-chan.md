---
id: BR-STUDY-040
title: guess: bỏ qua stage hay chặn
status: active
summary: Không đủ năm nghĩa thì bỏ qua stage `guess`; đủ mà question không dựng được thì chặn.
superseded_by:
---
## Rule

Phân biệt hai ca: tập thẻ của phiên **không đủ năm nghĩa khác nhau** thì stage `guess` MUST bị bỏ qua theo BR-MODE-009, không phải lỗi. Đủ năm nhưng một question vẫn không dựng được thì MUST chặn: không render, không ghi lượt, không bỏ qua thẻ, không tiến checkpoint.

**Enforced by:** rule
**Liên quan:** BR-MODE-009, BR-STUDY-071, BR-STUDY-037

## Lý do

**BR-STUDY-040 là chỗ đặc tả gốc và BR-STUDY-071 nói ngược nhau, và cả hai đều đúng — cho hai
ca khác nhau.** Deck chỉ có ba thẻ thì `guess` **không bao giờ** dựng được question,
và hiện lỗi mỗi phiên là đổ cho người dùng một thứ họ không sửa được bằng thao
tác nào trong phiên; bỏ qua stage là đúng. Nhưng khi tập đủ năm mà một question
vẫn không dựng được thì đó là bất thường thật, và chặn lại mới đúng — render bốn
lựa chọn sẽ âm thầm đổi xác suất đoán đúng từ 20% lên 25%.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
