---
id: UC-STUDY-003
title: Chọn chiều hỏi cho một phiên self-assess
status: ready
rules: [BR-DECK-025, BR-MODE-013, BR-MODE-014, BR-MODE-015, BR-MODE-016, BR-MODE-017, BR-MODE-018, BR-MODE-019, BR-SRS-003, BR-STUDY-005, BR-STUDY-009, BR-STUDY-015, BR-STUDY-020, BR-STUDY-051, BR-STUDY-054, BR-STUDY-055, BR-STUDY-072]
code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/features/study/domain/usecases/open_review_session_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Bấm `Review` ở Study Entry của một deck chạy `sm2`
**Preconditions:** Root deck của deck đang mở dùng scheduler `sm2` (BR-DECK-025), có ít
nhất một thẻ đến hạn (BR-STUDY-054), và mode ôn duy nhất thuật toán này offer là
`self_assess` (BR-STUDY-055) — ba điều kiện của BR-MODE-013

## Main flow

**Main flow:**
1. Người dùng bấm `Review`. Vì `sm2` chỉ offer một mode, hệ thống bỏ qua màn chọn
   mode (BR-STUDY-055) và mở sheet chọn **chiều hỏi**.
2. Hệ thống hiển thị ba lựa chọn — `Term first` (gắn nhãn Recommended; nhãn không
   gọi tên một ngôn ngữ vì thẻ không có trường ngôn ngữ — bảng `card` trong
   `docs/shared/data/schema.md`),
   `Meaning first`, `Mixed` — mỗi lựa chọn kèm một dòng mô tả bằng lời của bài
   tập, và một dòng nói lựa chọn không đổi được sau khi phiên bắt đầu (BR-MODE-017).
3. Người dùng chạm một lựa chọn. Chạm chỉ **chọn**, không mở phiên: lựa chọn bị
   khoá suốt phiên nên một cú chạm nhầm không được phép tiêu mất một phiên
   (BR-MODE-017).
4. Người dùng bấm `Start review`. Hệ thống khoá sheet trong lúc mở phiên — cú
   chạm thứ hai không sinh phiên thứ hai (BR-STUDY-072).
5. Hệ thống mở phiên với chiều đã chọn, materialize hàng đợi trong cùng
   transaction, và gán chiều cho từng dòng: một chiều duy nhất với hai lựa chọn
   cố định, hoặc chia gần đều một lần cho `mixed` (BR-MODE-015).
6. Màn phiên học mở ra. Mỗi thẻ hiện đề ở nửa trên theo chiều của dòng nó, và
   đáp án ở nửa dưới sau khi lật (BR-MODE-014). Tập action vẫn là bốn action của `sm2`
   (BR-STUDY-009) và lịch chạy y như trước (BR-MODE-019).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Đóng sheet:** người dùng vuốt xuống hoặc chạm ra ngoài. Chưa có gì được
  ghi, nên không có session nào để dọn (BR-STUDY-020, BR-MODE-017); màn Study Entry giữ
  nguyên.
- **A2 — Deck chạy `eight_box`:** sheet này không xuất hiện. Lối vào là màn chọn
  mode của BR-STUDY-055, và không đường nào từ đó dẫn tới chiều hỏi (BR-MODE-013).
- **A3 — Còn phiên bỏ dở:** sheet ba lối của BR-STUDY-072 hiện trước. Chọn `Continue`
  đọc chiều đã lưu và **không** hỏi lại (BR-MODE-017); chọn `Review` kết thúc phiên cũ
  rồi đi vào bước 1.
- **A4 — Phiên `mixed` đang chạy:** hai thẻ liên tiếp có thể hỏi hai chiều khác
  nhau. Đó là đúng bài tập người dùng chọn; chiều của mỗi thẻ đã cố định từ bước
  5 và không đổi khi thẻ quay lại (BR-STUDY-005, BR-MODE-015).

**Error flows:**
- **E1 — Deck đổi scheduler hoặc bị reset trong lúc sheet đang mở:** hệ thống đọc
  lại trước khi mở phiên; nếu `self_assess` không còn được offer thì phiên bị từ
  chối như một thay đổi giữa chừng, không ghi gì, và màn vào học hiện banner cảnh
  báo riêng ("Self-check is no longer offered for this deck."), như E2
  (BR-SRS-003, BR-STUDY-015; quyết định của chủ dự án 2026-09-28).
