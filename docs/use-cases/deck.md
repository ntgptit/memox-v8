# Use cases — Deck

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng DECK, dưới ID vĩnh viễn `UC-DECK-nnn` |
| **Scope** | Luồng tạo, sửa, xoá và di chuyển deck. |
| **Source of truth for** | UC-DECK-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-DECK-001 · Tạo root deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Bấm tạo deck ở màn hình danh sách deck
**Preconditions:** Không có

**Main flow:**
1. Người dùng nhập tên deck.
2. Người dùng **chọn chế độ ôn tập**: `eight_box` hoặc `sm2` (BR-SRS-001). Bắt buộc,
   không có mặc định ngầm bỏ qua bước này.
3. Hệ thống hiển thị mô tả ngắn cho từng chế độ, kèm lưu ý rằng chế độ sẽ bị khoá
   sau lượt ôn đầu tiên (BR-SRS-003).
4. Người dùng xác nhận.
5. Hệ thống validate tên (BR-DECK-020) và chế độ đã chọn.
6. Hệ thống tạo root deck với: `parent_id = NULL`, `root_id = id`,
   `content_type = 'deck'` (bất biến), `generation = 1`,
   `first_answered_at = NULL`.
7. Deck xuất hiện trong danh sách, rỗng.

**Root deck chỉ chứa deck con** (BR-DECK-004). Nút Create bên trong nó chỉ có một lựa
chọn: Create deck (BR-DECK-005). Việc tạo phần tử con nằm ở UC-DECK-004.

**Alternative flows:**
- **A1 — Người dùng huỷ:** không tạo gì; nếu đã nhập, hỏi xác nhận trước khi bỏ.

**Error flows:**
- **E1 — Tên rỗng:** lỗi inline dưới ô nhập, không phải snackbar.
- **E2 — Tên quá 200 ký tự:** lỗi inline; chặn nhập thêm thay vì cắt âm thầm.
- **E3 — Chưa chọn chế độ:** lỗi inline ở phần chọn chế độ; không tạo.
- **E4 — Ghi database thất bại:** hiện lỗi, giữ nguyên form và dữ liệu đã nhập.

**Postconditions:** Root deck tồn tại với scheduler đã chọn, `content_type =
'deck'`, `root_id = id`, và còn sau khi khởi động lại app.

**Business rules:** BR-DECK-020, BR-DECK-021, BR-SRS-001, BR-DECK-002, BR-DECK-004, BR-DECK-005
**UI states:** initial · submitting · error

---

## UC-DECK-002 · Sửa và xoá deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn sửa hoặc xoá trên một deck
**Preconditions:** Deck tồn tại

**Main flow (sửa tên):**
1. Người dùng đổi tên deck.
2. Hệ thống validate (BR-DECK-020) và lưu.

**Main flow (đổi chế độ ôn tập — chỉ trên root deck, chỉ khi chưa có thẻ nào học xong chuỗi học mới):**
1. Hệ thống hiển thị phần chọn chế độ ở trạng thái **mở khoá**
   (`first_answered_at IS NULL`, BR-SRS-002).
2. Người dùng chọn chế độ khác.
3. Hệ thống cảnh báo study state của **toàn bộ card trong cây** sẽ được khởi tạo
   lại theo chế độ mới (BR-SRS-004), và phiên học đang mở sẽ bị đóng (BR-STUDY-016). Đây
   **không** phải Reset learning progress: không có generation nào bị tiêu, không
   có lịch sử nào bị bỏ, nên cảnh báo này MUST NOT dùng giọng phá huỷ của UC-SRS-001.
4. Người dùng xác nhận.
5. Hệ thống đổi scheduler, khởi tạo lại study state toàn cây, **và** đóng mọi
   phiên đang mở của cây — trong một transaction (BR-SRS-004, BR-STUDY-016).

**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số deck con và số card sẽ bị xoá vĩnh viễn
   (BR-DECK-023).
