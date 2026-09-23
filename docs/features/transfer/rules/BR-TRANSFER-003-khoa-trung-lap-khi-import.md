---
id: BR-TRANSFER-003
title: Khoá trùng lặp khi import
status: active
summary: Trùng lặp đo bằng `front_folded + back_folded` trong deck đích và trong cùng nguồn import.
superseded_by:
---
## Rule

Trùng lặp khi import MUST đo bằng khoá `front_folded + back_folded`, trong hai phạm vi: card đang có trong **chính deck đích**, và các hàng lặp lại trong cùng nguồn import; card ở deck khác MUST NOT bị coi là trùng. Mặc định trùng lặp bị bỏ qua; người dùng MAY bật "Include duplicates". Import MUST NOT cập nhật hay gộp vào card hiện có — trùng thì hoặc bỏ hoặc tạo bản thứ hai, không có đường thứ ba. Kiểm tra trùng MUST chạy lại **bên trong** transaction commit theo policy đã chọn, vì database có thể đổi giữa preview và import.

**Enforced by:** rule + store
**Liên quan:** BR-TRANSFER-004

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Hai hàng trong file cùng `front`+`back` sau fold | Hàng sau đánh dấu trùng-trong-file; mặc định bỏ qua (BR-TRANSFER-003) |
| Card cùng nội dung đã có sẵn trong deck đích | Đánh dấu trùng-với-deck; bật Include duplicates thì vẫn ghi (BR-TRANSFER-003) |
