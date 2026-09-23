---
id: BR-TRASH-008
title: Undo một batch vừa tạo
status: active
summary: Undo đảo ngược một batch vừa tạo về đúng vị trí cũ, không hỏi target.
superseded_by:
---
## Rule

Undo là thao tác đảo ngược **một** batch vừa được tạo và MUST đưa mọi hàng của batch đó về đúng vị trí cũ, không hỏi target. Undo MUST áp dụng lại đầy đủ các điều kiện của BR-TRASH-006 lên vị trí cũ và MUST bị từ chối bằng lý do có kiểu khi vị trí cũ không còn hợp lệ — MUST NOT im lặng đặt vào chỗ khác. Undo MUST NOT khả dụng cho thao tác xoá nhiều item.

**Enforced by:** store + UI
**Liên quan:** BR-TRASH-001, BR-TRASH-006

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
