---
id: BR-STUDY-039
title: Khác nghĩa đo bằng back_folded
status: active
summary: "Hai nghĩa khác nhau" đo bằng `back_folded`; hai thẻ cùng `back_folded` không cùng option set.
superseded_by:
---
## Rule

"Hai nghĩa khác nhau" MUST đo bằng `back_folded`, không bằng chuỗi hiển thị. Hai thẻ cùng `back_folded` MUST NOT cùng xuất hiện trong một option set.

**Enforced by:** rule
**Liên quan:** BR-STUDY-037, BR-STUDY-038

## Lý do

**BR-STUDY-039 dùng lại `back_folded` thay vì định nghĩa một phép chuẩn hoá thứ hai.**
Cột đó đã tồn tại để search so trên nó: đã trim, hạ hoa và fold Unicode. Một
phép normalize riêng cho `guess` sẽ trôi khỏi phép kia ngay lần đầu
có ai sửa một trong hai, và không ai biết để sửa cả hai.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
