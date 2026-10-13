---
id: UC-STUDY-005
title: Ghép cặp thuật ngữ và nghĩa ở mode match
status: ready
rules: [BR-MODE-009, BR-MODE-011, BR-MODE-012, BR-STUDY-018, BR-STUDY-025, BR-STUDY-045, BR-STUDY-049, BR-STUDY-059, BR-STUDY-060, BR-STUDY-061, BR-STUDY-062, BR-STUDY-063, BR-STUDY-064, BR-STUDY-070]
code: [lib/features/study_mode/domain/models/match_mode.dart, lib/features/study_mode/domain/models/graded_mode.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/presentation/widgets/sections/study_match_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Stage `match` đến lượt trong một phiên học mới của deck `eight_box`
(stage thứ hai, sau `browse`), hoặc người dùng chọn `match` ở màn chọn mode ôn tập
(UC-STUDY-001 bước 4)
**Preconditions:** Root deck chạy `eight_box`; tập thẻ của stage có ít nhất hai cặp
(BR-STUDY-045). Sàn này áp cho **stage**, không cho từng bàn (BR-STUDY-049)

## Main flow

**Main flow:**
1. Hệ thống chia round thành các **bàn** liên tiếp theo `position`, tối đa năm cặp
   một bàn; bàn cuối lấy phần dư và có thể chỉ có một cặp. Một thẻ ở nguyên bàn
   của nó suốt round (BR-STUDY-049, BR-STUDY-061).
2. Bàn hiện cột thuật ngữ theo `position` và cột nghĩa theo một hoán vị riêng, đã
   lưu, không trùng thứ tự cột thuật ngữ khi bàn có từ hai cặp. Bộ đếm và thanh
   tiến trình ở header đo **cả round**, không phải bàn (BR-STUDY-049).
3. Người dùng chạm một thuật ngữ và một nghĩa, theo thứ tự nào cũng được
   (BR-STUDY-062).
4. Hệ thống chấm: cặp đúng khi `back_folded` của nghĩa đã chạm bằng `back_folded`
   của thẻ sở hữu thuật ngữ. Kết quả là nhị phân và ánh xạ đúng → `remembered`,
   sai → `forgotten` (BR-MODE-011, BR-MODE-012). `match` không có mức phản hồi trung
   gian; mọi mức không phải "đúng" là sai, và không mức nào vào `review_log.action`
   (BR-STUDY-070).
5. Hệ thống ghi một dòng `review_log` cho **thẻ sở hữu thuật ngữ**, kể cả khi cặp sai,
   trong cùng transaction với bước của hàng đợi. Thẻ sở hữu nghĩa bị chạm nhầm
   không bị ghi gì (BR-STUDY-062).
6. Chỉ sau khi transaction commit, bàn mới hiện kết quả (BR-STUDY-063). Cặp đúng
   chuyển sang trạng thái matched ngay; cặp sai nháy màu sai khoảng 600 ms kèm dòng
   "Not a match — this pair comes back next round", rồi bàn nhận chạm tiếp. Bàn
   không bao giờ bị thay bằng màn tải giữa hai lượt (BR-STUDY-064).
7. Hết cặp của một bàn, bàn kế hiện ra. Hết round thì UC-STUDY-001 A0c quyết định:
   còn thẻ trong tập không đạt thì dựng round mới chỉ từ tập đó (BR-STUDY-059).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Cặp sai:** dòng hàng đợi của thẻ sở hữu thuật ngữ ở lại `pending`, nên cặp
  đó ở lại bàn để ghép lại, và thẻ được ghi danh vào round kế **đúng một lần**, dù
  sai bao nhiêu lần hay sau đó ghép đúng (BR-STUDY-062, BR-STUDY-060).
- **A2 — Hai thẻ cùng nghĩa trên một bàn:** chạm nghĩa của thẻ kia vẫn là cặp đúng,
  vì phép chấm so `back_folded`; hai dòng đổi chỗ nghĩa cho nhau để ô đã chạm là ô
  hiện matched.
- **A3 — Ít hơn hai cặp:** ở phiên học mới, stage `match` bị bỏ qua (BR-MODE-009,
  BR-STUDY-025); ở màn chọn mode ôn tập, `match` bị vô hiệu hoá kèm lý do. Đây là
  điều kiện dựng nội dung, không phải ngưỡng số thẻ (BR-STUDY-025).
- **A4 — Tiếp tục phiên:** `position` và thứ tự cột nghĩa đã lưu, nên bàn hiện lại
  đúng chỗ, các cặp đã ghép vẫn matched. Ô đang được chọn dở không được lưu.

**Error flows:**
- **E1 — Database đang bận khi ghi:** không ghi gì, bàn giữ nguyên, banner `Retry`
  gửi lại đúng cặp đó (BR-STUDY-063).
- **E2 — Lỗi ghi không tiếp tục được:** transaction rollback, phiên thành `failed`
  với `persistence_error`, và màn tổng kết hiện ra (BR-STUDY-018).

## UI

**UI states:** idle · selected (một ô đã chọn) · submitting (bàn khoá chạm) ·
matched (cặp đúng) · wrong (nháy 600 ms) · unsaved (banner Retry). Gợi ý: "Tap a
term and its meaning, in either order".

## Local

**Postconditions:** mỗi lần ghép ghi một dòng `review_log` với `mode = 'match'` cho
thẻ sở hữu thuật ngữ; `direction`, `outcome_reason`, `comparison_version`,
`used_hint` để NULL. `kind` và lịch theo UC-STUDY-001 bước 7–8. Cặp đúng đưa dòng
hàng đợi về `completed`; cặp sai giữ nó `pending` và thêm một dòng ở round kế.

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** một round có bảy thẻ, **when** stage `match` chạy, **then** bàn đầu có năm cặp, bàn thứ hai có hai, và header đếm trên bảy (BR-STUDY-049).
- [ ] **Given** tập thẻ của stage chỉ có một thẻ, **when** phiên học mới dựng chuỗi stage, **then** `match` bị bỏ qua; ở màn ôn tập nó bị vô hiệu hoá kèm lý do (BR-STUDY-045, BR-STUDY-025, A3).
- [ ] **Given** một bàn đang mở, **when** người dùng chạm nghĩa trước rồi tới thuật ngữ đúng, **then** cặp được chấp nhận là đúng và lượt thuộc thẻ sở hữu thuật ngữ (BR-STUDY-062).
- [ ] **Given** người dùng ghép thuật ngữ A với nghĩa của thẻ B, **when** lượt được ghi, **then** chỉ thẻ A có dòng `review_log` với action `forgotten`, thẻ B không có dòng nào, và A ở lại bàn (BR-STUDY-062, BR-MODE-012, A1).
- [ ] **Given** thẻ A đã ghép sai hai lần rồi ghép đúng, **when** round kết thúc, **then** A có đúng một dòng ở round kế (BR-STUDY-060, BR-STUDY-062, A1).
- [ ] **Given** một cặp vừa được chạm, **when** transaction chưa commit, **then** bàn chưa hiện đúng hay sai; nếu database bận thì không có kết quả nào hiện và banner `Retry` xuất hiện (BR-STUDY-063, E1).
- [ ] **Given** phiên bị thoát giữa một bàn, **when** người dùng chọn Continue, **then** bàn hiện lại với cùng thứ tự hai cột và các cặp đã ghép vẫn matched (BR-STUDY-061, A4).
