# Use cases

Mọi use case của app, nhóm theo feature. Định dạng section và dòng meta:
[docs/README.md](README.md), mục "UC, FN và screen spec".

## Deck

### UC-DECK-001 — Tạo root deck
Status: ready · Code: [lib/features/deck/domain/usecases/create_root_deck_use_case.dart] · Invokes: [FN-DECK-001]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Bấm tạo deck ở màn hình danh sách deck
**Preconditions:** Không có

#### Main flow

**Main flow:**
1. Người dùng nhập tên deck.
2. Người dùng **chọn chế độ ôn tập**: `eight_box` hoặc `sm2`. Bắt buộc,
   không có mặc định ngầm bỏ qua bước này.
3. Hệ thống hiển thị mô tả ngắn cho từng chế độ, kèm lưu ý rằng chế độ sẽ bị khoá
   sau lượt ôn đầu tiên.
4. Người dùng xác nhận.
5. Hệ thống thực hiện FN-DECK-001: validate tên và chế độ đã chọn, rồi tạo root deck với
   `parent_id = NULL`, `root_id = id`, `content_type = 'deck'` (bất biến), `generation = 1`,
   `first_answered_at = NULL`.
6. Deck xuất hiện trong danh sách, rỗng.

**Root deck chỉ chứa deck con**. Nút Create bên trong nó chỉ có một lựa
chọn: Create deck. Việc tạo phần tử con là một use case riêng.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Người dùng huỷ:** không tạo gì; nếu đã nhập, hỏi xác nhận trước khi bỏ.

**Error flows:**
- **E1 — Tên rỗng:** lỗi inline dưới ô nhập, không phải snackbar.
- **E2 — Tên quá 200 ký tự:** lỗi inline; chặn nhập thêm thay vì cắt âm thầm.
- **E3 — Chưa chọn chế độ:** lỗi inline ở phần chọn chế độ; không tạo.
- **E4 — Ghi database thất bại:** hiện lỗi, giữ nguyên form và dữ liệu đã nhập.

#### Acceptance criteria

- [ ] **Given** một tên hợp lệ và một chế độ ôn tập (`eight_box` hoặc `sm2`), **when** người dùng xác nhận tạo, **then** hệ thống tạo root deck với `parent_id = NULL`, `root_id = id`, `content_type = 'deck'`, `generation = 1` và chế độ đã chọn, và deck còn sau khi khởi động lại app.
- [ ] **Given** một root deck vừa tạo, **when** người dùng bấm Create bên trong nó, **then** chỉ có lựa chọn Create deck, không có Create card.
- [ ] **Given** đã có một deck tên "Unit 5", **when** tạo thêm một root deck cũng tên "Unit 5", **then** hệ thống chấp nhận và không báo trùng tên.
- [ ] **Given** tên rỗng hoặc chỉ có khoảng trắng, **when** xác nhận, **then** lỗi hiện ngay dưới ô nhập và không tạo gì (E1).
- [ ] **Given** tên dài hơn 200 ký tự, **when** xác nhận, **then** lỗi hiện ngay dưới ô nhập và không tạo gì (E2).
- [ ] **Given** ghi database thất bại, **when** xác nhận, **then** hệ thống báo lỗi, giữ nguyên form và dữ liệu đã nhập, và không tạo deck (E4).
- [ ] **Given** dialog tạo root deck đã có tên hoặc chế độ ôn, **when** người dùng bấm Cancel, Back hay chạm ra ngoài, **then** hệ thống hỏi "Discard this deck?"; Keep editing giữ nguyên dữ liệu, Discard đóng dialog và không tạo gì. Dialog còn trống thì đóng ngay (A1).
- [ ] **Given** dialog tạo root deck vừa mở, **when** người dùng chưa chọn chế độ ôn tập mà bấm Create, **then** không có chế độ nào được chọn sẵn, lỗi inline "Choose how the cards are reviewed." hiện dưới phần chọn chế độ và không có deck nào được tạo (E3).

### UC-DECK-002 — Sửa và xoá deck
Status: ready · Code: [lib/features/deck/domain/usecases/rename_deck_use_case.dart, lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart, lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart] · Invokes: [FN-DECK-002, FN-DECK-003, FN-DECK-004, FN-DECK-005, FN-DECK-006]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn sửa hoặc xoá trên một deck
**Preconditions:** Deck tồn tại

