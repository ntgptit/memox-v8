---
id: UC-TOPIK-004
title: Xem tổng kết lượt làm bài
status: ready
rules: [BR-CORE-005, BR-TOPIK-013, BR-TOPIK-019, BR-TOPIK-023, BR-TOPIK-024, BR-TOPIK-025]
code: [lib/features/topik/domain/usecases/watch_topik_summary_use_case.dart, lib/features/topik/domain/models/topik_attempt_summary_model.dart, lib/features/topik/presentation/screens/topik_summary_screen.dart, lib/features/topik/presentation/providers/topik_summary_provider.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Nộp bài (UC-TOPIK-003), hoặc chạm Summary của một lượt đã nộp
**Preconditions:** Lượt ở trạng thái `completed`.

## Main flow

**Main flow:**
1. Hệ thống mở Summary (màn 38): tên đề và phần thi, ngày giờ, thời lượng, điểm `score / max_score`, donut số câu đúng, Accuracy, Answered, Unanswered, Longest (BR-TOPIK-023, BR-TOPIK-025).
2. Biểu đồ thời gian từng câu cuộn ngang: một cột mỗi câu, chiều cao theo thời gian, màu theo trạng thái (đúng, sai, bỏ trống), kèm chú giải màu. Chạm một cột mở Review ở câu đó (UC-TOPIK-005); không có tooltip.
3. Danh sách câu theo số câu thật, mỗi câu một hàng: số câu, Your answer và Right answer là số lựa chọn ①–④ (không phải văn bản), thời gian và nhãn trạng thái Correct, Wrong hoặc Unanswered; chạm hàng mở Review ở câu đó (BR-TOPIK-023).
4. Thống kê theo dạng câu: đúng / tổng cho mỗi dạng và dạng yếu nhất (BR-TOPIK-024).
5. Người dùng chọn bộ lọc All, Wrong, Unanswered hoặc Correct: biểu đồ và danh sách chỉ còn các câu đó.
6. Người dùng chạm biểu tượng mắt ("Hide answers" / "Show answers"): phần Right answer của mọi hàng ẩn hoặc hiện.
7. Người dùng chạm một hàng: Review mở ở câu đó (UC-TOPIK-005).
8. Chân màn có Done (về chi tiết đề) và Review answers (mở Review ở câu đầu). Summary thay màn làm bài trong ngăn xếp (UC-TOPIK-003 bước 6), nên Back cũng về chi tiết đề.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Bộ lọc không có câu nào:** thông báo không có câu nào ở trạng thái đó, thay cho biểu đồ và danh sách (BR-TOPIK-023).
- **A2 — Nội dung đã đổi, không còn hoặc không đọc được:** Summary vẫn hiện đầy đủ từ bản chốt; nó không đọc nội dung đề (BR-TOPIK-019).

**Error flows:**
- **E1 — Lượt không còn** (xoá ở máy khác qua đồng bộ, đổi tài khoản) **hoặc chưa nộp** (deep link): hiện trạng thái lượt không còn với đường quay lại chi tiết đề.
- **E2 — Đọc dữ liệu thất bại:** lý do đã localize theo kiểu failure cùng Retry (BR-CORE-005).

## UI

**UI states:** loading · loaded · bộ lọc rỗng (A1) · lượt không còn (E1) · error + retry (E2). Màn hình: [38](../../../shared/ui/screen-handoff/38-topik-summary.md).

## Local

**Postconditions:** Database không đổi; UC chỉ đọc.

## API

Không áp dụng — UC chạy trên Drift và nội dung đóng gói, không gọi mạng; đồng bộ lượt đã nộp chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), BR-TOPIK-026).

## Acceptance criteria

- [ ] **Given** lượt TOPIK I đọc sai câu 31 (2 điểm) và 45 (3 điểm), đúng mọi câu khác, **when** mở Summary, **then** điểm hiện `95 / 100` và bảng có hàng 31 và 45 ở trạng thái Wrong (BR-TOPIK-023).
- [ ] **Given** lượt đúng hết, **when** mở Summary, **then** điểm hiện `100 / 100` không bị cắt; **given** lượt không trả lời câu nào, **then** `0 / 100` (BR-TOPIK-023, BR-TOPIK-025).
- [ ] **Given** người dùng chọn ③ ở câu 21 và đáp án là ①, **when** đọc hàng của câu 21, **then** ghi Your answer ③ và Right answer ①, không phải văn bản (BR-TOPIK-023).
- [ ] **Given** Summary đã mở, **when** chạm một cột của biểu đồ, **then** Review mở ở câu của cột đó.
- [ ] **Given** Summary đã mở, **when** chạm biểu tượng mắt, **then** Right answer ẩn ở mọi hàng và hiện lại khi chạm lần nữa.
- [ ] **Given** `R2_ordering` 1/3 và `R2_headline` 1/3 và mọi dạng khác đúng hết, **when** đọc thống kê theo dạng, **then** dạng yếu nhất là dạng đứng trước trong enum (BR-TOPIK-024).
- [ ] **Given** lượt đúng hết, **when** chọn bộ lọc Wrong, **then** hiện thông báo không có câu sai (A1).
- [ ] **Given** nội dung của đề không còn trong app, hoặc không đọc được, **when** mở Summary của lượt cũ, **then** điểm, danh sách câu và thống kê vẫn hiện từ bản chốt (BR-TOPIK-019).
