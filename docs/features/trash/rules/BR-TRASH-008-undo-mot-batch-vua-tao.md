---
id: BR-TRASH-008
title: Undo một batch vừa tạo
status: active
summary: Undo đảo ngược mọi batch mà một thao tác xoá vừa tạo về đúng vị trí cũ, không hỏi target, all-or-nothing.
superseded_by:
---
## Rule

Undo là thao tác đảo ngược **mọi batch** mà một thao tác xoá vừa tạo — một batch cho xoá một item, một batch cho mỗi card khi xoá nhiều card từ card list (BR-TRASH-001) — và MUST đưa mọi hàng của chúng về đúng vị trí cũ, không hỏi target, all-or-nothing trong một transaction. Undo MUST áp dụng lại đầy đủ các điều kiện của BR-TRASH-006 lên vị trí cũ của từng batch và MUST bị từ chối bằng lý do có kiểu khi vị trí cũ của bất kỳ batch nào không còn hợp lệ — MUST NOT im lặng đặt vào chỗ khác và MUST NOT khôi phục một phần. Cửa sổ Undo là snackbar 8 giây; sau đó khôi phục qua màn Trash (BR-TRASH-006).

**Enforced by:** store + UI
**Liên quan:** BR-TRASH-001, BR-TRASH-006

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
