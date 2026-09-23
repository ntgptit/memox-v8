---
id: BR-STUDY-027
title: fill: lưu phiên bản chính sách so khớp
status: active
summary: Mỗi lượt `fill` lưu phiên bản chính sách so khớp; đổi chính sách tăng phiên bản, không sửa lượt cũ.
superseded_by:
---
## Rule

Mỗi lượt `fill` MUST lưu phiên bản chính sách so khớp đã dùng. Đổi chính sách MUST tăng phiên bản, MUST NOT sửa lại các lượt cũ.

**Enforced by:** db
**Liên quan:** BR-STUDY-026

## Lý do

**BR-STUDY-027 là lý do `scheduler_version` tồn tại, áp cho một thứ khác.** Một lượt đã ghi
phải đọc lại được bằng chính luật đã tạo ra nó. Nới chính sách so khớp — ví dụ bỏ
qua dấu câu — sẽ biến những lượt sai của hôm qua thành đúng khi đọc lại, và không
có cách nào biết lượt nào đã được chấm theo luật nào.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
