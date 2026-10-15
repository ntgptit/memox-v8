---
id: BR-TOPIK-024
title: Thống kê theo dạng câu
status: active
summary: Summary hiện đúng/tổng cho mỗi dạng câu của lượt và nêu dạng yếu nhất theo luật hoà cố định.
superseded_by:
---
## Rule

Với mỗi `question_type` có trong lượt, Summary MUST hiện số câu đúng / tổng số câu của dạng đó (theo bản chốt, BR-TOPIK-013).

Dạng yếu nhất là dạng có tỉ lệ đúng thấp nhất trong các dạng có ít nhất hai câu; hoà thì dạng có nhiều câu hơn, rồi theo thứ tự enum. Không nêu dạng yếu nhất khi không dạng nào có hai câu hoặc mọi dạng đều đúng hết.

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-005, BR-TOPIK-013, BR-TOPIK-023

## Lý do

Chủ dự án đưa thống kê theo dạng vào MVP ngày 2026-10-15: dữ liệu đã có sẵn trong bản chốt, và nó chỉ ra người học cần luyện dạng nào.

## Ví dụ

`R2_ordering` 1/3 và `R2_headline` 1/3: hoà tỉ lệ và số câu, dạng đứng trước trong enum là dạng yếu nhất.

## Edge case

Không áp dụng
