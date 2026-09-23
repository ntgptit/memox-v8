---
id: BR-CARD-006
title: Bốn trạng thái hiển thị của thẻ
status: active
summary: Trạng thái hiển thị là `new`, `beginning`, `reviewing` hoặc `mastered`, suy ra khi đọc, không lưu cột.
superseded_by:
---
## Rule

Trạng thái hiển thị của một thẻ MUST là một trong bốn: `new`, `beginning`, `reviewing`, `mastered`. Nó MUST được suy ra khi đọc và MUST NOT là cột trong DB.

**Enforced by:** rule
**Liên quan:** BR-SRS-013

## Lý do

BR-SRS-013 đã định nghĩa nửa trên của thang này — "đã thuộc" — cho cả hai scheduler.
Ba rule dưới đây chia phần còn lại, và **không** phát biểu lại BR-SRS-013.

**Bốn trạng thái là nhãn hiển thị, không phải state machine.** Không có chuyển
tiếp nào được định nghĩa giữa chúng và không có gì lưu chúng lại; chúng là một
phép đọc `card_schedule` tại thời điểm vẽ. Thẻ đi lùi từ `reviewing` về
`beginning` sau một lần quên là chuyện bình thường, không phải vi phạm.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
