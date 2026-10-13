---
id: UC-STUDY-006
title: Chọn nghĩa đúng trong năm lựa chọn ở mode guess
status: ready
rules: [BR-MODE-009, BR-MODE-011, BR-MODE-012, BR-STUDY-018, BR-STUDY-025, BR-STUDY-037, BR-STUDY-038, BR-STUDY-039, BR-STUDY-040, BR-STUDY-041, BR-STUDY-042, BR-STUDY-043, BR-STUDY-059, BR-STUDY-061, BR-STUDY-063, BR-STUDY-064, BR-TRASH-004]
code: [lib/features/study_mode/domain/models/guess_mode.dart, lib/features/study_mode/domain/models/graded_mode.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/presentation/widgets/sections/study_guess_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Stage `guess` đến lượt trong một phiên học mới của deck `eight_box`
(stage thứ ba, sau `match`), hoặc người dùng chọn `guess` ở màn chọn mode ôn tập
(UC-STUDY-001 bước 4)
**Preconditions:** Root deck chạy `eight_box`; nguồn distractor có ít nhất năm nghĩa
khác nhau đo bằng `back_folded` (BR-STUDY-038, BR-STUDY-039)

## Main flow

**Main flow:**
1. Khi một round bắt đầu, hệ thống dựng cho mỗi thẻ một question: đề là **mặt
   trước**, năm lựa chọn là **mặt sau** của năm thẻ — thẻ đang hỏi đúng một lần và
   bốn distractor (BR-STUDY-037).
2. Distractor lấy từ thẻ cùng cây deck, chưa ở Trash, **đã học xong**
   (`learned_at IS NOT NULL`) **hoặc thuộc tập thẻ của phiên**, khác thẻ đang hỏi
   (BR-STUDY-038). Năm lựa chọn có năm `back_folded` khác nhau (BR-STUDY-039).
3. Thứ tự thẻ trong round và thứ tự năm lựa chọn là hai hoán vị độc lập, cả hai
   được lưu nên không đổi khi tiếp tục phiên (BR-STUDY-043, BR-STUDY-061).
4. Màn hiện đề "What is this?", năm lựa chọn A–E và gợi ý "Only your first pick
   counts".
5. Người dùng chạm một lựa chọn. Chỉ lần chạm đầu được nhận; trong lúc ghi, các
   lựa chọn khoá (BR-STUDY-042).
6. Hệ thống chấm bằng **định danh** của thẻ được chọn, không bằng chuỗi hiển thị
   (BR-STUDY-041). Kết quả nhị phân ánh xạ đúng → `remembered`, sai → `forgotten`
   (BR-MODE-011, BR-MODE-012), và một dòng `review_log` được ghi.
7. Chỉ sau khi transaction commit, màn mới tô kết quả: lựa chọn đúng có dấu check;
   nếu chọn sai thì lựa chọn đã chọn có dấu sai và trình đọc màn hình đọc "Wrong.
   The answer is …" (BR-STUDY-063).
8. Kết quả ở lại khoảng 1,2 giây rồi sang thẻ kế; chạm bất kỳ đâu hoặc bấm `Next`
   thì sang ngay. Khi trình đọc màn hình bật, không có đồng hồ, chỉ có `Next`. Màn
   không bị thay bằng trạng thái tải giữa hai lượt (BR-STUDY-064).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Chọn sai:** thẻ rời round hiện tại, vào tập không đạt và quay lại ở round
  sau với một question dựng mới (BR-STUDY-059).
- **A2 — Không đủ năm nghĩa:** stage `guess` bị bỏ qua ở phiên học mới, và bị vô hiệu
  hoá kèm lý do ở màn chọn mode ôn tập. Đây là điều kiện dựng nội dung, không phải
  lỗi và không phải ngưỡng số thẻ (BR-STUDY-040, BR-MODE-009, BR-STUDY-025).
- **A3 — Tiếp tục phiên:** question đã dựng giữ nguyên năm lựa chọn và thứ tự của
  chúng (BR-STUDY-043).
- **A4 — Một thẻ trong hàng đợi hoặc dùng làm lựa chọn bị chuyển vào Trash:** phiên
  kết thúc `invalidated` với `content_deleted` trong cùng transaction xoá
  (BR-TRASH-004, UC-CARD-001 A2).

**Error flows:**
- **E1 — Đủ năm nghĩa nhưng một question không dựng được:** màn chặn với "This
  question can't be shown" và nút `Close`. Không render ít hơn năm lựa chọn, không
  ghi lượt, không bỏ qua thẻ, không tiến checkpoint (BR-STUDY-040, BR-STUDY-037).
  `Close` đi qua hộp thoại thoát của UC-STUDY-001 A3; các lượt đã ghi vẫn giữ.
- **E2 — Database đang bận khi ghi:** không ghi gì, không chuyển lượt, banner `Retry`
  gửi lại câu trả lời (BR-STUDY-063).
- **E3 — Lỗi ghi không tiếp tục được:** transaction rollback, phiên thành `failed`
  với `persistence_error`, và màn tổng kết hiện ra (BR-STUDY-018).

## UI

**UI states:** asking (năm lựa chọn) · submitting (lựa chọn khoá) · right · wrong ·
blocked (E1) · unsaved (banner Retry).

## Local

**Postconditions:** mỗi lượt ghi một dòng `review_log` với `mode = 'guess'`;
`direction`, `outcome_reason`, `comparison_version`, `used_hint` để NULL. `kind` và
lịch theo UC-STUDY-001 bước 7–8. Năm lựa chọn của mỗi question nằm ở
`study_guess_options`, khoá theo round.

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** cây deck có ít nhất năm nghĩa khác nhau trong thẻ đã học hoặc thẻ của phiên, **when** một question `guess` hiện ra, **then** nó có đúng năm lựa chọn với năm `back_folded` khác nhau, đáp án đúng xuất hiện đúng một lần (BR-STUDY-037, BR-STUDY-038, BR-STUDY-039).
- [ ] **Given** một phiên ôn chỉ có ba thẻ đến hạn nhưng cây có hai trăm thẻ đã học, **when** màn chọn mode hiện ra, **then** `guess` dùng được, vì distractor lấy từ thẻ đã học của cây (BR-STUDY-038).
- [ ] **Given** cây có ít hơn năm nghĩa khác nhau trong nguồn distractor, **when** phiên học mới dựng chuỗi stage, **then** `guess` bị bỏ qua mà không hiện lỗi (BR-STUDY-040, A2).
- [ ] **Given** một question đã dựng, **when** câu trả lời mang id của một thẻ, **then** lượt đúng khi và chỉ khi id đó là id của thẻ đang hỏi, và một id không thuộc năm lựa chọn đã lưu bị từ chối mà không ghi gì (BR-STUDY-041).
- [ ] **Given** người dùng đã chạm một lựa chọn, **when** người dùng chạm thêm lựa chọn khác, **then** chỉ một lượt được ghi (BR-STUDY-042).
- [ ] **Given** một question đã hiện, **when** người dùng thoát rồi Continue, **then** question hiện lại với cùng năm lựa chọn theo cùng thứ tự (BR-STUDY-043, A3).
- [ ] **Given** đủ năm nghĩa nhưng một question không dựng được, **when** thẻ đến lượt, **then** màn chặn hiện ra, không ghi lượt và không tiến checkpoint (BR-STUDY-040, E1).
- [ ] **Given** một lựa chọn vừa được chạm, **when** transaction chưa commit hoặc database bận, **then** chưa có kết quả nào được tô, và lượt không chuyển (BR-STUDY-063, E2).