#### Main flow

**Main flow (sửa tên):**
1. Người dùng đổi tên deck.
2. Hệ thống thực hiện FN-DECK-002: validate và lưu.

**Main flow (đổi chế độ ôn tập — chỉ trên root deck, chỉ khi chưa có thẻ nào học xong chuỗi học mới):**
1. Hệ thống hiển thị phần chọn chế độ ở trạng thái **mở khoá**
   (`first_answered_at IS NULL`).
2. Người dùng chọn chế độ khác.
3. Hệ thống cảnh báo study state của **toàn bộ card trong cây** sẽ được khởi tạo
   lại theo chế độ mới, và phiên học đang mở sẽ bị đóng. Đây
   **không** phải Reset learning progress: không có generation nào bị tiêu, không
   có lịch sử nào bị bỏ, nên cảnh báo này MUST NOT dùng giọng phá huỷ của Reset learning
   progress.
4. Người dùng xác nhận.
5. Hệ thống thực hiện FN-DECK-003: đổi scheduler, khởi tạo lại study state toàn cây,
   **và** đóng mọi phiên đang mở của cây — trong một transaction.

**Main flow (xoá):**
1. Hệ thống thực hiện FN-DECK-004 rồi hỏi xác nhận, nêu rõ số deck con và số card sẽ vào
   Trash cùng deck.
2. Người dùng xác nhận.
3. Hệ thống thực hiện FN-DECK-005: chuyển deck cùng mọi deck con và card còn active bên dưới vào Trash,
   thành **một** batch, trong một transaction. Tombstone đã có sẵn bên trong giữ batch cũ của nó. Phiên
   `in_progress` chạm tới batch kết thúc trong cùng transaction với
   `content_deleted`.
4. Người dùng có thể Undo ngay tại chỗ (hệ thống thực hiện FN-DECK-006) hoặc khôi phục về
   sau từ Trash.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Root deck đã có thẻ học xong chuỗi học mới:** phần chọn chế độ hiển thị ở trạng thái **khoá**,
  kèm giải thích và lối đi tới Reset learning progress. Không ẩn đi — ẩn
  khiến người dùng tưởng tính năng không tồn tại.
- **A2 — Sửa deck con:** không có phần chọn chế độ.
- **A3 — Huỷ xác nhận xoá:** không xảy ra gì.
- **A4 — Xác nhận đúng chế độ deck đang chạy:** thao tác được chấp nhận và không
  làm gì người dùng thấy được. Không seed lại cây, không đóng phiên đang
  mở — mất một phiên đang học cho một thay đổi bằng không là cái giá không ai
  đồng ý trả.

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành, quay về danh sách với
  thông báo nhẹ nhàng.
- **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên
  scheduler cũ và study state cũ.
- **E3 — Xoá thất bại:** hiện lỗi; deck còn nguyên vẹn, và `content_type` của
  deck cha cũng không đổi — cả hai nằm trong một transaction.
- **E4 — Scheduler bị khoá trong lúc bảng chọn đang mở:** người dùng học xong một
  thẻ ở màn khác giữa lúc bảng chọn mở. Hệ thống đọc lại `first_answered_at`
  **bên trong** transaction và từ chối; màn hình hiện lý do và lối đi tới
  Reset. Trạng thái vẽ trên màn hình MUST NOT là thứ quyết định thao tác có hợp lệ
  hay không.

#### Acceptance criteria

