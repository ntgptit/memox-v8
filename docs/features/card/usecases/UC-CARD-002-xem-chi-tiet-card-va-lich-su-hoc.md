---
id: UC-CARD-002
title: Xem chi tiết một card và lịch sử học của nó
status: ready
rules: [BR-CARD-003, BR-CARD-005, BR-CARD-006, BR-CARD-007, BR-CARD-008, BR-CARD-009, BR-CARD-012, BR-CARD-013, BR-CARD-014, BR-CARD-015, BR-CARD-016, BR-CARD-017, BR-CARD-018, BR-CARD-019, BR-CARD-020, BR-DECK-015, BR-MODE-008, BR-CORE-005, BR-SRS-014, BR-SRS-015, BR-STUDY-028, BR-STUDY-034, BR-STUDY-035, BR-STUDY-053, BR-TAG-001]
code: [lib/features/card/domain/usecases/watch_card_detail_use_case.dart, lib/features/card/domain/usecases/load_card_history_page_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm vào một hàng card trong danh sách card khi **không** ở chế độ
chọn nhiều (BR-CARD-020)
**Preconditions:** Deck đang mở là sub-deck loại `card`; thẻ được chạm còn tồn
tại

## Main flow

**Main flow:**
1. Người dùng chạm một hàng card. Hệ thống mở màn chi tiết **chỉ đọc** của đúng
   thẻ đó, đẩy chồng lên danh sách chứ không thay thế nó (BR-CARD-020).
2. Hệ thống hiển thị toàn bộ nội dung thẻ: mặt trước đầy đủ, mặt sau đầy đủ, và
   ba field tuỳ chọn `example`, `hint`, `pronunciation` — mỗi field chỉ hiện khi
   có giá trị (BR-CARD-014).
3. Hệ thống hiển thị phần siêu dữ liệu và trạng thái học **hiện tại**: tag, cờ,
   trạng thái hiển thị của thẻ, ngày tới hạn, lần trả lời gần nhất, số lượt đã
   trả lời, số lần quên, và các field riêng của scheduler đang gắn với thẻ
   (BR-CARD-014).
4. Hệ thống tải trang lịch sử đầu tiên — 50 event gần nhất, mới nhất trước
   (BR-CARD-015) — và hiển thị chúng thành một dòng thời gian, nhóm theo generation
   của scheduler (BR-CARD-017).
5. Mỗi event nói: thời điểm, chế độ học, loại lượt, hành động đã ghi, lý do kết
   thúc và việc dùng gợi ý khi có, cùng thay đổi lịch trước→sau đúng theo
   scheduler đã ghi trên chính hàng đó (BR-CARD-016).
6. Người dùng cuộn tới cuối danh sách lịch sử và chọn tải thêm; hệ thống nối
   thêm 50 event kế tiếp bằng con trỏ keyset và không lặp lại event nào đã hiện
   (BR-CARD-015).
7. Người dùng quay lại. Hệ thống trả về danh sách card **đúng như lúc rời đi** —
   filter, search term, sort, cửa sổ đã tải và selection đều nguyên vẹn
   (BR-CARD-020).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Sửa thẻ:** người dùng chọn hành động `Edit` tường minh trên màn chi
  tiết; hệ thống mở editor sẵn có cho đúng thẻ đó (UC-CARD-001 A1). Sửa nội dung
  không đụng tới trạng thái lịch hay lịch sử (BR-CARD-005, BR-CARD-018); quay lại từ
  editor thì chi tiết hiện nội dung mới và lịch sử không đổi.
- **A2 — Thẻ chưa có lịch sử:** phần dòng thời gian hiện trạng thái rỗng có nội
  dung giải thích, không phải lỗi, và phần nội dung cùng trạng thái hiện tại vẫn
  hiển thị đầy đủ (BR-CARD-018).
- **A3 — Lịch sử trải nhiều generation:** sau một lần Reset (UC-SRS-001), các event
  cũ vẫn còn và nằm dưới tiêu đề nhóm của generation của chúng; event của
  generation hiện tại nằm trên cùng (BR-CARD-017).
- **A4 — Chạm khi đang ở chế độ chọn nhiều:** chạm giữ nguyên nghĩa chọn/bỏ
  chọn; hệ thống **không** điều hướng (BR-CARD-020).
- **A5 — Đã tải hết lịch sử:** hệ thống nói rõ đã hết thay vì để một nút tải
  thêm không còn gì để tải.

**Error flows:**
- **E1 — Thẻ không tồn tại khi mở:** deep link hoặc route cũ trỏ tới một id đã
  bị xoá → hệ thống hiện mặt not-found có kiểu kèm lối quay lại danh sách; không
  màn trắng, không lộ id hay chi tiết kỹ thuật (BR-CARD-019, BR-CORE-005).
- **E2 — Thẻ bị xoá từ màn khác khi chi tiết đang mở:** stream nội dung chuyển
  sang mặt not-found tương tự E1; không có mutation nào được thực hiện từ đây
  (BR-CARD-013, BR-CARD-019).
- **E3 — Đọc nội dung/trạng thái thất bại:** lỗi database map thành lý do có
  kiểu; màn hiện mặt lỗi cấp cao nhất có `Retry`, và `Retry` chạy lại đúng lần
  đọc đó.
- **E4 — Tải một trang lịch sử thất bại:** các event đã hiện **giữ nguyên**;
  chỉ phần đuôi danh sách hiện dải lỗi có `Retry`, và thử lại tiếp tục từ
  đúng con trỏ trước đó chứ không tải lại từ đầu (BR-CARD-015).
- **E5 — Kết quả trang tới muộn sau khi người dùng đã rời hoặc đã thử lại:** hệ
  thống bỏ qua kết quả cũ; danh sách MUST NOT bị nối thêm hai lần cùng một tập
  event (BR-CARD-015).

## UI

**UI states:** loading (đọc nội dung + trạng thái) · loaded không có lịch sử ·
loaded có lịch sử một trang · loaded nhiều trang · loading-more · page error
(có `Retry`, giữ nguyên phần đã tải) · end-of-history · error cấp cao nhất ·
not-found.

## Local

**Postconditions:** Database không đổi — nội dung, `updated_at`, study state,
`learned_at`, review history, cờ và tag đều nguyên vẹn (BR-CARD-013). Ngữ cảnh của
danh sách card được giữ nguyên khi quay lại (BR-CARD-020).

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] **Given** chạm một hàng card ở chế độ thường, **when** chi tiết mở, **then** nó hiện toàn bộ mặt trước, mặt sau và chỉ các trường tuỳ chọn có giá trị; việc đọc không ghi gì (BR-CARD-013, BR-CARD-014).
- [ ] **Given** chi tiết đang mở, **when** tag, study state hoặc nội dung đổi, **then** thông tin hiện tại (tag, cờ, trạng thái, ngày tới hạn, số liệu học) cập nhật theo (BR-CARD-014).
- [ ] **Given** một card có lịch sử, **when** chi tiết tải, **then** trang đầu là 50 event gần nhất, mới nhất trước, nhóm theo generation với generation hiện tại trên cùng, kể cả event của generation cũ sau một lần Reset (BR-CARD-015, BR-CARD-017, A3).
- [ ] **Given** một event lịch sử, **when** hiển thị, **then** nó nêu thời điểm, chế độ học, loại lượt, hành động và đúng giá trị lịch trước và sau đã lưu trên hàng đó (BR-CARD-016).
- [ ] **Given** đã cuộn tới cuối trang đã tải, **when** người dùng tải thêm, **then** 50 event kế tiếp nối vào theo con trỏ keyset, không lặp và không sót, kể cả khi có answer mới ghi giữa lúc phân trang (BR-CARD-015).
- [ ] **Given** người dùng chọn Edit trên chi tiết, **when** editor mở, **then** đó là editor của UC-CARD-001 A1 cho đúng card đó, và sửa nội dung không đụng study state hay lịch sử (BR-CARD-005, BR-CARD-018, A1).
- [ ] **Given** một card chưa có lịch sử, **when** chi tiết mở, **then** dòng thời gian hiện trạng thái rỗng có giải thích, không phải lỗi, và nội dung cùng trạng thái hiện tại vẫn hiện đủ (BR-CARD-018, A2).
- [ ] **Given** người dùng đang ở chi tiết mở từ card list, **when** quay lại, **then** card list giữ nguyên filter, search, sort, cửa sổ đã tải và lựa chọn (BR-CARD-020).
- [ ] **Given** đang ở chế độ chọn nhiều, **when** chạm một hàng, **then** hàng chỉ đổi trạng thái chọn, hệ thống không mở chi tiết (BR-CARD-020, A4).
- [ ] **Given** đã tải hết lịch sử, **when** tới cuối, **then** hệ thống nói rõ đã hết thay vì để một nút tải thêm không làm gì (A5).
- [ ] **Given** id card không còn tồn tại (deep link hoặc route cũ), **when** mở chi tiết, **then** hệ thống hiện mặt not-found kèm lối về danh sách, không màn trắng và không lộ id hay chi tiết kỹ thuật (BR-CARD-019, BR-CORE-005, E1).
- [ ] **Given** chi tiết đang mở, **when** card bị xoá ở nơi khác, **then** màn chuyển sang mặt not-found, và không có thao tác ghi nào từ đây (BR-CARD-013, BR-CARD-019, E2).
- [ ] **Given** đọc nội dung hoặc trạng thái thất bại, **when** lỗi xảy ra, **then** hệ thống hiện mặt lỗi kèm Retry, ẩn nguyên nhân kỹ thuật, và Retry chạy lại đúng lần đọc đó (BR-CORE-005, E3).
- [ ] **Given** tải một trang lịch sử thất bại, **when** lỗi xảy ra, **then** các event đã hiện giữ nguyên, chỉ cuối danh sách hiện lỗi kèm Retry, và Retry tiếp tục từ đúng con trỏ trước đó (BR-CARD-015, E4).
- [ ] **Given** một trang lịch sử đang tải, **when** người dùng rời màn hoặc yêu cầu tải thêm lần nữa trước khi nó về, **then** kết quả tới muộn bị bỏ qua và danh sách không bao giờ nối cùng một tập event hai lần (BR-CARD-015, E5).
