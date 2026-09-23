---
id: BR-MODE-014
title: Hai chiều của một lượt
status: active
summary: Chiều của một lượt là `korean_to_meaning` hoặc `meaning_to_korean`; chỉ đổi nội dung hai nửa thẻ.
superseded_by:
---
## Rule

Chiều của **một lượt** MUST là một trong hai: `korean_to_meaning` hiển thị `front` làm đề và `back` làm đáp án; `meaning_to_korean` hiển thị `back` làm đề và `front` làm đáp án. Đề MUST luôn nằm ở nửa trên của thẻ và đáp án ở nửa dưới (BR-MODE-006) — chiều đổi **nội dung** của hai nửa, MUST NOT đổi vị trí, thứ tự đọc, hay hình học của thẻ. Nhãn của mỗi nửa MUST đi theo nội dung nửa đó. Chiều MUST NOT là dấu hiệu chỉ bằng màu.

**Enforced by:** rule + UI
**Liên quan:** BR-CARD-002, BR-MODE-006, BR-MODE-013

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Đọc dòng có chiều do bản mới hơn ghi | Đọc được, vẽ như `korean_to_meaning`, MUST NOT ghi lại giá trị đó (BR-MODE-014) |
