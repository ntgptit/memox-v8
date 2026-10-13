---
id: BR-STUDY-071
title: Bỏ qua thẻ thiếu dữ liệu có ghi nhận
status: active
summary: Thẻ thiếu dữ liệu cho một stage bị bỏ qua có ghi nhận ở stage đó, vẫn xuất hiện ở stage khác.
superseded_by:
---
## Rule

Thẻ không đủ dữ liệu cho một stage MUST bị bỏ qua **có ghi nhận** ở stage đó, MUST NOT bị xoá khỏi deck, và MUST vẫn xuất hiện ở các stage khác mà nó đủ dữ liệu. "Có ghi nhận" là: hàng đợi đã lưu của stage đó (BR-STUDY-021) MUST NOT có hàng cho thẻ, nên việc bỏ qua đọc được từ dữ liệu phiên; MUST NOT có cờ hay lý do riêng cho từng thẻ — lý do chỉ tồn tại ở mức stage, khi cả stage không chạy (BR-MODE-009).

**Enforced by:** store
**Liên quan:** BR-MODE-009, BR-STUDY-022

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