- [ ] **Given** một tên mới hợp lệ, **when** người dùng đổi tên deck, **then** tên đã trim được lưu và `updated_at` cập nhật.
- [ ] **Given** một root chưa có `first_answered_at`, **when** người dùng chọn chế độ khác và xác nhận, **then** trong một transaction scheduler đổi, study state của cả cây khởi tạo lại, `generation` giữ nguyên, và mọi phiên đang mở của cây đóng với `end_reason = 'scheduler_changed'`.
- [ ] **Given** người dùng xoá một deck có N deck con active và M card active, **when** hộp thoại xác nhận mở, **then** nó nêu đúng N và M trước khi ghi gì.
- [ ] **Given** người dùng đã xác nhận xoá, **when** transaction xong, **then** deck cùng mọi descendant active (deck và card) vào Trash trong cùng một batch và một `deleted_at`, và Undo hiện ngay tại chỗ.
- [ ] **Given** vừa xoá một deck, **when** người dùng bấm Undo, **then** deck cùng mọi phần tử của batch đó trở lại đúng vị trí cũ.
- [ ] **Given** một descendant đã ở Trash từ một batch cũ hơn, **when** xoá deck cha của nó, **then** descendant đó giữ nguyên batch cũ, không bị gộp vào batch mới.
- [ ] **Given** một deck cha không phải root vừa mất direct child active cuối cùng vì bị xoá, **when** transaction xoá xong, **then** `content_type` của nó về `unset` trong cùng transaction; một root vẫn giữ `deck`.
- [ ] **Given** một phiên `in_progress` chạm tới item của batch, **when** xoá xảy ra, **then** phiên đó đóng với `status = invalidated`, `end_reason = content_deleted` trong cùng transaction.
- [ ] **Given** root đã có thẻ hoàn tất chuỗi học mới (`first_answered_at` khác NULL), **when** mở phần chọn chế độ, **then** phần chọn hiện ở trạng thái khoá kèm giải thích và lối tới Reset, không bị ẩn (A1).
- [ ] **Given** đang sửa một deck con, **when** mở phần sửa, **then** không có phần chọn chế độ ôn tập (A2).
- [ ] **Given** hộp thoại xác nhận xoá đang mở, **when** người dùng bấm Cancel, **then** không có gì thay đổi (A3).
- [ ] **Given** root đang chạy chế độ X, khoá hay chưa khoá, **when** người dùng chọn lại đúng X, **then** không ghi gì, không seed lại cây và không đóng phiên đang mở (A4).
- [ ] **Given** deck đã bị xoá ở nơi khác, **when** người dùng đổi tên hoặc xoá nó, **then** thao tác không thành, không ghi gì, và màn hình nói deck không còn (E1).
- [ ] **Given** đổi chế độ thất bại giữa chừng, **when** transaction dừng, **then** mọi thay đổi rollback và deck giữ scheduler cùng study state cũ (E2).
- [ ] **Given** xoá thất bại giữa chừng, **when** transaction dừng, **then** hệ thống báo lỗi, deck còn nguyên và `content_type` của deck cha không đổi (E3).
- [ ] **Given** bảng chọn chế độ đang mở trên một cây chưa khoá, **when** cây bị khoá ở nơi khác rồi người dùng xác nhận, **then** hệ thống đọc lại `first_answered_at` trong transaction, từ chối có lý do, và không đổi gì (E4).

### UC-DECK-003 — Xem danh sách deck với tiến độ
Status: ready · Code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/models/deck_level_model.dart, lib/features/deck/domain/models/deck_level_query_model.dart] · Invokes: [FN-DECK-007, FN-DECK-008]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Mở app, hoặc quay về từ màn khác
**Preconditions:** Không có

#### Main flow

**Main flow:**
1. Hệ thống thực hiện FN-DECK-007: lấy toàn bộ root deck kèm số card đến hạn — **một query gộp** theo
   `root_id`, không phải N+1 query và không duyệt cây trong Dart.
2. Người dùng thấy mỗi deck với tên, tổng số card trong cây, **hai** số
   — card chưa học (New) và card đến hạn (Due), không bao giờ gộp — và
   chế độ ôn tập đang dùng.
3. Deck có card đến hạn được làm nổi bật bằng **cả biểu tượng lẫn chữ**, không
   chỉ bằng màu. Deck tile hiển thị **total Due + New**; biểu tượng lớn phân ba
   trạng thái lịch — chưa đến hạn (outlined, neutral), đến hạn hôm
   nay (filled, vai time-pressure vàng/streak), quá hạn (missed + badge số ngày,
   cặp error container đỏ) — khác nhau bằng hình dạng/fill/badge chứ không chỉ
   màu. Hero level summary breakdown thành bốn tập rời nhau
   Overdue/Due today/New/Scheduled — lưới 2×2, mỗi hàng căn theo
   alphabetic baseline; Scheduled là tập trung tính, không actionable và không
   bao giờ là primary metric.
4. Mỗi deck có một thanh mastery: số thẻ `mastered` trên mọi thẻ của cây. Deck rỗng chỉ vẽ track. Thanh không có chữ, nên hàng đọc
   "{n}% mastered" cho trình đọc màn hình.
5. Mở một deck chứa deck con hiển thị ở tóm tắt một donut mastery của cả level,
   cạnh dòng "Mastered · {thuật toán}".
