---
id: UC-STUDY-004
title: Xem thẻ ở stage browse
status: ready
rules: [BR-MODE-004, BR-MODE-005, BR-MODE-007, BR-STUDY-004, BR-STUDY-018, BR-STUDY-042, BR-STUDY-048, BR-STUDY-063, BR-STUDY-072]
code: [lib/features/study_mode/domain/models/study_mode.dart, lib/features/study_mode/domain/models/browse_mode.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/presentation/widgets/sections/study_browse_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Một phiên học mới (`session_kind = 'learning'`) mở ra; `browse` là stage
đầu của cả hai chuỗi (BR-MODE-004)
**Preconditions:** Phiên do UC-STUDY-001 bước 3 tạo. Chuỗi stage do thuật toán của
root khai báo qua `stageSequence` — `eight_box`: `browse`, `match`, `guess`,
`recall`, `fill`; `sm2`: `browse`, `self_assess` — và UI không hardcode nó (BR-MODE-007)

`browse` là stage duy nhất không có câu hỏi: người học đọc thẻ mới trước khi bị hỏi.
Nó không bao giờ có mặt ở phiên ôn tập.

## Main flow

**Main flow:**
1. Hệ thống hiện thẻ đứng đầu hàng đợi thành một thẻ chia đôi: nửa trên là
   `Term` (mặt trước, phiên âm), nửa dưới là `Meaning` (mặt sau, ví dụ). Không có
   câu hỏi và không có nút chấm.
2. Người dùng sang thẻ kế bằng vuốt trái, nút `Next card`, hoặc action tương ứng
   của trình đọc màn hình — ba đường làm cùng một việc.
3. Hệ thống ghi tiến độ stage: dòng hàng đợi của thẻ thành `completed` và
   `study_session.cursor` tăng một. Không có `action`, không có dòng `review_log`,
   lịch không đổi (BR-MODE-005, BR-STUDY-004).
4. Hết hàng đợi của stage, phiên chuyển sang stage kế trong `stageSequence` trên
   cùng tập thẻ (UC-STUDY-001 A0).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Xem lại thẻ đã qua:** người dùng vuốt phải (hoặc action `Previous card` của
  trình đọc màn hình). Thẻ đã qua trong round hiện ra theo đúng thứ tự đã thấy
  (`position`), kèm nhãn `Looking back`. Đây là **xem, không phải trả lời**: thẻ giữ
  `completed`, `cursor` không lùi, và tiến lại qua thẻ đó không ghi lần hai
  (BR-STUDY-048, BR-STUDY-042). Ở thẻ đầu tiên của round không có gì để xem lại.
- **A2 — Các stage khác:** không stage nào khác có thao tác xem lại (BR-STUDY-048).
- **A3 — Thoát rồi tiếp tục:** hàng đợi và `cursor` được lưu, nên Continue cùng ngày
  học đưa về thẻ `browse` đầu tiên chưa xem (BR-STUDY-072). Vị trí đang xem lại
  không được lưu; nó bắt đầu lại ở thẻ hiện hành.

**Error flows:**
- **E1 — Database đang bận khi ghi:** không có gì được ghi, thẻ ở lại màn hình, và
  banner `Retry` gửi lại đúng thao tác sang thẻ đó (BR-STUDY-063).
- **E2 — Lỗi ghi không tiếp tục được:** transaction rollback, phiên thành `failed`
  với `persistence_error`, và màn tổng kết hiện ra (BR-STUDY-018).

## UI

**UI states:** viewing (thẻ hiện hành) · looking back (thẻ đã qua, nhãn
`Looking back`) · submitting (thao tác sang thẻ kế bị bỏ qua tới khi ghi xong) ·
unsaved (banner Retry). Gợi ý dưới thẻ: "Swipe for next or back · nothing is graded".

## Local

**Postconditions:** mỗi thẻ đã xem có dòng `study_queue_items` ở `completed`;
`study_session.cursor` bằng số thẻ đã xem trong stage. `review_log`, `card_schedule`
và `learned_at` không đổi.

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** một phiên học mới của deck `eight_box` hoặc `sm2`, **when** phiên mở, **then** stage đầu là `browse`, đúng như `stageSequence` của thuật toán khai báo (BR-MODE-004, BR-MODE-007).
- [ ] **Given** một thẻ đang hiện ở `browse`, **when** người dùng sang thẻ kế, **then** dòng hàng đợi thành `completed`, `cursor` tăng một, và không có dòng `review_log` nào được ghi (BR-MODE-005).
- [ ] **Given** đã xem hai thẻ trong round, **when** người dùng vuốt phải hai lần, **then** hai thẻ đó hiện theo thứ tự đã xem với nhãn `Looking back`, và `cursor` không đổi (BR-STUDY-048, A1).
- [ ] **Given** người dùng đang xem lại một thẻ, **when** người dùng tiến lại tới thẻ hiện hành, **then** không có lượt nào được ghi thêm và bộ đếm không nhảy (BR-STUDY-048, BR-STUDY-042, A1).
- [ ] **Given** stage đang chạy không phải `browse`, **when** thẻ hiện ra, **then** không có thao tác xem lại thẻ đã qua (BR-STUDY-048, A2).
- [ ] **Given** database đang bận lúc sang thẻ kế, **when** người dùng bấm `Retry`, **then** đúng thao tác đó được gửi lại và chỉ một lần ghi thành công (BR-STUDY-063, E1).
