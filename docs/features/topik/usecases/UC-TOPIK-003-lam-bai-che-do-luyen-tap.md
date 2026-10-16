---
id: UC-TOPIK-003
title: Làm bài ở chế độ luyện tập
status: ready
rules: [BR-CORE-005, BR-TOPIK-001, BR-TOPIK-004, BR-TOPIK-008, BR-TOPIK-010, BR-TOPIK-011, BR-TOPIK-012, BR-TOPIK-013, BR-TOPIK-014, BR-TOPIK-015, BR-TOPIK-016, BR-TOPIK-017, BR-TOPIK-019, BR-TOPIK-026, BR-TOPIK-027, BR-TOPIK-028]
code: [lib/features/topik/domain/usecases/start_topik_attempt_use_case.dart, lib/features/topik/domain/usecases/answer_topik_question_use_case.dart, lib/features/topik/domain/usecases/move_topik_question_use_case.dart, lib/features/topik/domain/usecases/record_topik_time_use_case.dart, lib/features/topik/domain/usecases/submit_topik_attempt_use_case.dart, lib/features/topik/domain/usecases/watch_topik_attempt_use_case.dart, lib/features/topik/presentation/screens/topik_attempt_screen.dart, lib/features/topik/presentation/controllers/topik_attempt_controller.dart, lib/features/topik/presentation/controllers/topik_audio_controller.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm nút bắt đầu ở chi tiết đề, hoặc Tiếp tục một lượt dở
**Preconditions:** Đề hợp lệ (BR-TOPIK-008).

## Main flow

**Main flow:**
1. Hệ thống tạo lượt `in_progress` (hoặc mở lượt dở ở câu hiện tại của nó) và mở màn làm bài (màn 37) (BR-TOPIK-010, BR-TOPIK-011).
2. Mỗi trang là một câu, có chỉ thị, đoạn văn hoặc ảnh, và trình phát audio của nhóm phía trên, rồi câu hỏi với bốn lựa chọn ①–④. Thanh tiến độ và vị trí câu dùng số câu thật (BR-TOPIK-001, BR-TOPIK-004).
3. Người dùng chọn một lựa chọn: hệ thống ghi ngay, không báo đúng sai (BR-TOPIK-012, BR-TOPIK-016).
4. Người dùng chuyển câu bằng trước/sau hoặc lưới số câu; thời gian của câu vừa rời được ghi (BR-TOPIK-015).
5. Đề nghe: người dùng phát, dừng, tua, nghe lại, đổi tốc độ trong đoạn audio của nhóm; đổi câu trong cùng nhóm không làm audio phát lại; script mở được khi câu đã có đáp án hoặc qua công tắc (BR-TOPIK-016, BR-TOPIK-017).
6. Người dùng nộp. Hệ thống chấm, chốt kết quả, xếp lượt vào hàng đồng bộ và mở Summary (BR-TOPIK-013, BR-TOPIK-026, UC-TOPIK-004).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Nộp khi còn câu trống:** hệ thống hỏi xác nhận nêu số câu trống; huỷ thì ở lại; xác nhận thì câu trống được 0 điểm (BR-TOPIK-014).
- **A2 — Rời màn, chuyển nền hay app bị kill:** lượt giữ `in_progress` với đáp án và thời gian đã ghi; chuyển nền không cộng thời gian, và thời gian chỉ chạy khi một câu đang hiện trên màn (đang tải, lỗi hay lượt không còn thì không cộng) (BR-TOPIK-010, BR-TOPIK-015).
- **A6 — Mở liên kết tới lượt đã nộp:** màn nói lượt này đã nộp và có đường tới Summary (UC-TOPIK-004).
- **A3 — Quay lại câu đã trả lời và đổi đáp án:** đáp án mới ghi đè, thời gian cộng dồn (BR-TOPIK-012, BR-TOPIK-015).
- **A4 — Đổi ngôn ngữ giao diện giữa chừng:** nhãn đổi theo; đáp án và thời gian không mất.
- **A5 — Chạm nộp lần nữa hoặc Back khi đang nộp:** không có tác dụng (BR-TOPIK-014).

**Error flows:**
- **E1 — Audio không phát được:** trình phát hiện lỗi kèm thử lại; lượt và đáp án không đổi (BR-TOPIK-017).
- **E2 — Lượt không còn** (xoá ở màn khác, đổi tài khoản): màn hiện trạng thái lượt không còn và đường quay lại chi tiết đề.
- **E3 — Tiếp tục khi đề không còn hợp lệ:** không cho tiếp tục, đề nghị xoá lượt (BR-TOPIK-019).
- **E4 — Ghi thất bại:** thông báo lựa chọn chưa được lưu và cho thử lại; không lựa chọn nào được coi là đã lưu khi chưa ghi; thời gian của lần ghi hỏng được giữ và ghi cùng lần ghi sau (BR-CORE-005, BR-TOPIK-015).
- **E5 — Đọc lượt hoặc đề thất bại:** lý do đã localize theo kiểu failure cùng Retry; Close vẫn có; giữa chừng thì chân màn và lưới ẩn (BR-CORE-005).

## UI

**UI states:** loading · đang làm · lỗi audio · xác nhận nộp · đang nộp · lượt không còn · đề không còn hợp lệ · đã nộp (A6) · error + retry (E5). Màn hình: [37](../../../shared/ui/screen-handoff/37-topik-attempt.md).

## Local

**Postconditions:** Bước 1 tạo lượt; bước 3–5 ghi đáp án, câu hiện tại và thời gian; bước 6 chốt lượt `completed` cùng một thao tác đồng bộ trong một transaction (BR-TOPIK-013, BR-TOPIK-026). Server chỉ kiểm tính toàn vẹn của lượt khi nhận nó (BR-TOPIK-028); đổi tài khoản xoá lượt dở (BR-TOPIK-027).

## API

Không áp dụng — UC chạy trên Drift và nội dung đóng gói, không gọi mạng; đồng bộ lượt đã nộp chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), BR-TOPIK-026).

