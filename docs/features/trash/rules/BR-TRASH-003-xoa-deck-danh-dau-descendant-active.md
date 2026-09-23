---
id: BR-TRASH-003
title: Xoá deck đánh dấu mọi descendant active
status: active
summary: Xoá deck đánh dấu deck và mọi descendant đang active bằng cùng một batch.
superseded_by:
---
## Rule

Xoá một deck MUST đánh dấu deck đó cùng **mọi descendant đang active** — deck lẫn card — bằng **cùng một** batch và cùng một `deleted_at`. Descendant đã ở Trash từ một batch trước MUST giữ nguyên tombstone cũ và MUST NOT được gộp vào batch mới; restore batch mới MUST NOT hồi sinh chúng. Quan hệ batch MUST được lưu trên hàng, MUST NOT suy ra từ parent hiện tại.

**Enforced by:** store
**Liên quan:** BR-DECK-022

## Lý do

BR-TRASH-003 nói "MUST NOT suy ra từ parent hiện tại" vì hai batch chồng nhau trong
cùng một subtree là trạng thái hợp lệ và bình thường: xoá một card hôm nay, xoá
deck chứa nó tuần sau. Parent trả lời *nó ở đâu*, không trả lời *nó đi cùng ai*.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
