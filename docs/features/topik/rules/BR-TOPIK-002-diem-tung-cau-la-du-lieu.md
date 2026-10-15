---
id: BR-TOPIK-002
title: Điểm từng câu là dữ liệu của đề
status: active
summary: Điểm của mỗi câu lấy từ 배점표 chính thức trong nội dung, tổng một phần thi bằng 100; domain chỉ cộng, không bao giờ suy ra điểm từ số câu đúng.
superseded_by:
---
## Rule

Mỗi câu MUST mang `points` nguyên dương lấy từ 정답·배점표 chính thức, và tổng `points` của một đề MUST bằng 100. Ràng buộc theo cấp:

| Cấp · phần thi | Điểm mỗi câu |
|---|---|
| TOPIK II · 듣기, 읽기 | đúng 2 |
| TOPIK I · 듣기 | 3 hoặc 4, đổi theo câu và theo kỳ |
| TOPIK I · 읽기 | 2 hoặc 3, đổi theo câu và theo kỳ |

Code MUST NOT giả định "2 điểm một câu" hay "số câu đúng × hằng số". Ràng buộc 3/4 và 2/3 của TOPIK I đến từ khảo sát của chủ dự án và **chờ đối chiếu** với đề kỳ 96; lệch thì lint thất bại và báo chủ dự án, rule sửa ở đây trước.

**Enforced by:** rule
**Liên quan:** BR-TOPIK-001, BR-TOPIK-008, BR-TOPIK-013

## Lý do

Người học dùng điểm để tự đánh giá cấp; điểm sai vì một hằng số làm hỏng đúng mục đích của tính năng.

## Ví dụ

Kỳ 52 TOPIK I nghe: câu 1 được 4 điểm, câu 3 được 3 điểm; đúng cả hai thì `score` cộng 7.

## Edge case

Đề có tổng 98 hoặc một câu 0 điểm bị loại khi nạp (BR-TOPIK-008).