2. Người dùng xác nhận.
3. Hệ thống xoá cứng deck cùng toàn bộ descendant, card, study state, study
   answers và study session của nó, trong một transaction (BR-DECK-022). Khi
   sub-project Trash triển khai, bước này đổi thành soft-delete có Undo và
   khôi phục — xem UC-TRASH-001.

**Alternative flows:**
- **A1 — Root deck đã có thẻ học xong chuỗi học mới:** phần chọn chế độ hiển thị ở trạng thái **khoá**,
  kèm giải thích và lối đi tới Reset learning progress (UC-SRS-001). Không ẩn đi — ẩn
  khiến người dùng tưởng tính năng không tồn tại (BR-SRS-003).
- **A2 — Sửa deck con:** không có phần chọn chế độ (BR-DECK-025).
- **A3 — Huỷ xác nhận xoá:** không xảy ra gì.
- **A4 — Xác nhận đúng chế độ deck đang chạy:** thao tác được chấp nhận và không
  làm gì người dùng thấy được (BR-SRS-002). Không seed lại cây, không đóng phiên đang
  mở — mất một phiên đang học cho một thay đổi bằng không là cái giá không ai
  đồng ý trả.

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách với
  thông báo nhẹ nhàng.
- **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên
  scheduler cũ và study state cũ.
- **E3 — Xoá thất bại:** hiện lỗi; deck còn nguyên vẹn, và `content_type` của
  deck cha cũng không đổi — cả hai nằm trong một transaction (BR-DECK-015).
- **E4 — Scheduler bị khoá trong lúc bảng chọn đang mở:** người dùng học xong một
  thẻ ở màn khác giữa lúc bảng chọn mở. Hệ thống đọc lại `first_answered_at`
  **bên trong** transaction (BR-SRS-003) và từ chối; màn hình hiện lý do và lối đi tới
  Reset. Trạng thái vẽ trên màn hình MUST NOT là thứ quyết định thao tác có hợp lệ
  hay không.

**Postconditions:**
- Sau đổi chế độ: `scheduler_type` mới, mọi study state trong cây khởi tạo lại,
  `generation` **không đổi** (chưa có gì để reset), `first_answered_at`
  vẫn NULL, và không còn phiên `in_progress` nào của cây (BR-STUDY-016).
- Sau xoá: deck và mọi descendant của nó không còn tồn tại — cascade đã xoá
  cứng card, study state, study answers và study session của chúng (BR-DECK-022);
  không bề mặt active nào còn hiện chúng.
- Sau xoá một deck con: nếu deck cha là **sub-deck** và vừa mất phần tử con cuối
  cùng, `content_type` của nó tự về `unset` trong cùng transaction (BR-DECK-015).
  Deck cha là root thì giữ `deck` (BR-DECK-004).

**Business rules:** BR-DECK-020, BR-DECK-022, BR-DECK-023, BR-DECK-025, BR-SRS-002, BR-SRS-003, BR-SRS-004, BR-DECK-015, BR-STUDY-016
**UI states:** loaded · submitting · error

---

## UC-DECK-003 · Xem danh sách deck với tiến độ

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Mở app, hoặc quay về từ màn khác
**Preconditions:** Không có

**Main flow:**
1. Hệ thống lấy toàn bộ root deck kèm số card đến hạn — **một query gộp** theo
   `root_id`, không phải N+1 query và không duyệt cây trong Dart.
2. Người dùng thấy mỗi deck với tên, tổng số card trong cây, **hai** số của
   BR-STUDY-046 — card chưa học (New) và card đến hạn (Due), không bao giờ gộp — và
   chế độ ôn tập đang dùng.
