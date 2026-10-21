---
id: BR-STUDY-008
title: Không thẻ đến hạn là trạng thái bình thường
status: active
summary: Không có thẻ đến hạn là trạng thái bình thường, không phải lỗi, và không mở được phiên ôn tập.
superseded_by:
---
## Rule

Không có thẻ nào đến hạn MUST được trình bày là trạng thái bình thường, không phải lỗi — và MUST NOT có đường nào mở phiên ôn tập khi tập đến hạn rỗng (BR-STUDY-054).

**Enforced by:** UI
**Liên quan:** BR-STUDY-054

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Study Entry của deck không còn thẻ nào (thẻ cuối vào Thùng rác, bị chuyển đi hay bị pull xoá khi màn đang mở) | Vẫn là trạng thái trống bình thường, nhưng mô tả nói deck không có thẻ, MUST NOT nói mọi thẻ đã học và đang nghỉ (chủ dự án 2026-10-21) |
