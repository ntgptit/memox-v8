---
id: BR-TOPIK-023
title: Số liệu tổng kết một lượt làm bài
status: active
summary: Summary hiện điểm theo 배점, tỉ lệ đúng, số câu trả lời và bỏ trống, câu lâu nhất, biểu đồ thời gian từng câu và bảng câu với số lựa chọn, luôn theo số câu thật.
superseded_by:
---
## Rule

Summary của một lượt đã nộp MUST hiện:

- điểm `score / max_score` (BR-TOPIK-013), không bao giờ là số câu đúng nhân hằng số;
- donut `correct_count / question_count`, Accuracy, Answered, Unanswered;
- Longest: câu có thời gian lớn nhất, hoà thì số nhỏ hơn;
- bộ lọc All, Wrong, Unanswered, Correct;
- một cột thời gian cho mỗi câu, màu theo trạng thái;
- một danh sách câu, mỗi câu một hàng gồm số câu, Your (lựa chọn đã chọn) và Correct (đáp án đúng) là số lựa chọn ①–④ chứ không phải văn bản, Time và Status (bố cục hàng theo di động, không phải bảng năm cột; chủ dự án 2026-10-16); một công tắc ẩn phần Correct của mọi hàng;
- tên đề và phần thi, không phải nhãn chung chung.

Mọi số câu MUST là số thật (TOPIK I đọc bắt đầu từ 31). Bố cục MUST đúng ở 100/100 và 0/100.

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-001, BR-TOPIK-003, BR-TOPIK-013, BR-TOPIK-024, BR-TOPIK-025

## Lý do

Đây là nơi người học đọc kết quả; mỗi số phải đúng nghĩa và hiển thị không vỡ ở hai đầu thang điểm.

## Ví dụ

TOPIK I đọc, sai câu 31 và 45: danh sách có hàng 31 và 45 ở trạng thái Wrong; điểm 95 / 100 nếu hai câu đó 2 và 3 điểm.

## Edge case

Bộ lọc Wrong của một lượt đúng hết: thông báo không có câu sai, không phải danh sách rỗng.
