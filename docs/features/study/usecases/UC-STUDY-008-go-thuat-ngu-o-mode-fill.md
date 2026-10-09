---
id: UC-STUDY-008
title: Gõ thuật ngữ từ nghĩa ở mode fill
status: ready
rules: [BR-CARD-002, BR-MODE-009, BR-MODE-011, BR-MODE-012, BR-STUDY-018, BR-STUDY-025, BR-STUDY-026, BR-STUDY-027, BR-STUDY-029, BR-STUDY-030, BR-STUDY-059, BR-STUDY-063, BR-STUDY-064, BR-STUDY-071]
code: [lib/features/study_mode/domain/models/fill_mode.dart, lib/features/study_mode/domain/models/graded_mode.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/domain/usecases/show_fill_hint_use_case.dart, lib/features/study/presentation/widgets/sections/study_fill_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Stage `fill` đến lượt trong một phiên học mới của deck `eight_box`
(stage cuối, sau `recall`), hoặc người dùng chọn `fill` ở màn chọn mode ôn tập
(UC-STUDY-001 bước 4)
**Preconditions:** Root deck chạy `eight_box`; thẻ có `example` (BR-STUDY-071)

## Main flow

**Main flow:**
1. Màn hiện **mặt sau** của thẻ (nghĩa) làm đề và một ô nhập "Your answer" đã có
   focus. Người dùng phải gõ **mặt trước** — thuật ngữ (BR-STUDY-026, BR-CARD-002).
2. Người dùng gõ rồi bấm `Check` hoặc Done trên bàn phím. `Check` chỉ bật khi câu
   trả lời không rỗng sau trim (BR-STUDY-029).
3. Hệ thống fold câu trả lời — trim, chuẩn hoá Unicode, hạ hoa — rồi so với
   `front_folded` của thẻ. Phép so **giữ nguyên dấu**: `cong` không khớp `công`
   (BR-STUDY-026). Gợi ý dưới ô nói điều đó: "Case and spaces are ignored, accents
   are not".
4. Kết quả nhị phân ánh xạ đúng → `remembered`, sai → `forgotten` (BR-MODE-011,
   BR-MODE-012). Hệ thống ghi một dòng `review_log` kèm phiên bản chính sách so khớp
   đang dùng và cờ đã dùng gợi ý (BR-STUDY-027). Nội dung người dùng gõ **không**
   được lưu ở đâu cả (BR-STUDY-030).
5. Chỉ sau khi commit, màn mới hiện kết quả (BR-STUDY-063). Đúng thì thẻ kế hiện ra
   ngay. Sai thì màn giữ thẻ: chữ đã gõ bị gạch, thuật ngữ đúng (`front`) hiện bên
   dưới, nhãn "Wrong · comes back next round", và chờ `Continue` (BR-STUDY-026,
   BR-STUDY-064).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Xem gợi ý:** thẻ có `hint` thì có nút `Show hint`. Bấm nó hiện "Hint: …",
  ghi cờ đã dùng gợi ý trên dòng hàng đợi, và giữ nguyên chữ đã gõ. Gợi ý không đổi
  kết quả chấm; nó chỉ được ghi lại ("Using the hint is noted; it changes nothing").
- **A2 — Trả lời sai:** thẻ vào tập không đạt và quay lại ở round sau, với cờ gợi ý
  đặt lại (BR-STUDY-059).
- **A3 — Thẻ không có `example`:** thẻ vắng ở stage `fill` nhưng vẫn có ở các stage
  khác (BR-STUDY-071). Không thẻ nào có `example` thì stage bị bỏ qua ở phiên học
  mới và `fill` bị vô hiệu hoá kèm lý do ở màn chọn mode ôn tập (BR-MODE-009,
  BR-STUDY-025).
- **A4 — Tiếp tục phiên:** cờ gợi ý đã lưu nên gợi ý vẫn hiện; chữ đã gõ dở không
  được lưu và ô nhập trống lại (BR-STUDY-030).

**Error flows:**
- **E1 — Câu trả lời rỗng sau trim:** không sinh lượt, không tiến checkpoint
  (BR-STUDY-029).
- **E2 — Database đang bận khi ghi:** không ghi gì, không chuyển lượt, banner `Retry`
  gửi lại đúng câu trả lời (BR-STUDY-063).
- **E3 — Lỗi ghi không tiếp tục được:** transaction rollback, phiên thành `failed`
  với `persistence_error`, và màn tổng kết hiện ra (BR-STUDY-018).

## UI

**UI states:** typing (ô nhập có focus, `Check` tắt khi rỗng) · hint shown ·
submitting (`Check`, `Show hint`, `Continue` khoá) · wrong (chữ gạch, đáp án,
`Continue`) · unsaved (banner Retry).

## Local

**Postconditions:** mỗi lượt ghi một dòng `review_log` với `mode = 'fill'`,
`comparison_version` là phiên bản chính sách so khớp hiện hành và `used_hint` là 0
hoặc 1; hai cột này chỉ có giá trị ở `fill`. Không cột nào giữ chữ người dùng gõ.
`kind` và lịch theo UC-STUDY-001 bước 7–8.

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** thẻ có mặt trước `Công` và mặt sau là nghĩa của nó, **when** thẻ hiện ở `fill`, **then** đề là mặt sau và người dùng phải gõ mặt trước (BR-STUDY-026).
- [ ] **Given** thẻ có mặt trước `Công`, **when** người dùng gõ `  công `, **then** lượt được chấm đúng; **when** người dùng gõ `cong`, **then** lượt bị chấm sai và đáp án hiện `Công` (BR-STUDY-026).
- [ ] **Given** ô nhập chỉ có khoảng trắng, **when** người dùng bấm Done, **then** không có lượt nào được ghi và checkpoint không đổi (BR-STUDY-029, E1).
- [ ] **Given** một lượt `fill` vừa được ghi, **when** đọc `review_log` và `study_queue_items`, **then** dòng log có `comparison_version` và `used_hint`, và không nơi nào chứa chữ người dùng đã gõ (BR-STUDY-027, BR-STUDY-030).
- [ ] **Given** người dùng đã bấm `Show hint` rồi trả lời đúng, **when** lượt được ghi, **then** action vẫn là `remembered` và `used_hint = 1` (A1).
- [ ] **Given** một deck có thẻ không có `example`, **when** phiên học mới chạy, **then** thẻ đó vắng ở `fill` nhưng có ở các stage khác (BR-STUDY-071, A3).
- [ ] **Given** người dùng vừa bấm `Check`, **when** transaction chưa commit hoặc database bận, **then** chưa có kết quả nào hiện và lượt không chuyển (BR-STUDY-063, E2).