6. Mở một deck, hệ thống thực hiện FN-DECK-008 và hiển thị nội dung theo `content_type`: danh sách deck con, hoặc
   danh sách card, không bao giờ cả hai.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Chưa có deck nào:** empty state với hai lối đi — thư viện starter
  hoặc tạo deck mới.
- **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift,
  không cần refresh thủ công.
- **A3 — Cây sâu nhiều cấp:** điều hướng xuống từng cấp; số liệu gộp luôn tính
  theo `root_id`.
- **A4 — Sắp xếp và lọc:** Manual, Newest, Name, Most due hoặc Progress, cùng bộ lọc chỉ giữ deck có thẻ đến hạn. Mọi sort kết thúc bằng
  thứ tự thủ công.

**Error flows:**
- **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại.

#### Acceptance criteria

- [ ] **Given** nhiều root deck với card ở nhiều cấp, **when** danh sách deck tải hoặc phát lại, **then** mỗi lần phát chỉ chạy đúng một câu lệnh gộp theo `root_id`, không phải một câu mỗi deck, kể cả khi cây sâu nhiều cấp (A3).
- [ ] **Given** deck có card mới, card đến hạn hôm nay và card quá hạn, **when** xem danh sách, **then** số New và số Due hiện tách biệt, không bao giờ gộp, và Due bằng Overdue cộng Due today.
- [ ] **Given** cây có N card active trong đó M card `mastered`, **when** xem hàng deck, **then** thanh mastery vẽ theo tỉ lệ M/N và hàng đọc phần trăm cho trình đọc màn hình; deck không có card chỉ vẽ track và không đọc phần trăm.
- [ ] **Given** một card `mastered` đang ở Trash, **when** tính mastery của deck chứa nó, **then** card đó không được tính ở cả tử số lẫn mẫu số.
- [ ] **Given** một deck `content_type = 'deck'`, **when** mở nó, **then** màn hiện danh sách deck con; một deck `content_type = 'card'` thì hiện danh sách card; không màn nào hiện cả hai.
- [ ] **Given** không deck nào có card đến hạn, **when** xem danh sách, **then** trạng thái được trình bày bình thường, không phải lỗi.
- [ ] **Given** chưa có deck nào, **when** mở danh sách, **then** hệ thống hiện empty state với hai lối: tạo deck mới và mở thư viện starter (A1).
- [ ] **Given** danh sách đang mở, **when** dữ liệu đổi ở nơi khác (thêm card, card thành `mastered`, deck mới), **then** danh sách tự cập nhật mà không cần làm mới tay (A2).
- [ ] **Given** các deck có mastery khác nhau và có deck không có card, **when** chọn sort Progress, **then** deck sắp theo mastery tăng dần, deck không có card đứng cuối, và hai deck bằng nhau giữ thứ tự thủ công (A4).
- [ ] **Given** bộ lọc chỉ-deck-có-thẻ-đến-hạn đang bật và không deck nào có thẻ đến hạn, **when** xem danh sách, **then** danh sách rỗng và nói rõ lý do (A4).
- [ ] **Given** đọc dữ liệu lỗi, **when** tải danh sách, **then** hệ thống hiện lỗi bằng lời thường kèm Retry, và Retry tải lại (E1).

### UC-DECK-004 — Tạo phần tử con và xác lập `content_type`
Status: ready · Code: [lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/usecases/create_sub_deck_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart] · Invokes: [FN-DECK-008, FN-DECK-009]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Bấm Create bên trong một deck
**Preconditions:** Deck tồn tại

Đây là use case định hình toàn bộ cấu trúc cây, và là chỗ dễ cài sai nhất vì nút
Create có ba hành vi khác nhau tuỳ trạng thái deck.

#### Main flow

**Main flow:**
1. Người dùng bấm Create trong một deck.
2. Hệ thống quyết định lựa chọn hiển thị (FN-DECK-008):

   | Deck | Lựa chọn hiện ra |
   | root deck (`content_type = 'deck'`, bất biến) | **chỉ** Create deck |
   | deck con, `content_type = 'unset'` | Create card **và** Create deck |
   | deck con, `content_type = 'card'` | **chỉ** Create card |
   | deck con, `content_type = 'deck'` | **chỉ** Create deck |