3. Deck có card đến hạn được làm nổi bật bằng **cả biểu tượng lẫn chữ**, không
   chỉ bằng màu. Deck tile hiển thị **total Due + New**; biểu tượng lớn phân ba
   trạng thái lịch theo BR-STUDY-067 — chưa đến hạn (outlined, neutral), đến hạn hôm
   nay (filled, vai time-pressure vàng/streak), quá hạn (missed + badge số ngày,
   cặp error container đỏ) — khác nhau bằng hình dạng/fill/badge chứ không chỉ
   màu. Hero level summary breakdown thành bốn tập rời nhau
   Overdue/Due today/New/Scheduled theo BR-STUDY-068 — lưới 2×2, mỗi hàng căn theo
   alphabetic baseline; Scheduled là tập trung tính, không actionable và không
   bao giờ là primary metric.
4. Mở một deck hiển thị nội dung theo `content_type`: danh sách deck con, hoặc
   danh sách card, không bao giờ cả hai (BR-DECK-011).

**Alternative flows:**
- **A1 — Chưa có deck nào:** empty state với hai lối đi — thư viện starter (UC-STARTER-001)
  hoặc tạo deck mới (UC-DECK-001).
- **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift,
  không cần refresh thủ công.
- **A3 — Cây sâu nhiều cấp:** điều hướng xuống từng cấp; số liệu gộp luôn tính
  theo `root_id` (BR-DECK-002, BR-DECK-003).

**Error flows:**
- **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại.

**Postconditions:** Không đổi gì — use case chỉ đọc.

**Business rules:** BR-STUDY-051 — hai tập "chưa học" và "đến hạn" phải khớp **hệt** UC-STUDY-001, nếu
không con số ở danh sách sẽ lệch với số card thực sự ôn được. Dùng chung một
named query. Ngoài ra BR-DECK-002, BR-DECK-003, BR-DECK-011.
**UI states:** loading · loaded · empty · error

---

## UC-DECK-004 · Tạo phần tử con và xác lập `content_type`

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Bấm Create bên trong một deck
**Preconditions:** Deck tồn tại

Đây là use case định hình toàn bộ cấu trúc cây, và là chỗ dễ cài sai nhất vì nút
Create có ba hành vi khác nhau tuỳ trạng thái deck.

**Main flow:**
1. Người dùng bấm Create trong một deck.
2. Hệ thống quyết định lựa chọn hiển thị:

   | Deck | Lựa chọn hiện ra |
   |---|---|
   | root deck (`content_type = 'deck'`, bất biến) | **chỉ** Create deck (BR-DECK-005) |
   | deck con, `content_type = 'unset'` | Create card **và** Create deck (BR-DECK-007) |
   | deck con, `content_type = 'card'` | **chỉ** Create card (BR-DECK-012) |
   | deck con, `content_type = 'deck'` | **chỉ** Create deck (BR-DECK-012) |

3. Người dùng chọn một hành động và nhập nội dung.
4. Hệ thống thực hiện **trong một transaction** (BR-DECK-008):
   - nếu deck đang `unset`: đặt `content_type` theo hành động đã chọn;
   - tạo phần tử con: card (kèm study state, BR-CARD-004) hoặc deck con mới với
     `content_type = 'unset'`, `parent_id` = deck hiện tại,
     `root_id` = root của deck hiện tại (BR-DECK-002), và **không** có cột
     scheduler (BR-DECK-025).
5. Từ đây nút Create trong deck này chỉ hiện hành động tương ứng (BR-DECK-012).

**Alternative flows:**
- **A1 — Deck đã `card`:** không có lựa chọn tạo deck con, ở bất kỳ đâu trong UI
  (BR-DECK-009).
- **A2 — Deck đã `deck`:** không có lựa chọn tạo card (BR-DECK-010).
- **A3 — Phần tử con cuối cùng rời đi:** xoá card cuối, xoá deck con cuối hoặc
  di chuyển deck con cuối sang cha khác đều đưa `content_type` của sub-deck về
  `unset`, trong cùng transaction với mutation đó (BR-DECK-015). Không có thao tác
  reset thủ công nào, và không cần có.
- **A4 — Huỷ giữa chừng:** không tạo gì và **không** xác lập `content_type` —
  `content_type` chỉ đổi cùng với việc phần tử con thực sự được tạo (BR-DECK-008).

