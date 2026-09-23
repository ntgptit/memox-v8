# Use cases — Card

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng CARD, dưới ID vĩnh viễn `UC-CARD-nnn` |
| **Scope** | Luồng quản lý card trong deck và xem chi tiết card. |
| **Source of truth for** | UC-CARD-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-CARD-001 · Quản lý card trong deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Mở một deck có `content_type = 'card'`
**Preconditions:** Deck tồn tại và `content_type = 'card'` (BR-DECK-009)

**Main flow:**
1. Người dùng thấy danh sách card của deck.
2. Người dùng thêm card: nhập mặt trước và mặt sau, tuỳ chọn thêm ví dụ, gợi ý
   và phiên âm (BR-CARD-003).
3. Hệ thống validate (BR-CARD-001, BR-CARD-002, BR-CARD-003).
4. Hệ thống tạo card **và** study state của nó trong cùng transaction, theo
   scheduler của root deck (tra qua `root_id`) và generation hiện tại (BR-CARD-004).
5. Card xuất hiện; số card đến hạn của deck tăng.

Card đầu tiên của một deck `unset` được tạo qua UC-DECK-004, và chính nó xác lập
`content_type = 'card'`.

**Alternative flows:**
- **A1 — Sửa card:** nội dung đổi; study state và history **không** đổi (BR-CARD-005).
- **A2 — Xoá card:** hỏi xác nhận, nêu rõ nội dung sẽ mất (BR-DECK-023); xác nhận thì
  xoá cứng card cùng study state và history của nó, trong một transaction
  (BR-DECK-022). Khi sub-project Trash triển khai, thao tác này đổi thành soft-delete
  có Undo và khôi phục — xem UC-TRASH-001. Nếu đó là card **cuối cùng** đang active,
  deck atomically trở về `content_type = unset` trong cùng transaction
  (BR-DECK-015); sau đó người dùng quay về màn hình deck và
  lại chọn được tạo card hay tạo sub-deck. "Deck `card` rỗng" không còn là một
  trạng thái ổn định của hệ thống.
- **A3 — Deck còn card nhưng danh sách rỗng theo bộ lọc:** empty state của bộ
  lọc, không phải của deck.
- **A5 — Di chuyển thẻ sang deck khác:** chọn deck đích trong cùng root; thẻ giữ
  nguyên id, nội dung, study state, history, cờ và tag — chỉ đổi chỗ (BR-CARD-010).
  Deck nguồn mất thẻ cuối thì về `unset`, deck đích đang `unset` thì thành
  `card`, cùng transaction (BR-DECK-015).
- **A6 — Chọn nhiều thẻ:** long-press một thẻ hoặc dùng action **Select** trên
  app bar để vào chế độ chọn. Thanh hành động ngữ cảnh hiện số đã chọn và các
  thao tác hàng loạt: Move, Add tag, Flag, Remove flag, Delete. **Select all**
  chọn toàn bộ tập kết quả theo filter và search hiện tại, không chỉ phần đã
  tải (BR-CARD-012). Mỗi thao tác là all-or-nothing (BR-CARD-011).
- **A4 — Thêm liên tiếp nhiều card:** sau khi lưu, giữ form mở và xoá trống các ô.
- **A7 — Cờ:** người dùng bật hoặc bỏ cờ của một thẻ (BR-CARD-009).
- **A8 — Tag:** người dùng gắn tag theo tên — dùng lại tag trùng tên đã fold, tạo
  mới nếu chưa có — hoặc gỡ tag khỏi thẻ (BR-TAG-001, BR-TAG-002).
- **A9 — Mở chi tiết:** chạm một thẻ ở chế độ thường mở chi tiết chỉ đọc (UC-CARD-002);
  sửa là action riêng (BR-CARD-020).

**Error flows:**
- **E1 — Mặt trước hoặc mặt sau rỗng:** lỗi inline ở đúng ô đó.
- **E5 — Deck đích không hợp lệ:** picker chỉ liệt kê deck cùng root, không phải
  root, không phải loại `deck`, và không phải chính deck nguồn. Nếu một thao tác
  vẫn mang đích không hợp lệ tới trước khi ghi — deep link, hoặc cây đổi giữa
  lúc mở picker và lúc xác nhận — nó bị từ chối kèm lý do có kiểu và không ghi
  gì (BR-CARD-010).
- **E6 — Một thẻ trong lô vi phạm:** cả lô rollback; danh sách và selection giữ
  nguyên, lỗi nêu rõ vì sao (BR-CARD-011).
- **E2 — Vượt giới hạn độ dài** (BR-CARD-002, BR-CARD-003): lỗi inline ở đúng ô đó.
- **E3 — Ghi thất bại:** hiện lỗi, giữ nội dung; không tạo card không có study
state.
- **E7 — Tag không hợp lệ, hoặc thẻ đã đủ 10 tag:** lỗi có kiểu; tag của thẻ giữ
  nguyên (BR-TAG-001, BR-TAG-002).

**Postconditions:** Card tồn tại kèm đúng một study state, đúng scheduler và
đúng generation của root deck.

**Business rules:** BR-DECK-022, BR-DECK-023, BR-CARD-001, BR-CARD-002, BR-CARD-004, BR-CARD-005, BR-DECK-009, BR-CARD-009, BR-TAG-001, BR-TAG-002, BR-CARD-003, BR-DECK-015, BR-CARD-010, BR-CARD-011, BR-CARD-012, BR-CARD-020
**UI states:** loading · loaded · empty · submitting · error

---

## UC-CARD-002 · Xem chi tiết một card và lịch sử học của nó

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chạm vào một hàng card trong danh sách card khi **không** ở chế độ
chọn nhiều (BR-CARD-020)
**Preconditions:** Deck đang mở là sub-deck loại `card`; thẻ được chạm còn tồn
tại

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
  màn trắng, không lộ id hay chi tiết kỹ thuật (BR-CARD-019, BR-PRIVACY-003).
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

**Postconditions:** Database không đổi — nội dung, `updated_at`, study state,
`learned_at`, review history, cờ và tag đều nguyên vẹn (BR-CARD-013). Ngữ cảnh của
danh sách card được giữ nguyên khi quay lại (BR-CARD-020).

**Business rules:** BR-CARD-005, BR-PRIVACY-003, BR-SRS-014, BR-SRS-015, BR-CARD-006, BR-CARD-007, BR-CARD-008, BR-CARD-009,
BR-TAG-001, BR-CARD-003, BR-MODE-008, BR-STUDY-034, BR-STUDY-035, BR-STUDY-028, BR-STUDY-053, BR-DECK-015, BR-CARD-012, BR-CARD-013,
BR-CARD-014, BR-CARD-015, BR-CARD-016, BR-CARD-017, BR-CARD-018, BR-CARD-019, BR-CARD-020

**UI states:** loading (đọc nội dung + trạng thái) · loaded không có lịch sử ·
loaded có lịch sử một trang · loaded nhiều trang · loading-more · page error
(có `Retry`, giữ nguyên phần đã tải) · end-of-history · error cấp cao nhất ·
not-found.
