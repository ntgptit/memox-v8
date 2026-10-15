---
id: BR-TOPIK-001
title: Cấu trúc đề theo cấp và phần thi
status: active
summary: Mỗi đề có đúng số câu và dải số câu thật của (cấp, phần thi): TOPIK I nghe 30 câu 1–30, đọc 40 câu 31–70; TOPIK II nghe và đọc 50 câu 1–50.
superseded_by:
---
## Rule

Một đề (`TopikTest`) là bộ (cấp, kỳ, phần thi) của đề PBT NIIED công khai. Đề MUST có đúng số câu và dải số câu sau, số liên tục và không trùng:

| Cấp · phần thi | Số câu | Số thứ tự | Thời gian chính thức |
|---|---|---|---|
| TOPIK I · 듣기 | 30 | 1–30 | 40 phút |
| TOPIK I · 읽기 | 40 | **31–70** | 60 phút |
| TOPIK II · 듣기 | 50 | 1–50 | 60 phút |
| TOPIK II · 읽기 | 50 | 1–50 | 70 phút |

Số câu MUST giữ nguyên số thật của đề ở mọi nơi hiển thị (navigator, Summary, biểu đồ, Review). MVP chỉ nhận `format = pbt` và hai phần thi nghe, đọc; 쓰기 thuộc Phase C ([ADR-023](../../../shared/decisions/ADR-023-luyen-de-topik.md)).

**Enforced by:** rule
**Liên quan:** BR-TOPIK-002, BR-TOPIK-008

## Lý do

Người học so kết quả với đề giấy và đáp án chính thức theo số câu thật; đánh số lại từ 1 cho TOPIK I đọc làm lệch mọi tra cứu.

## Ví dụ

Đề `topik1-96-reading` có 40 câu đánh số 31–70; câu đầu trong navigator và trong bảng Summary là 31.

## Edge case

Đề có 39 câu, hoặc nhảy từ 44 sang 46, bị loại khi nạp (BR-TOPIK-008).