**Error flows:**
- **E1 — Validate thất bại** (tên deck rỗng, card thiếu mặt): lỗi inline; không
  tạo gì và không đổi `content_type`.
- **E2 — Ghi thất bại giữa chừng:** transaction rollback. Deck giữ nguyên
  `content_type` cũ và không có phần tử con nửa vời (BR-DECK-008) — chiều xoá cũng
  vậy: mutation và thay đổi type cùng sống hoặc cùng chết (BR-DECK-015).
- **E3 — Cố tạo card trong root deck:** không có đường nào tới được trạng thái
  này qua UI (BR-DECK-005). Nếu xảy ra qua deep link hoặc lỗi lập trình, từ chối và log
  — đây là vi phạm BR-DECK-004 và validation phải bắt được.
- **E4 — Deck cha đã ở cấp 10:** tạo deck con bị chặn trước khi ghi (BR-DECK-001).
  Không tạo gì và không đổi `content_type` của deck cha — kể cả khi nó đang
  `unset`. Tạo card không bị giới hạn này: card không thêm cấp cho cây.

**Postconditions:**
- Deck có `content_type` khác `unset`, khớp với loại phần tử con vừa tạo.
- Deck không đồng thời chứa card và deck con (BR-DECK-011).
- Deck con mới có `root_id` đúng bằng root của cha (BR-DECK-002, BR-DECK-019).

**Business rules:** BR-CARD-004, BR-DECK-001, BR-DECK-002, BR-DECK-004…BR-DECK-012, BR-DECK-019, BR-DECK-015
**UI states:** initial · submitting · error

---

## UC-DECK-005 · Di chuyển deck trong cây

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn di chuyển một deck sang deck cha khác
**Preconditions:** Deck nguồn và deck đích tồn tại

**Main flow:**
1. Người dùng chọn deck nguồn và deck đích.
2. Hệ thống kiểm tra, theo thứ tự:
   - đích không phải chính deck nguồn hoặc descendant của nó (BR-DECK-017);
   - đích có `content_type = 'deck'` hoặc `'unset'` (BR-DECK-010) — không thể đưa deck
     vào một deck chỉ chứa card;
   - root của đích có cùng `scheduler_type` và `generation` với root
     của nguồn (BR-SRS-006);
   - độ sâu sau move không vượt giới hạn (BR-DECK-001): với `targetDepth` là cấp của
     deck đích (root là cấp 1) và `subtreeHeight` là chiều cao subtree nguồn
     (deck nguồn tính là 1), MUST có `targetDepth + subtreeHeight <= 10`.
3. Hệ thống thực hiện **trong một transaction** (BR-DECK-018):
   - đặt `parent_id` của deck nguồn thành deck đích;
   - cập nhật `root_id` cho **toàn bộ subtree** của deck nguồn;
   - nếu đích đang `unset`, đặt `content_type = 'deck'` (BR-DECK-008);
   - nếu deck cha **cũ** là sub-deck và vừa mất phần tử con cuối cùng, đặt
     `content_type` của nó về `unset` (BR-DECK-015); cha cũ là root thì giữ `deck`.
4. Cây được vẽ lại.

**Alternative flows:**
- **A1 — Di chuyển trong cùng một cây (cùng root):** `root_id` không đổi,
  nhưng vẫn phải chạy trong transaction cùng với việc đổi `parent_id`.
- **A2 — Di chuyển lên thành root deck:** ngoài phạm vi MVP — deck nguồn sẽ cần
  scheduler riêng, tức là một quyết định mới, không phải một phép di chuyển.

**Error flows:**
- **E1 — Đích là chính nó hoặc descendant:** chặn, lỗi rõ ràng "Không thể di
  chuyển deck vào chính nó" (BR-DECK-017). Đây là phép kiểm tra chống cycle (BR-DECK-016).
- **E2 — Đích có `content_type = 'card'`:** chặn, giải thích deck đích chỉ chứa
  card (BR-DECK-010).
