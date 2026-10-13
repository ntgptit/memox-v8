---
id: UC-STUDY-007
title: Nhớ lại nghĩa trong 20 giây ở mode recall
status: ready
rules: [BR-MODE-011, BR-MODE-012, BR-STUDY-018, BR-STUDY-031, BR-STUDY-032, BR-STUDY-033, BR-STUDY-059, BR-STUDY-063, BR-STUDY-064, BR-STUDY-065, BR-STUDY-066, BR-STUDY-070]
code: [lib/features/study_mode/domain/models/recall_mode.dart, lib/features/study_mode/domain/models/graded_mode.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/domain/usecases/reveal_recall_answer_use_case.dart, lib/features/study/domain/usecases/save_recall_time_use_case.dart, lib/features/study/presentation/widgets/sections/study_recall_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Stage `recall` đến lượt trong một phiên học mới của deck `eight_box`
(stage thứ tư, sau `guess`), hoặc người dùng chọn `recall` ở màn chọn mode ôn tập
(UC-STUDY-001 bước 4)
**Preconditions:** Root deck chạy `eight_box`. `recall` chạy được với một thẻ

## Main flow

**Main flow:**
1. Màn hiện mặt trước của thẻ và đồng hồ 20 giây với dòng "Recall the meaning
   before the time runs out". Đồng hồ bắt đầu khi thẻ đã hiện, nên thời gian tải
   không bị tính (BR-STUDY-031).
2. Đồng hồ chỉ chạy khi app ở tiền cảnh: app vào nền hoặc bị hệ điều hành ngắt thì
   nó dừng, quay lại thì chạy tiếp. Thời gian còn lại được lưu khi app vào nền, và
   chỉ giảm, không bao giờ tăng (BR-STUDY-031).
3. Người dùng bấm `Show the meaning` trước khi hết giờ. Mở đáp án **không phải kết
   cục**: hệ thống dừng đồng hồ, lưu trạng thái đã mở, không ghi `review_log` và
   không chấm gì (BR-STUDY-065).
4. Mặt sau hiện ra cùng hai lựa chọn tự đánh giá, `Forgot` và `Remembered`
   (BR-STUDY-065).
5. Người dùng chọn một. Kết quả nhị phân ánh xạ `Remembered` → `remembered`,
   `Forgot` → `forgotten` (BR-MODE-011, BR-MODE-012, BR-STUDY-070), và đúng một dòng
   `review_log` được ghi cho lượt (BR-STUDY-032).
6. Sau khi commit, thẻ kế hiện ra ngay: không giữ thêm thời lượng cố định và không
   có nút Tiếp theo (BR-STUDY-066, BR-STUDY-063).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Hết giờ:** đồng hồ về 0 trước khi người dùng mở đáp án. Kết cục bị khoá là
  sai: hệ thống ghi `forgotten` với lý do `timeout` (BR-STUDY-033). Chỉ sau khi
  commit, màn mới hiện mặt sau, nhãn "Counted as forgot" và nút `Continue`; nó không
  tự chuyển theo thời lượng. `Continue` chỉ chuyển lượt và không ghi thêm gì
  (BR-STUDY-066, BR-STUDY-063).
- **A2 — Mốc hết giờ:** chỉ một nhánh thắng. Mở đáp án trước mốc là reveal; tại hoặc
  sau mốc là hết giờ. Một thẻ đã mở đáp án không thể bị ghi hết giờ, và một lượt
  không vừa vào tự đánh giá vừa ghi hết giờ (BR-STUDY-032).
- **A3 — Trả lời sai hoặc hết giờ:** thẻ vào tập không đạt và quay lại ở round sau
  (BR-STUDY-059). Dòng "This card comes back in a later round" nói điều đó khi hết giờ.
- **A4 — Tiếp tục phiên:** thẻ chưa mở đáp án chạy tiếp từ thời gian còn lại đã
  lưu; thẻ đã mở đáp án hiện lại ở bước tự đánh giá với đồng hồ đã dừng; thời gian
  đã lưu bằng 0 thì đi thẳng vào A1.

**Error flows:**
- **E1 — Database đang bận khi ghi:** không ghi gì, không chuyển lượt, banner `Retry`
  gửi lại đúng câu trả lời. Sau hết giờ, retry gửi lại đúng kết cục sai đó và không
  mở lại lựa chọn cho người dùng (BR-STUDY-033, BR-STUDY-063).
- **E2 — Lỗi ghi không tiếp tục được:** transaction rollback, phiên thành `failed`
  với `persistence_error`, và màn tổng kết hiện ra (BR-STUDY-018).
- **E3 — Ghi trạng thái mở đáp án thất bại:** đồng hồ chạy tiếp và người dùng mở lại
  được; chưa có gì được chấm.

## UI

**UI states:** counting (đồng hồ chạy, `Time to recall`) · revealed (mặt sau, hai
nút tự đánh giá, `Revealed with time left`) · timed out (mặt sau, "Counted as
forgot", `Continue`, `Time is up`) · submitting · unsaved (banner Retry). Mỗi thay
đổi trạng thái có một khoảng chặn chạm ngắn để một cú chạm không rơi vào nút vừa
đổi.

## Local

**Postconditions:** mỗi lượt ghi tối đa một dòng `review_log` với
`mode = 'recall'`; `outcome_reason = 'timeout'` chỉ khi hết giờ. Mở đáp án và thời
gian còn lại chỉ ghi vào dòng `study_queue_items` của thẻ (`is_revealed`,
`remaining_ms`), không vào lịch sử. `kind` và lịch theo UC-STUDY-001 bước 7–8.

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** một thẻ `recall` vừa hiện, **when** người dùng chờ, **then** đồng hồ đếm từ 20 giây và không tính thời gian tải nội dung (BR-STUDY-031).
- [ ] **Given** đồng hồ còn 12 giây, **when** app vào nền rồi quay lại, **then** đồng hồ tiếp tục từ 12 giây, không ít hơn vì thời gian ở nền (BR-STUDY-031).
- [ ] **Given** đồng hồ đang chạy, **when** người dùng bấm `Show the meaning`, **then** không có dòng `review_log` nào được ghi, đồng hồ dừng và hai nút `Forgot`/`Remembered` hiện ra (BR-STUDY-065).
- [ ] **Given** đáp án đã mở, **when** người dùng bấm `Remembered`, **then** đúng một lượt `remembered` được ghi và thẻ kế hiện ra ngay, không có nút Tiếp theo (BR-STUDY-032, BR-STUDY-066).
- [ ] **Given** đồng hồ về 0, **when** lượt được ghi, **then** action là `forgotten` với lý do `timeout`, mặt sau chỉ hiện sau commit, và màn chờ người dùng bấm `Continue` (BR-STUDY-033, BR-STUDY-066, A1).
- [ ] **Given** màn đang ở trạng thái hết giờ, **when** người dùng bấm `Continue`, **then** lượt chuyển và không có dòng `review_log` nào được ghi thêm (BR-STUDY-066, A1).
- [ ] **Given** ghi lượt hết giờ gặp database bận, **when** người dùng bấm `Retry`, **then** đúng kết cục sai đó được gửi lại và không có cách chọn `Remembered` cho lượt này (BR-STUDY-033, E1).
- [ ] **Given** đáp án đã mở, **when** người dùng thoát rồi Continue, **then** thẻ hiện lại ở bước tự đánh giá với đồng hồ đã dừng (BR-STUDY-065, A4).
