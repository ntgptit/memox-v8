---
id: BR-TOPIK-013
title: Chấm điểm khi nộp và chốt kết quả
status: active
summary: Khi nộp, mỗi câu được chấm đúng/sai/bỏ trống theo nội dung hiện tại, điểm là tổng điểm các câu đúng, và kết quả được chốt vào lượt cùng từng đáp án.
superseded_by:
---
## Rule

Khi nộp, với mỗi câu:

- `correct` khi `selected_idx = answerIdx`; `wrong` khi chọn chỉ số khác; `unanswered` khi chưa chọn.
- `points_earned = points` khi `correct`, ngược lại 0.

Lượt MUST lưu `score = Σ points_earned`, `max_score = Σ points`, `correct_count`, `answered_count`, `question_count`, `content_version` và `completed_at`. Mỗi đáp án MUST lưu bản chốt `correct_idx`, `points`, `points_earned` và `question_type`.

Khi lượt còn `in_progress`, MUST NOT lưu gì về đúng sai: bản sửa nội dung có trước lúc nộp là bản dùng để chấm.

**Enforced by:** rule + store
**Liên quan:** BR-TOPIK-002, BR-TOPIK-003, BR-TOPIK-010, BR-TOPIK-019

## Lý do

Chốt kết quả làm điểm cũ không đổi khi nội dung được sửa về sau, và cho Summary hiện được mà không cần nội dung.

## Ví dụ

TOPIK I nghe: đúng câu 1 (4 điểm) và câu 3 (3 điểm), sai câu 2, bỏ trống các câu khác: `score = 7`, `correct_count = 2`, `answered_count = 3`.

## Edge case

Đúng mọi câu: `score = max_score = 100`. Không trả lời câu nào: `score = 0`, `answered_count = 0`.
