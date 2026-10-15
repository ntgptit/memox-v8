---
id: BR-TOPIK-010
title: Vòng đời của lượt làm bài
status: active
summary: Lượt làm bài đi `in_progress` → `completed` khi nộp, hoặc bị xoá; `completed` là bất biến.
superseded_by:
---
## Rule

Một lượt làm bài (`TopikAttempt`) MUST theo đúng bảng chuyển trạng thái của [spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §5.1:

- Bắt đầu tạo lượt `in_progress` cho một đề hợp lệ.
- Chọn, đổi đáp án và chuyển câu giữ `in_progress`, ghi ngay.
- Rời màn hình, chuyển nền hay app bị kill giữ `in_progress`; lượt tiếp tục được trên chính máy đó.
- Nộp chuyển sang `completed` (BR-TOPIK-013).
- Xoá bỏ lượt ở bất kỳ trạng thái nào (BR-TOPIK-018).

`completed` MUST là bất biến: không đổi đáp án, thời gian hay điểm sau khi nộp; Review chỉ đọc. Không có trạng thái nào khác.

**Enforced by:** rule + store
**Liên quan:** BR-TOPIK-011, BR-TOPIK-013, BR-TOPIK-018, BR-TOPIK-026

## Lý do

Kết quả đã nộp là bằng chứng người học dùng để so tiến bộ; cho sửa sau khi nộp làm mọi thống kê vô nghĩa.

## Ví dụ

Người dùng làm 30 câu, thoát app, mở lại: lượt vẫn `in_progress` với 30 đáp án và đúng thời gian đã dùng.

## Edge case

Gọi ghi đáp án vào lượt `completed` bị từ chối, không đổi gì.
