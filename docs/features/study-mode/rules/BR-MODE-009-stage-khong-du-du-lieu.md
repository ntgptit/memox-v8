---
id: BR-MODE-009
title: Stage không đủ dữ liệu
status: active
summary: Học mới: stage không còn thẻ đủ dữ liệu bị bỏ qua; ôn tập: mode không đủ dữ liệu bị vô hiệu hoá kèm lý do.
superseded_by:
---
## Rule

Trong phiên `learning`, một stage MUST chạy chỉ khi nằm trong `stageSequence` **và** có ít nhất một thẻ đủ dữ liệu; stage không còn thẻ nào MUST bị bỏ qua thay vì hiện rỗng. Trong phiên `reviewing`, không có stage nào để bỏ qua vì người dùng đã chọn: mode không đủ dữ liệu MUST bị **vô hiệu hoá ngay trên màn chọn**, kèm lý do.

**Enforced by:** rule + UI
**Liên quan:** BR-MODE-007, BR-STUDY-071, BR-STUDY-055

## Lý do

Ngưỡng riêng theo stage đã đóng ở BR-STUDY-024: không có. Năm stage chạy trên **một**
tập thẻ của phiên, và BR-STUDY-025 tách bạch điều đó với điều kiện dựng được nội dung —
`guess` cần năm nghĩa khác nhau, `fill` cần thẻ có `example`. Hai thứ đó quyết
định stage **có chạy hay bị bỏ qua**, không quyết định lấy bao nhiêu thẻ.
Không đoán ở đây — mỗi câu trả lời khác nhau cho ra một thiết kế khác nhau.

Hai mục từng nằm trong danh sách này đã đóng: `guess` so "khác nghĩa" bằng
`back_folded` (BR-STUDY-039), và ngưỡng của chính `guess` là **năm nghĩa khác nhau
trong tập thẻ của phiên** (BR-STUDY-037, BR-STUDY-040). Ngưỡng đó khác `match` và `recall` ở
một điểm đáng chú ý: nó là điều kiện của **cả stage**, không phải của từng thẻ,
vì một question mượn bốn thẻ khác để dựng.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