3. Người dùng chọn một hành động và nhập nội dung.
4. Hệ thống thực hiện **trong một transaction**:
   - nếu deck đang `unset`: đặt `content_type` theo hành động đã chọn;
   - tạo phần tử con: card (kèm study state; chức năng của feature card) hoặc deck con mới
     (FN-DECK-009) với
     `content_type = 'unset'`, `parent_id` = deck hiện tại,
     `root_id` = root của deck hiện tại, và **không** có cột
     scheduler.
5. Từ đây nút Create trong deck này chỉ hiện hành động tương ứng.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Deck đã `card`:** không có lựa chọn tạo deck con, ở bất kỳ đâu trong UI.
- **A2 — Deck đã `deck`:** không có lựa chọn tạo card.
- **A3 — Phần tử con cuối cùng rời đi:** xoá card cuối, xoá deck con cuối hoặc
  di chuyển deck con cuối sang cha khác đều đưa `content_type` của sub-deck về
  `unset`, trong cùng transaction với mutation đó. Không có thao tác
  reset thủ công nào, và không cần có.
- **A4 — Huỷ giữa chừng:** không tạo gì và **không** xác lập `content_type` —
  `content_type` chỉ đổi cùng với việc phần tử con thực sự được tạo.

**Error flows:**
- **E1 — Validate thất bại** (tên deck rỗng, card thiếu mặt): lỗi inline; không
  tạo gì và không đổi `content_type`.
- **E2 — Ghi thất bại giữa chừng:** transaction rollback. Deck giữ nguyên
  `content_type` cũ và không có phần tử con nửa vời — chiều xoá cũng
  vậy: mutation và thay đổi type cùng sống hoặc cùng chết.
- **E3 — Cố tạo card trong root deck:** không có đường nào tới được trạng thái
  này qua UI. Nếu xảy ra qua deep link hoặc lỗi lập trình, từ chối và log
  — đây là vi phạm ràng buộc "root deck chỉ chứa deck con" và validation phải bắt được.
- **E4 — Deck cha đã ở cấp 10:** tạo deck con bị chặn trước khi ghi.
  Không tạo gì và không đổi `content_type` của deck cha — kể cả khi nó đang
  `unset`. Tạo card không bị giới hạn này: card không thêm cấp cho cây.

#### Acceptance criteria

- [ ] **Given** một root deck, **when** bấm Create, **then** chỉ có Create deck.
- [ ] **Given** một deck con `content_type = 'unset'`, **when** bấm Create, **then** có cả Create card và Create deck.
- [ ] **Given** một deck con `unset`, **when** tạo deck con đầu tiên, **then** nó thành `content_type = 'deck'` trong cùng transaction với việc tạo, và deck mới có `root_id` bằng root của cha.
- [ ] **Given** một deck con `unset`, **when** tạo card đầu tiên, **then** nó thành `content_type = 'card'`, và study state của card được tạo cùng transaction theo scheduler và `generation` của root.
- [ ] **Given** một deck `content_type = 'card'`, **when** mở lựa chọn tạo hoặc gọi tạo deck con, **then** không có lựa chọn tạo deck con và lời gọi bị từ chối (A1).
- [ ] **Given** một deck `content_type = 'deck'`, **when** mở lựa chọn tạo hoặc gọi tạo card, **then** không có lựa chọn tạo card và lời gọi bị từ chối (A2).
- [ ] **Given** một deck con chỉ còn một phần tử con active, **when** phần tử đó bị xoá hoặc di chuyển đi, **then** deck con về `unset` trong cùng transaction, không cần thao tác tay (A3).
- [ ] **Given** dialog tạo deck con hoặc card đang mở, **when** người dùng huỷ, **then** không tạo gì và `content_type` của deck cha không đổi (A4).
- [ ] **Given** tên deck con rỗng hoặc card thiếu một mặt, **when** xác nhận, **then** lỗi hiện ngay dưới ô nhập, không tạo gì và `content_type` không đổi (E1).
- [ ] **Given** ghi thất bại giữa chừng (ví dụ không ghi được study state), **when** tạo card, **then** không có card nào được ghi và `content_type` của deck cha không đổi (E2).
- [ ] **Given** một root deck, **when** tạo card trực tiếp trong nó, **then** thao tác bị từ chối và không tạo gì (E3).
- [ ] **Given** deck cha ở cấp 10, **when** tạo deck con, **then** bị chặn trước khi ghi và `content_type` của deck cha không đổi; tạo card ở cấp 10 vẫn được (E4).

