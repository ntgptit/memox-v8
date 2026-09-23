---
id: BR-SEARCH-002
title: Một hàm chuẩn hoá dùng chung
status: active
summary: Truy vấn và dữ liệu đi qua một hàm chuẩn hoá dùng chung: trim rồi hạ chữ theo Unicode của Dart.
superseded_by:
---
## Rule

Cả câu truy vấn lẫn dữ liệu được so sánh MUST đi qua **một** hàm chuẩn hoá dùng chung — trim rồi hạ chữ theo Unicode của Dart. SQL MUST NOT dùng `lower()` hay `COLLATE NOCASE` để thay thế: chúng chỉ fold ASCII, nên `CÔNG NGHỆ` sẽ không tìm được bằng `công nghệ`. Chuẩn hoá MUST là case-only; MUST NOT bỏ dấu.

**Enforced by:** rule + store
**Liên quan:** BR-TAG-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
