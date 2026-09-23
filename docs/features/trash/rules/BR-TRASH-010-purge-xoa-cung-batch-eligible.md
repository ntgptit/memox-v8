---
id: BR-TRASH-010
title: Purge xoá cứng batch eligible
status: active
summary: Purge xoá cứng đúng các hàng của batch eligible và cascade sang dữ liệu liên quan.
superseded_by:
---
## Rule

Purge MUST xoá cứng đúng các hàng của batch eligible và cascade sang study state, history, hàng đợi phiên và quan hệ tag của chúng. Purge MUST NOT chạy nếu bất kỳ descendant nào của hàng bị purge thuộc một batch **chưa** eligible hoặc còn đang active — batch đó MUST bị bỏ qua, MUST NOT bị purge một phần. Lỗi ở bất kỳ bước nào MUST rollback toàn bộ transaction và MUST để lại đồ thị deck ở trạng thái nhất quán.

**Enforced by:** store
**Liên quan:** BR-TRASH-009

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