### UC-DECK-005 — Di chuyển deck trong cây
Status: ready · Code: [lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart, lib/features/deck/domain/usecases/move_deck_use_case.dart] · Invokes: [FN-DECK-010, FN-DECK-011]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn di chuyển một deck sang deck cha khác
**Preconditions:** Deck nguồn và deck đích tồn tại

#### Main flow

**Main flow:**
1. Người dùng chọn deck nguồn và deck đích trong các đích hợp lệ (FN-DECK-010).
2. Hệ thống thực hiện FN-DECK-011, kiểm tra theo thứ tự:
   - đích không phải chính deck nguồn hoặc descendant của nó;
   - đích có `content_type = 'deck'` hoặc `'unset'` — không thể đưa deck
     vào một deck chỉ chứa card;
   - root của đích có cùng `scheduler_type` và `generation` với root
     của nguồn;
   - độ sâu sau move không vượt giới hạn: với `targetDepth` là cấp của
     deck đích (root là cấp 1) và `subtreeHeight` là chiều cao subtree nguồn
     (deck nguồn tính là 1), MUST có `targetDepth + subtreeHeight <= 10`.
3. Hệ thống thực hiện **trong một transaction**:
   - đặt `parent_id` của deck nguồn thành deck đích;
   - cập nhật `root_id` và `depth` cho **toàn bộ subtree** của deck nguồn;
   - nếu đích đang `unset`, đặt `content_type = 'deck'`;
   - nếu deck cha **cũ** là sub-deck và vừa mất phần tử con cuối cùng, đặt
     `content_type` của nó về `unset`; cha cũ là root thì giữ `deck`.
4. Cây được vẽ lại.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Di chuyển trong cùng một cây (cùng root):** `root_id` không đổi,
  nhưng vẫn phải chạy trong transaction cùng với việc đổi `parent_id`.
- **A2 — Di chuyển lên thành root deck:** ngoài phạm vi MVP — deck nguồn sẽ cần
  scheduler riêng, tức là một quyết định mới, không phải một phép di chuyển.

**Error flows:**
- **E1 — Đích là chính nó hoặc descendant:** chặn, lỗi rõ ràng "Không thể di
  chuyển deck vào chính nó". Đây là phép kiểm tra chống cycle.
- **E2 — Đích có `content_type = 'card'`:** chặn, giải thích deck đích chỉ chứa
  card.
- **E3 — Root đích khác scheduler hoặc generation:** **chặn**, và đề nghị đặt lại
  tiến độ học một cách tường minh. Không im lặng chuyển đổi state — không
  có ánh xạ nào có cơ sở giữa box và ease factor.
- **E4 — Thất bại giữa chừng:** transaction rollback — con trỏ cha, con
  trỏ root của cả subtree, `content_type` của đích **và** `content_type` của cha
  cũ cùng quay lại nguyên trạng. Không có descendant nào trỏ sai root.
- **E5 — Vượt độ sâu tối đa:** `targetDepth + subtreeHeight > 10` → chặn trước
  khi ghi. Không đổi `parent_id`, `root_id`, `content_type`
  của đích hay bất kỳ timestamp nào.

#### Acceptance criteria

- [ ] **Given** deck nguồn và đích hợp lệ (đích không phải chính nó hay descendant, đích `deck` hoặc `unset`, cùng scheduler và generation, độ sâu sau khi di chuyển không quá 10), **when** di chuyển, **then** deck nguồn nhận `parent_id` mới và cả subtree có `root_id` và độ sâu đúng, trong một transaction.
- [ ] **Given** đích đang `unset` và deck cha cũ (không phải root) vừa mất phần tử con cuối cùng, **when** di chuyển xong, **then** đích thành `content_type = 'deck'` và cha cũ về `unset`, cùng transaction với việc di chuyển.
- [ ] **Given** nguồn và đích cùng một root, **when** di chuyển, **then** `root_id` không đổi và việc đổi `parent_id` vẫn chạy trong transaction (A1).
- [ ] **Given** deck nguồn là root, **when** di chuyển, **then** bị từ chối: đưa một deck lên hay xuống vị trí root nằm ngoài phạm vi (A2).
- [ ] **Given** đích là chính deck nguồn hoặc một descendant của nó, **when** di chuyển, **then** bị chặn với lý do rõ ràng và `parent_id` không đổi (E1).
- [ ] **Given** đích có `content_type = 'card'`, **when** di chuyển, **then** bị chặn kèm giải thích và `parent_id` không đổi (E2).
- [ ] **Given** root của đích khác `scheduler_type` hoặc `generation` với root của nguồn, **when** di chuyển, **then** bị chặn và không có chuyển đổi study state ngầm nào (E3).
- [ ] **Given** di chuyển thất bại giữa chừng, **when** transaction dừng, **then** con trỏ cha, `root_id` của cả subtree, `content_type` của đích và của cha cũ đều trở lại như trước (E4).
- [ ] **Given** cấp của đích cộng chiều cao subtree vượt 10, **when** di chuyển, **then** bị chặn trước khi ghi, và không `parent_id`, `root_id`, `content_type` hay timestamp nào đổi (E5).

