---
id: UC-TOPIK-002
title: Xem chi tiết đề và lịch sử
status: ready
rules: [BR-CORE-005, BR-TOPIK-011, BR-TOPIK-018, BR-TOPIK-020, BR-TOPIK-021, BR-TOPIK-025, BR-TOPIK-026, BR-TOPIK-027]
code: [lib/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart, lib/features/topik/domain/usecases/delete_topik_attempt_use_case.dart, lib/features/topik/domain/models/topik_test_progress_model.dart, lib/features/topik/presentation/screens/topik_test_detail_screen.dart, lib/features/topik/presentation/controllers/topik_test_detail_controller.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm một đề trên danh sách (màn 35) hoặc mở deep link `/study/topik/test/:testId`
**Preconditions:** Không có.

## Main flow

**Main flow:**
1. Hệ thống mở chi tiết đề (màn 36) ở tab Overview: thẻ Overall Progress (Sessions, Completed, Completion, Accuracy, Best, Average, Last activity, Total time, kèm ghi chú điểm chỉ tính lượt đã nộp) và Recent Attempts gồm năm lượt mới nhất (BR-TOPIK-020, BR-TOPIK-021). Chạm một lượt trong Recent Attempts mở Summary khi đã nộp, mở lại lượt khi đang dở.
2. Người dùng chạm tab History: mọi lượt, mới nhất trước; mỗi lượt có số thứ tự, trạng thái, ngày giờ và thời lượng, lượt đã nộp thêm điểm và số câu đúng / tổng (BR-TOPIK-021, BR-TOPIK-025). Mỗi hành động của hàng được đặt tên kèm số thứ tự lượt cho TalkBack.
3. Lượt đã nộp có hai hành động Summary và Review; lượt dở có hành động Tiếp tục (UC-TOPIK-003).
4. Người dùng xoá một lượt: hệ thống hỏi xác nhận, rồi xoá lượt cùng đáp án; số thứ tự và thống kê tính lại (BR-TOPIK-018).
5. Người dùng chạm nút bắt đầu: hệ thống bắt đầu một lượt (UC-TOPIK-003).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Đề chưa có lượt nào:** Overview hiện trạng thái rỗng kèm nút bắt đầu; History rỗng nói chưa có lượt nào.
- **A2 — Bắt đầu khi đề đang có lượt dở trên máy này:** hệ thống hỏi Tiếp tục hay Bắt đầu mới; Bắt đầu mới cần thêm một xác nhận (BR-TOPIK-011).
- **A3 — Một lượt đồng bộ về từ máy khác:** Overview và History tự cập nhật.
- **A4 — Huỷ xác nhận xoá:** không đổi gì.
- **A6 — Bắt đầu bị từ chối** (đề không còn trong gói, hoặc một lượt dở vừa xuất hiện): thông báo nêu lý do, màn giữ nguyên (BR-TOPIK-011, BR-TOPIK-019).
- **A5 — Tài khoản đổi khi màn đang mở:** lượt cục bộ bị xoá (BR-TOPIK-027); màn về trạng thái chưa có lượt, rồi hiện lượt đã nộp của tài khoản mới khi đồng bộ về.

**Error flows:**
- **E1 — Đề của deep link không còn hoặc không hợp lệ:** không phải lỗi; hiện trạng thái rỗng riêng với đường quay lại danh sách, không có Retry.
- **E2 — Đọc dữ liệu thất bại:** lý do đã localize theo kiểu failure cùng Retry (BR-CORE-005).
- **E3 — Xoá thất bại:** thông báo không có gì bị mất và cho thử lại; lượt vẫn còn.

## UI

**UI states:** loading · có lượt · chưa có lượt (A1) · đề không còn (E1) · error + retry · xác nhận xoá · hỏi Tiếp tục / Bắt đầu mới · xác nhận Bắt đầu mới · bắt đầu bị từ chối (A6). Màn hình: [36](../../../shared/ui/screen-handoff/36-topik-test-detail.md).

## Local

**Postconditions:** Chỉ bước 4 ghi: lượt và đáp án của nó bị xoá trong một transaction; lượt đã nộp tạo một thao tác xoá để đồng bộ (BR-TOPIK-018, BR-TOPIK-026).

## API

Không áp dụng — UC chạy trên Drift và nội dung đóng gói, không gọi mạng; đồng bộ lượt đã nộp chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), BR-TOPIK-026).

## Acceptance criteria

- [ ] **Given** ba lượt đã nộp 80, 90, 85 và một lượt dở, **when** mở Overview, **then** Sessions 4, Completed 3, Completion 75%, Best 90, Average 85 (BR-TOPIK-020).
- [ ] **Given** bảy lượt, **when** mở Overview, **then** Recent Attempts hiện #7 đến #3, mới nhất trước (BR-TOPIK-021).
- [ ] **Given** ba lượt, **when** xoá lượt #2 và xác nhận, **then** lượt và đáp án của nó không còn trong database, lượt #3 cũ thành #2 (BR-TOPIK-018, BR-TOPIK-021).
- [ ] **Given** đề có lượt dở trên máy này, **when** chạm bắt đầu, **then** hệ thống hỏi Tiếp tục hay Bắt đầu mới và không tạo lượt dở thứ hai (BR-TOPIK-011).
- [ ] **Given** đề chưa có lượt nào, **when** mở Overview, **then** hiện trạng thái rỗng kèm nút bắt đầu (A1).
- [ ] **Given** deep link tới một `testId` không có trong gói, **when** mở màn, **then** hiện trạng thái rỗng với đường quay lại, không có Retry (E1).
- [ ] **Given** tổng thời gian các lượt là 3 731 000 ms, **when** mở Overview, **then** Total time hiện `1h 02m 11s` (BR-TOPIK-025).