## Acceptance criteria

- [ ] **Given** lượt TOPIK I đọc mới, **when** màn làm bài mở, **then** câu đầu là 31 và lưới số câu đi từ 31 đến 70 (BR-TOPIK-001).
- [ ] **Given** đang ở câu 9, **when** chọn ② rồi chọn ④, **then** database lưu ④ cho câu 9 và màn không báo đúng sai (BR-TOPIK-012, BR-TOPIK-016).
- [ ] **Given** đã chọn đáp án ở 30 câu, **when** app bị kill và mở lại lượt, **then** 30 đáp án và thời gian đã ghi còn nguyên (BR-TOPIK-010, BR-TOPIK-015).
- [ ] **Given** ở câu 5 trong 40 giây, sang câu 6 trong 20 giây, quay lại câu 5 thêm 10 giây, **when** đọc lượt, **then** câu 5 là 50 giây và tổng 70 giây (BR-TOPIK-015).
- [ ] **Given** đang ở câu 5 và app chuyển nền 5 phút, **when** quay lại, **then** câu 5 không cộng 5 phút đó (BR-TOPIK-015).
- [ ] **Given** audio nhóm [21～22] đang phát ở giây 30, **when** chuyển từ câu 21 sang 22, **then** audio phát tiếp từ giây 30 (BR-TOPIK-017).
- [ ] **Given** còn 3 câu trống, **when** chạm Nộp, **then** hệ thống hỏi xác nhận nêu 3 câu; xác nhận thì lượt `completed` với 3 câu `unanswered`, 0 điểm (BR-TOPIK-013, BR-TOPIK-014).
- [ ] **Given** TOPIK I nghe, đúng câu 1 (4 điểm) và câu 3 (3 điểm), sai câu 2, **when** nộp, **then** `score = 7`, `correct_count = 2`, `answered_count = 3`, và mỗi đáp án lưu `correct_idx`, `points`, `points_earned`, `question_type` (BR-TOPIK-013).
- [ ] **Given** lượt vừa nộp, **when** đọc hàng đồng bộ, **then** có đúng một thao tác cho lượt mang cả đáp án; một lượt dở không bao giờ có thao tác nào (BR-TOPIK-026).
- [ ] **Given** đang nộp, **when** chạm Nộp lần nữa, **then** chỉ một lần nộp được ghi (BR-TOPIK-014).
- [ ] **Given** lượt bị xoá ở màn khác khi màn làm bài đang mở, **when** màn nhận thay đổi, **then** hiện trạng thái lượt không còn với đường quay lại (E2).
