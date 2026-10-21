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
| Study Entry của deck mà nó và các deck con không còn thẻ nào sống (kể cả khi thẻ cuối rời đi lúc màn đang mở: vào Thùng rác, bị chuyển đi, bị pull xoá) | Vẫn là trạng thái trống bình thường, nhưng tiêu đề và mô tả nói deck chưa có thẻ ("No cards yet"), MUST NOT nói mọi thẻ đã học và đang nghỉ (chủ dự án 2026-10-21) |
| Study Entry của deck có thẻ, mọi thẻ đã học và chưa đến hạn | Tiêu đề nêu đúng deck này ("Nothing to study in this deck"), để không mâu thuẫn với Continue của phiên ở deck khác phía trên (chủ dự án 2026-10-21) |