### UC-DECK-006 — Sắp xếp lại Deck cùng cấp
Status: ready · Code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart] · Invokes: [FN-DECK-012]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chọn Reorder trong action sheet của một deck khi Library đang ở
Manual order, rồi kéo deck tới vị trí mới; với TalkBack, dùng action Move up
hoặc Move down trên hàng deck (quyết định của chủ dự án 2026-09-28, theo kit 01).
**Preconditions:** Source và target là deck active cùng một level; danh sách
đang ở Manual order để thứ tự nhìn thấy chính là thứ tự persisted.

#### Main flow

**Main flow:**
1. Hệ thống lấy sibling liền trước hoặc sau từ thứ tự Manual đã lưu và gửi
   operation `before`/`after`, không gửi một database index thô.
2. Hệ thống thực hiện FN-DECK-012: mở một transaction, đọc lại source và target active, xác nhận
   chúng còn cùng `parent_id`, rồi cập nhật thứ tự nhóm sibling.
3. Watch của level phát emission mới; danh sách đổi vị trí tại chỗ. Mọi parent,
   root pointer, scheduler, card, study state và subtree giữ nguyên.

#### Alternative / Error flow

**Alternative flows:** Ở chế độ Reorder, deck đầu không có action Move up của
TalkBack và deck cuối không có Move down; level chỉ có một deck không hiện mục
Reorder. Khi đang dùng sort theo
tên, ngày, due hoặc tiến độ, thao tác bị ẩn để neighbour không bị
suy ra từ một view-only order.

**Error flows:** Source hoặc target đã stale, hoặc không còn sibling → transaction
từ chối và không ghi gì. Lỗi database ở bất kỳ update nào → toàn transaction
rollback, thứ tự cũ giữ nguyên.

#### Acceptance criteria

- [ ] **Given** hai deck cùng `parent_id` ở Manual order, **when** hệ thống gửi thao tác `before` hoặc `after` theo sibling liền kề, **then** chỉ `sibling_position` (và `updated_at` của các sibling đổi chỗ) thay đổi; `parent_id`, `root_id`, scheduler, card, study state và subtree giữ nguyên, trong một transaction.
- [ ] **Given** nhiều root deck, **when** sắp xếp lại, **then** chúng đổi chỗ trong đúng nhóm sibling gốc.
- [ ] **Given** level đang ở Manual order và chỉ có một deck, **when** mở action sheet của deck đó, **then** không có thao tác sắp xếp lại; có từ hai deck trở lên thì có.
- [ ] **Given** level đang dùng một sort chỉ để xem (tên, ngày, due hoặc tiến độ), **when** mở action sheet của một deck, **then** thao tác sắp xếp lại bị ẩn.
- [ ] **Given** source và target không còn cùng `parent_id`, **when** sắp xếp lại, **then** transaction từ chối và không ghi gì.
- [ ] **Given** deck hoặc anchor không còn, **when** sắp xếp lại, **then** thao tác bị từ chối, không ghi gì và thứ tự cũ giữ nguyên.
- [ ] **Given** một update lỗi giữa lúc đánh số lại nhóm sibling, **when** transaction dừng, **then** toàn bộ rollback và thứ tự cũ giữ nguyên.
- [ ] **Given** level đang ở Manual order với từ hai deck, **when** người dùng chọn Reorder và kéo một deck, hoặc dùng Move up / Move down của TalkBack, **then** deck đổi chỗ với sibling kề đó và không có deck nào khác đổi thứ tự.

