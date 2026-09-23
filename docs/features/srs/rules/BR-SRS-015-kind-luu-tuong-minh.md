---
id: BR-SRS-015
title: kind lưu tường minh
status: active
summary: `kind` được lưu tường minh lúc ghi, không suy từ trạng thái trước và sau.
superseded_by:
---
## Rule

`kind` MUST được lưu tường minh tại thời điểm ghi. MUST NOT suy luận bằng cách so sánh trạng thái trước và sau.

**Enforced by:** store

## Lý do

BR-SRS-015 đáng nói vì cách suy luận nghe rất hợp lý: "trước và sau giống nhau thì là
relearning". Nó sai ở đúng một trường hợp và trường hợp đó không hiếm — một lượt
`scheduled` trên card ở box 8 trả lời `remembered` cũng có `previous_box == 8` và
`next_box == 8`. Suy luận sẽ gắn nhãn nó là `relearning` và mọi thống kê về sau
đều lệch.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
