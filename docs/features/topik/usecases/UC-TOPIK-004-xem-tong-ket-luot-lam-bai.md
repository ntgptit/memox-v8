---
id: UC-TOPIK-004
title: Xem tổng kết lượt làm bài
status: draft
rules: [BR-TOPIK-013, BR-TOPIK-019, BR-TOPIK-023, BR-TOPIK-024, BR-TOPIK-025]
code: []
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Nộp bài (UC-TOPIK-003), hoặc chạm Summary của một lượt đã nộp
**Preconditions:** Lượt ở trạng thái `completed`.

## Main flow

**Main flow:**
1. Hệ thống mở Summary (màn 38): tên đề và phần thi, ngày giờ, thời lượng, điểm `score / max_score`, donut số câu đúng, Accuracy, Answered, Unanswered, Longest (BR-TOPIK-023, BR-TOPIK-025).
2. Biểu đồ thời gian từng câu cuộn ngang, một cột mỗi câu, màu theo trạng thái; chạm một cột hiện thời gian của câu đó.
3. Bảng No · Your · Correct · Time · Status theo số câu thật, Your và Correct là số lựa chọn ①–④ (BR-TOPIK-023).
4. Thống kê theo dạng câu: đúng / tổng cho mỗi dạng và dạng yếu nhất (BR-TOPIK-024).
5. Người dùng chọn bộ lọc All, Wrong, Unanswered hoặc Correct: biểu đồ và bảng chỉ còn các câu đó.
6. Người dùng chạm công tắc mắt: cột Correct ẩn hoặc hiện.
7. Người dùng chạm một hàng: Review mở ở câu đó (UC-TOPIK-005).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Bộ lọc không có câu nào:** thông báo không có câu nào ở trạng thái đó, không phải bảng rỗng (BR-TOPIK-023).
- **A2 — Nội dung đã đổi hoặc không còn:** Summary vẫn hiện đầy đủ từ bản chốt (BR-TOPIK-019).

**Error flows:**
- **E1 — Lượt không còn** (xoá ở máy khác qua đồng bộ, đổi tài khoản): hiện trạng thái lượt không còn với đường quay lại.

## UI

**UI states:** loaded · bộ lọc rỗng (A1) · lượt không còn (E1).

## Local

**Postconditions:** Database không đổi; UC chỉ đọc.

## API

Không áp dụng — UC chạy trên Drift và nội dung đóng gói, không gọi mạng; đồng bộ lượt đã nộp chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), BR-TOPIK-026).

## Acceptance criteria

- [ ] **Given** lượt TOPIK I đọc sai câu 31 (2 điểm) và 45 (3 điểm), đúng mọi câu khác, **when** mở Summary, **then** điểm hiện `95 / 100` và bảng có hàng 31 và 45 ở trạng thái Wrong (BR-TOPIK-023).
- [ ] **Given** lượt đúng hết, **when** mở Summary, **then** điểm hiện `100 / 100` không bị cắt; **given** lượt không trả lời câu nào, **then** `0 / 100` (BR-TOPIK-023, BR-TOPIK-025).
- [ ] **Given** người dùng chọn ③ ở câu 21 và đáp án là ①, **when** đọc bảng, **then** Your là ③, Correct là ①, không phải văn bản (BR-TOPIK-023).
- [ ] **Given** `R2_ordering` 1/3 và `R2_headline` 1/3 và mọi dạng khác đúng hết, **when** đọc thống kê theo dạng, **then** dạng yếu nhất là dạng đứng trước trong enum (BR-TOPIK-024).
- [ ] **Given** lượt đúng hết, **when** chọn bộ lọc Wrong, **then** hiện thông báo không có câu sai (A1).
- [ ] **Given** nội dung của đề không còn trong app, **when** mở Summary của lượt cũ, **then** điểm, bảng và thống kê vẫn hiện từ bản chốt (BR-TOPIK-019).
