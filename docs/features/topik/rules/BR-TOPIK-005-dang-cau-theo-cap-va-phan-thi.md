---
id: BR-TOPIK-005
title: Dạng câu theo cấp và phần thi
status: active
summary: Mỗi câu mang một `questionType` thuộc tập dạng của cấp và phần thi; lệch bản đồ số câu mặc định chỉ là cảnh báo.
superseded_by:
---
## Rule

Mỗi câu MUST có `questionType` thuộc tập của (cấp, phần thi): `L1_*` cho TOPIK I nghe, `R1_*` cho TOPIK I đọc, `L2_*` cho TOPIK II nghe, `R2_*` cho TOPIK II đọc, theo bảng của [spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §4.4.

Bản đồ "số câu → dạng" mặc định ổn định qua các kỳ công khai nhưng **không** bất biến: một câu lệch bản đồ chỉ sinh cảnh báo ở lint, không loại đề. Dạng câu dùng cho thống kê theo dạng (BR-TOPIK-024).

**Enforced by:** rule
**Liên quan:** BR-TOPIK-008, BR-TOPIK-024

## Lý do

Thống kê điểm yếu theo dạng câu cần nhãn dạng tin được; nhưng NIIED có thể đổi bố cục một kỳ, nên ép cứng bản đồ sẽ chặn nội dung thật.

## Ví dụ

Câu 13 của TOPIK II đọc mang `R2_ordering`.

## Edge case

Câu TOPIK I nghe mang `R2_theme` (dạng của cấp và phần thi khác) làm đề bị loại; câu 13 TOPIK II đọc mang `R2_paragraph_blank` chỉ sinh cảnh báo.
