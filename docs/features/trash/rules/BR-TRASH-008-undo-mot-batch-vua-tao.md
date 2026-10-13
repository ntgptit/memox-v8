---
id: BR-TRASH-008
title: Undo một batch vừa tạo
status: active
summary: Undo đảo ngược một batch vừa tạo về đúng vị trí cũ, không hỏi target; không khả dụng cho thao tác xoá nhiều item.
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

Vị trí cũ (`sibling_position`) đã bị một deck sống chiếm vì có reorder xen giữa (reorder đánh số lại các deck sống từ 0, BR-SRS-007): Undo vẫn trả deck về đúng vị trí cũ và dịch deck đang chiếm cùng mọi deck sống sau nó lên một, trong cùng transaction, để không hai deck sống cùng vị trí (DEV-219). Ví dụ A(0), B(1), C(2); xoá B; kéo C lên trước A → C(0), A(1); Undo B → C(0), B(1), A(2).