- **E2 — Không còn thẻ đến hạn tại thời điểm bấm Start:** phiên bị từ chối và
  không ghi dòng nào (BR-STUDY-020, BR-STUDY-054); sheet báo lỗi như E1.
- **E3 — Yêu cầu thiếu chiều:** không thể tạo từ UI này; use case vẫn từ chối là
  validation và không ghi session (BR-MODE-018).

## UI

**UI states:** initial (ba lựa chọn, Term first đã chọn sẵn) · submitting
(Start hiện spinner, ba lựa chọn khoá) · failure (dòng lỗi, lựa chọn giữ nguyên,
Start dùng lại được). Không có state `loading` khi mở sheet — điều kiện khả dụng
đã được đọc trước khi sheet mở; không có state `empty`, vì ba lựa chọn là hằng
số.

## Local

**Postconditions:** `study_session.direction` giữ lựa chọn của phiên,
`study_queue_items.direction` giữ chiều thật của từng thẻ, và mỗi lượt ghi vào
`review_log.direction` chiều chép từ dòng hàng đợi (BR-MODE-016). Nội dung thẻ,
`card.updated_at` và toàn bộ lịch SRS không đổi (BR-MODE-019).

## API

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** một root dùng `sm2` có thẻ đến hạn, **when** người dùng bấm Review, **then** hệ thống bỏ qua màn chọn mode và mở sheet chọn chiều với `Term first` chọn sẵn (BR-STUDY-055, BR-MODE-013).
- [ ] **Given** sheet chọn chiều đang mở, **when** người dùng chọn `Meaning first` rồi bấm Start review, **then** phiên mở với đúng chiều đó, lưu ở `study_session.direction` (BR-MODE-016, BR-MODE-017).
- [ ] **Given** phiên mở với `Term first` hoặc `Meaning first`, **when** hệ thống dựng hàng đợi, **then** mọi dòng có cùng chiều đó; với `Mixed`, mỗi dòng nhận một trong hai chiều, chia gần đều một lần lúc mở phiên (BR-MODE-015, BR-MODE-016).
- [ ] **Given** một thẻ hỏi theo `Meaning first`, **when** thẻ hiện ra, **then** đề là mặt nghĩa, mặt thuật ngữ và ví dụ chỉ hiện sau khi lật, và vẫn là 4 action của `sm2` với lịch chạy như thường (BR-MODE-014, BR-MODE-019, BR-STUDY-009).
- [ ] **Given** Start review đang mở phiên, **when** người dùng bấm thêm lần nữa, **then** chỉ một phiên được tạo (BR-STUDY-072).
- [ ] **Given** sheet chọn chiều đang mở, **when** người dùng đóng sheet mà không bấm Start review, **then** không có gì được ghi và Study Entry giữ nguyên (BR-STUDY-020, A1).
- [ ] **Given** deck chạy `eight_box`, **when** người dùng bấm Review, **then** không có sheet chọn chiều, chỉ có màn chọn mode (BR-MODE-013, A2).
- [ ] **Given** còn một phiên `self_assess` bỏ dở, **when** người dùng chọn Continue, **then** phiên tiếp tục với chiều đã lưu ở `study_session.direction` và sheet chọn chiều không mở lại (BR-MODE-017, A3).
- [ ] **Given** một phiên `Mixed` đang chạy, **when** một thẻ quay lại hàng đợi, **then** chiều của thẻ vẫn là chiều đã gán lúc mở phiên (BR-STUDY-005, BR-MODE-015, A4).
- [ ] **Given** không còn thẻ nào đến hạn lúc bấm Start review, **when** người dùng bấm Start, **then** phiên bị từ chối kèm banner cảnh báo, không ghi gì, và footer theo số mới (BR-STUDY-054, E2).
- [ ] **Given** yêu cầu mở phiên `self_assess` không kèm chiều, hoặc kèm chiều cho một mode không dùng chiều, **when** hệ thống xử lý, **then** yêu cầu bị từ chối và không ghi gì (BR-MODE-013, BR-MODE-018, E3).
- [ ] **Given** sheet chọn chiều đang mở và scheduler của root đổi sang `eight_box`, **when** người dùng bấm Start review, **then** phiên bị từ chối với `modeNotOffered`, không ghi gì, và màn vào học hiện banner cảnh báo riêng thay cho lỗi mở phiên chung (E1).