- **E3 — Root đích khác scheduler hoặc generation:** **chặn**, và đề nghị đặt lại
  tiến độ học một cách tường minh (BR-SRS-006). Không im lặng chuyển đổi state — không
  có ánh xạ nào có cơ sở giữa box và ease factor (BR-SRS-005).
- **E4 — Thất bại giữa chừng:** transaction rollback (BR-DECK-018) — con trỏ cha, con
  trỏ root của cả subtree, `content_type` của đích **và** `content_type` của cha
  cũ cùng quay lại nguyên trạng (BR-DECK-015). Không có descendant nào trỏ sai root
  (BR-DECK-019).
- **E5 — Vượt độ sâu tối đa:** `targetDepth + subtreeHeight > 10` → chặn trước
  khi ghi (BR-DECK-001). Không đổi `parent_id`, `root_id`, `content_type`
  của đích hay bất kỳ timestamp nào.

**Postconditions:**
- Cây không có cycle (BR-DECK-016).
- Mọi deck trong subtree đã di chuyển có `root_id` đúng bằng root mới
  (BR-DECK-002, BR-DECK-019).
- Không deck nào đồng thời chứa card và deck con (BR-DECK-011).
- Deck đích `unset` nhận phần tử con đầu tiên thành `deck`; cha cũ là sub-deck
  mất phần tử con cuối thành `unset`; cha cũ còn sibling giữ `deck` (BR-DECK-015).
- Không có card study state nào lệch scheduler hoặc generation so với root
  (BR-SRS-028, BR-SRS-029).

**Business rules:** BR-DECK-001, BR-DECK-002, BR-DECK-008, BR-DECK-010, BR-DECK-016, BR-DECK-017, BR-DECK-018, BR-DECK-019, BR-SRS-005, BR-SRS-006, BR-DECK-015
**UI states:** loaded · submitting · error

---

## UC-DECK-006 · Sắp xếp lại Deck cùng cấp

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chọn Move up hoặc Move down trên một deck khi Library đang ở
Manual order.
**Preconditions:** Source và target là deck active cùng một level; danh sách
đang ở Manual order để thứ tự nhìn thấy chính là thứ tự persisted.

**Main flow:**
1. Hệ thống lấy sibling liền trước hoặc sau từ thứ tự Manual đã lưu và gửi
   operation `before`/`after`, không gửi một database index thô.
2. Hệ thống mở một transaction, đọc lại source và target active, xác nhận
   chúng còn cùng `parent_id`, rồi cập nhật thứ tự nhóm sibling.
3. Watch của level phát emission mới; danh sách đổi vị trí tại chỗ. Mọi parent,
   root pointer, scheduler, card, study state và subtree giữ nguyên.

**Alternative flows:** Deck đầu không hiện Move up; deck cuối không hiện Move
down; level chỉ có một deck không hiện thao tác reorder. Khi đang dùng sort theo
tên, ngày, due hoặc tiến độ, thao tác bị ẩn để neighbour không bị suy ra từ một
view-only order.

**Error flows:** Source hoặc target đã stale, hoặc không còn sibling → transaction
từ chối và không ghi gì. Lỗi database ở bất kỳ update nào → toàn transaction
rollback, thứ tự cũ giữ nguyên.

**Business rules:** BR-SRS-007, BR-DECK-001…BR-DECK-004.

**Postconditions:** Chỉ `sibling_position` (và timestamp audit của các sibling
được đánh số lại) đổi trong một transaction; sibling xuất hiện theo thứ tự mới
qua stream và toàn bộ tree pointer, subtree cùng study data giữ nguyên.

**UI states:** Ở Manual order, action sheet hiện Move up khi có sibling trước
và Move down khi có sibling sau. Ở đầu/cuối hoặc level một phần tử, action
tương ứng bị ẩn. Ở mọi view-only sort khác, cả hai thao tác bị ẩn; lỗi giữ
nguyên danh sách hiện có.
