# Use cases

Mọi use case của app, nhóm theo feature. Định dạng section và dòng meta:
[docs/README.md](README.md), mục "UC, FN và screen spec".

## Deck

### UC-DECK-001 — Tạo root deck
Status: ready · Code: [lib/features/deck/domain/usecases/create_root_deck_use_case.dart] · Invokes: [FN-DECK-001]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Có một deck mới ở cấp gốc của thư viện, với chế độ ôn tập mà các card của nó sẽ
theo.
**Preconditions:** Không có

#### Main flow

**Main flow:**
1. Người dùng đặt tên cho deck.
2. Người dùng **chọn chế độ ôn tập**: `eight_box` hoặc `sm2`. Bắt buộc, không có mặc định ngầm
   bỏ qua bước này.
3. Người dùng được cho biết mỗi chế độ là gì, và rằng chế độ sẽ khoá khi thẻ đầu tiên hoàn tất
   chuỗi học mới.
4. Người dùng xác nhận.
5. Hệ thống thực hiện FN-DECK-001.
6. Deck mới có trong thư viện, rỗng.

**Root deck chỉ chứa deck con:** bên trong nó chỉ tạo được deck con. Việc tạo phần tử con là một
use case riêng.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Người dùng huỷ:** không tạo gì; những gì đã nhập chỉ bị bỏ khi người dùng xác nhận bỏ.

**Error flows:**
- **E1 — Tên rỗng:** không tạo gì; người dùng được báo tên không hợp lệ.
- **E2 — Tên quá 200 ký tự:** không tạo gì; tên không bị cắt âm thầm.
- **E3 — Chưa chọn chế độ:** không tạo gì; người dùng được báo phải chọn chế độ ôn tập.
- **E4 — Ghi database thất bại:** không tạo gì; người dùng được báo lỗi và những gì đã nhập vẫn
  còn.

#### Acceptance criteria

- [ ] **Given** một tên hợp lệ và một chế độ ôn tập (`eight_box` hoặc `sm2`), **when** người dùng xác nhận tạo, **then** hệ thống tạo root deck với `parent_id = NULL`, `root_id = id`, `content_type = 'deck'`, `generation = 1` và chế độ đã chọn, và deck còn sau khi khởi động lại app.
- [ ] **Given** một root deck vừa tạo, **when** người dùng muốn tạo phần tử con bên trong nó, **then** chỉ tạo được deck con, không tạo được card.
- [ ] **Given** đã có một deck tên "Unit 5", **when** tạo thêm một root deck cũng tên "Unit 5", **then** hệ thống chấp nhận và không báo trùng tên.
- [ ] **Given** tên rỗng hoặc chỉ có khoảng trắng, **when** xác nhận, **then** người dùng được báo tên không hợp lệ và không có gì được tạo (E1).
- [ ] **Given** tên dài hơn 200 ký tự, **when** xác nhận, **then** người dùng được báo tên quá dài và không có gì được tạo (E2).
- [ ] **Given** ghi database thất bại, **when** xác nhận, **then** người dùng được báo lỗi, những gì đã nhập vẫn còn, và không có deck nào được tạo (E4).
- [ ] **Given** người dùng đã nhập tên hoặc chọn chế độ, **when** người dùng huỷ, **then** hệ thống hỏi trước khi bỏ những gì đã nhập; giữ lại thì mọi thứ còn nguyên, bỏ thì không có gì được tạo. Chưa nhập gì thì huỷ ngay (A1).
- [ ] **Given** người dùng chưa chọn chế độ ôn tập, **when** xác nhận tạo, **then** không có chế độ nào được chọn sẵn, người dùng được báo phải chọn chế độ, và không có deck nào được tạo (E3).

### UC-DECK-002 — Sửa và xoá deck
Status: ready · Code: [lib/features/deck/domain/usecases/rename_deck_use_case.dart, lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart, lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart] · Invokes: [FN-DECK-002, FN-DECK-003, FN-DECK-004, FN-DECK-005, FN-DECK-006]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Đổi tên một deck, đổi chế độ ôn tập của một root deck, hoặc bỏ một deck vào Trash.
**Preconditions:** Deck tồn tại

#### Main flow

**Main flow (sửa tên):**
1. Người dùng đặt tên mới cho deck.
2. Hệ thống thực hiện FN-DECK-002.

**Main flow (đổi chế độ ôn tập — chỉ trên root deck, chỉ khi chưa có thẻ nào học xong chuỗi học mới):**
1. Chế độ ôn tập của root đang mở khoá (`first_answered_at IS NULL`).
2. Người dùng chọn chế độ khác.
3. Hệ thống báo trước hệ quả: study state của **toàn bộ card trong cây** sẽ được khởi tạo lại
   theo chế độ mới, và phiên học đang mở sẽ bị đóng. Đây **không** phải Reset learning
   progress: không có generation nào bị tiêu, không có lịch sử nào bị bỏ.
4. Người dùng xác nhận.
5. Hệ thống thực hiện FN-DECK-003.

**Main flow (xoá):**
1. Hệ thống thực hiện FN-DECK-004, cho người dùng biết số deck con và số card sẽ vào Trash cùng
   deck, và chờ xác nhận.
2. Người dùng xác nhận.
3. Hệ thống thực hiện FN-DECK-005.
4. Người dùng có thể hoàn tác ngay (hệ thống thực hiện FN-DECK-006), hoặc khôi phục về sau từ
   Trash.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Root deck đã có thẻ học xong chuỗi học mới:** chế độ ôn tập bị khoá; người dùng biết
  nó đang khoá, vì sao, và lối tới Reset learning progress. Chế độ đang khoá không bị giấu đi:
  giấu khiến người dùng tưởng tính năng không tồn tại.
- **A2 — Sửa deck con:** deck con không có chế độ ôn tập riêng để đổi.
- **A3 — Người dùng không xác nhận xoá:** không xảy ra gì.
- **A4 — Xác nhận đúng chế độ deck đang chạy:** thao tác được chấp nhận và không làm gì người dùng
  thấy được. Không seed lại cây, không đóng phiên đang mở — mất một phiên đang học cho một thay
  đổi bằng không là cái giá không ai đồng ý trả.

**Error flows:**
- **E1 — Deck đã bị xoá ở nơi khác:** thao tác không thành; người dùng được báo deck không còn.
- **E2 — Đổi chế độ thất bại giữa chừng:** transaction rollback; deck giữ nguyên scheduler cũ và
  study state cũ.
- **E3 — Xoá thất bại:** người dùng được báo lỗi; deck còn nguyên vẹn, và `content_type` của deck
  cha cũng không đổi — cả hai nằm trong một transaction.
- **E4 — Scheduler bị khoá trong lúc người dùng đang chọn chế độ:** người dùng học xong một thẻ ở
  nơi khác giữa chừng. Hệ thống đọc lại `first_answered_at` **bên trong** transaction và từ
  chối; người dùng biết lý do và lối tới Reset. Trạng thái người dùng đang thấy MUST NOT là thứ
  quyết định thao tác có hợp lệ hay không.

#### Acceptance criteria

- [ ] **Given** một tên mới hợp lệ, **when** người dùng đổi tên deck, **then** tên đã trim được lưu và `updated_at` cập nhật.
- [ ] **Given** một root chưa có `first_answered_at`, **when** người dùng chọn chế độ khác và xác nhận, **then** trong một transaction scheduler đổi, study state của cả cây khởi tạo lại, `generation` giữ nguyên, và mọi phiên đang mở của cây đóng với `end_reason = 'scheduler_changed'`.
- [ ] **Given** người dùng xoá một deck có N deck con active và M card active, **when** hệ thống hỏi xác nhận, **then** nó nêu đúng N và M trước khi ghi gì.
- [ ] **Given** người dùng đã xác nhận xoá, **when** transaction xong, **then** deck cùng mọi descendant active (deck và card) vào Trash trong cùng một batch và một `deleted_at`, và người dùng có thể hoàn tác ngay.
- [ ] **Given** vừa xoá một deck, **when** người dùng hoàn tác, **then** deck cùng mọi phần tử của batch đó trở lại đúng vị trí cũ.
- [ ] **Given** một descendant đã ở Trash từ một batch cũ hơn, **when** xoá deck cha của nó, **then** descendant đó giữ nguyên batch cũ, không bị gộp vào batch mới.
- [ ] **Given** một deck cha không phải root vừa mất direct child active cuối cùng vì bị xoá, **when** transaction xoá xong, **then** `content_type` của nó về `unset` trong cùng transaction; một root vẫn giữ `deck`.
- [ ] **Given** một phiên `in_progress` chạm tới item của batch, **when** xoá xảy ra, **then** phiên đó đóng với `status = invalidated`, `end_reason = content_deleted` trong cùng transaction.
- [ ] **Given** root đã có thẻ hoàn tất chuỗi học mới (`first_answered_at` khác NULL), **when** người dùng muốn đổi chế độ ôn tập, **then** người dùng biết chế độ đang khoá, vì sao, và lối tới Reset; chế độ không bị giấu (A1).
- [ ] **Given** đang sửa một deck con, **when** người dùng muốn đổi chế độ ôn tập, **then** không có chế độ nào để đổi (A2).
- [ ] **Given** hệ thống đang chờ xác nhận xoá, **when** người dùng không xác nhận, **then** không có gì thay đổi (A3).
- [ ] **Given** root đang chạy chế độ X, khoá hay chưa khoá, **when** người dùng chọn lại đúng X, **then** không ghi gì, không seed lại cây và không đóng phiên đang mở (A4).
- [ ] **Given** deck đã bị xoá ở nơi khác, **when** người dùng đổi tên hoặc xoá nó, **then** thao tác không thành, không ghi gì, và người dùng được báo deck không còn (E1).
- [ ] **Given** đổi chế độ thất bại giữa chừng, **when** transaction dừng, **then** mọi thay đổi rollback và deck giữ scheduler cùng study state cũ (E2).
- [ ] **Given** xoá thất bại giữa chừng, **when** transaction dừng, **then** người dùng được báo lỗi, deck còn nguyên và `content_type` của deck cha không đổi (E3).
- [ ] **Given** người dùng đang chọn chế độ trên một cây chưa khoá, **when** cây bị khoá ở nơi khác rồi người dùng xác nhận, **then** hệ thống đọc lại `first_answered_at` trong transaction, từ chối có lý do, và không đổi gì (E4).

### UC-DECK-003 — Xem danh sách deck với tiến độ
Status: ready · Code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/models/deck_level_model.dart, lib/features/deck/domain/models/deck_level_query_model.dart] · Invokes: [FN-DECK-007, FN-DECK-008]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Biết thư viện có gì, deck nào đang có việc phải ôn, và mỗi deck đã thuộc tới đâu.
**Preconditions:** Không có

#### Main flow

**Main flow:**
1. Hệ thống thực hiện FN-DECK-007 cho cấp gốc của thư viện.
2. Người dùng biết, với mỗi deck: tên, tổng số card trong cây, hai số card chưa học (New) và
   card đến hạn (Due) — không bao giờ gộp — và chế độ ôn tập đang dùng.
3. Người dùng biết deck nào có card đến hạn, và nó đến hạn hôm nay hay đã quá hạn; tín hiệu đó
   không chỉ dựa vào màu. Người dùng cũng biết tóm tắt của cả cấp: Overdue, Due today, New và
   Scheduled, trong đó Scheduled chỉ để biết, không phải việc phải làm.
4. Người dùng biết mastery của mỗi deck: số thẻ `mastered` trên mọi thẻ của cây; deck không có
   card không có tỉ lệ.
5. Mở một deck chứa deck con, người dùng biết mastery của cả cấp và chế độ ôn tập của cây.
6. Mở một deck, hệ thống thực hiện FN-DECK-008: người dùng thấy deck con hoặc card của nó, không
   bao giờ cả hai.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Chưa có deck nào:** người dùng được đưa tới hai lối đi — mở thư viện starter, hoặc tạo
  deck mới.
- **A2 — Dữ liệu đổi ở nơi khác:** danh sách tự cập nhật, không cần làm mới tay.
- **A3 — Cây sâu nhiều cấp:** người dùng đi xuống từng cấp; số liệu gộp luôn tính theo
  `root_id`.
- **A4 — Sắp xếp và lọc:** Manual, Newest, Name, Most due hoặc Progress, cùng bộ lọc chỉ giữ deck
  có thẻ đến hạn. Mọi cách sắp xếp kết thúc bằng thứ tự thủ công.

**Error flows:**
- **E1 — Đọc thất bại:** người dùng được báo lỗi và có thể thử lại.

#### Acceptance criteria

- [ ] **Given** nhiều root deck với card ở nhiều cấp, **when** danh sách deck tải hoặc phát lại, **then** mỗi lần phát chỉ chạy đúng một câu lệnh gộp theo `root_id`, không phải một câu mỗi deck, kể cả khi cây sâu nhiều cấp (A3).
- [ ] **Given** deck có card mới, card đến hạn hôm nay và card quá hạn, **when** xem danh sách, **then** số New và số Due tách biệt, không bao giờ gộp, và Due bằng Overdue cộng Due today.
- [ ] **Given** cây có N card active trong đó M card `mastered`, **when** xem deck đó, **then** mastery của deck là M/N; deck không có card không có tỉ lệ.
- [ ] **Given** một card `mastered` đang ở Trash, **when** tính mastery của deck chứa nó, **then** card đó không được tính ở cả tử số lẫn mẫu số.
- [ ] **Given** một deck `content_type = 'deck'`, **when** mở nó, **then** người dùng thấy deck con; một deck `content_type = 'card'` thì thấy card; không bao giờ cả hai.
- [ ] **Given** không deck nào có card đến hạn, **when** xem danh sách, **then** đó là trạng thái bình thường, không phải lỗi.
- [ ] **Given** chưa có deck nào, **when** mở danh sách, **then** người dùng có hai lối: tạo deck mới và mở thư viện starter (A1).
- [ ] **Given** danh sách đang mở, **when** dữ liệu đổi ở nơi khác (thêm card, card thành `mastered`, deck mới), **then** danh sách tự cập nhật mà không cần làm mới tay (A2).
- [ ] **Given** các deck có mastery khác nhau và có deck không có card, **when** chọn sắp xếp theo Progress, **then** deck sắp theo mastery tăng dần, deck không có card đứng cuối, và hai deck bằng nhau giữ thứ tự thủ công (A4).
- [ ] **Given** bộ lọc chỉ-deck-có-thẻ-đến-hạn đang bật và không deck nào có thẻ đến hạn, **when** xem danh sách, **then** danh sách rỗng và người dùng biết vì sao (A4).
- [ ] **Given** đọc dữ liệu lỗi, **when** tải danh sách, **then** người dùng được báo lỗi bằng lời thường và có thể thử lại; thử lại thì đọc lại (E1).

### UC-DECK-004 — Tạo phần tử con và xác lập `content_type`
Status: ready · Code: [lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/usecases/create_sub_deck_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart] · Invokes: [FN-DECK-008, FN-DECK-009]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Thêm một card hoặc một deck con vào một deck; lần thêm đầu tiên quyết định deck đó
chứa gì.
**Preconditions:** Deck tồn tại

Đây là use case định hình toàn bộ cấu trúc cây, và là chỗ dễ cài sai nhất vì việc tạo có ba
hành vi khác nhau tuỳ trạng thái deck.

#### Main flow

**Main flow:**
1. Người dùng muốn tạo một phần tử con trong một deck.
2. Hệ thống thực hiện FN-DECK-008 để biết những gì tạo được:

   | Deck | Tạo được |
   | root deck (`content_type = 'deck'`, bất biến) | **chỉ** deck con |
   | deck con, `content_type = 'unset'` | card **và** deck con |
   | deck con, `content_type = 'card'` | **chỉ** card |
   | deck con, `content_type = 'deck'` | **chỉ** deck con |

3. Người dùng chọn loại phần tử và đưa nội dung.
4. Hệ thống tạo phần tử **trong một transaction**:
   - nếu deck đang `unset`: đặt `content_type` theo loại phần tử vừa tạo;
   - tạo phần tử con: một card kèm study state (chức năng của feature card), hoặc một deck con
     qua FN-DECK-009.
5. Từ đây deck này chỉ nhận loại phần tử tương ứng.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Deck đã `card`:** không tạo được deck con trong nó, bằng bất kỳ đường nào.
- **A2 — Deck đã `deck`:** không tạo được card trong nó.
- **A3 — Phần tử con cuối cùng rời đi:** xoá card cuối, xoá deck con cuối hoặc di chuyển deck con
  cuối sang cha khác đều đưa `content_type` của sub-deck về `unset`, trong cùng transaction với
  mutation đó. Không có thao tác reset thủ công nào, và không cần có.
- **A4 — Huỷ giữa chừng:** không tạo gì và **không** xác lập `content_type` — `content_type` chỉ
  đổi cùng với việc phần tử con thực sự được tạo.

**Error flows:**
- **E1 — Validate thất bại** (tên deck rỗng, card thiếu mặt): không tạo gì, không đổi
  `content_type`; người dùng được báo cái gì chưa hợp lệ.
- **E2 — Ghi thất bại giữa chừng:** transaction rollback. Deck giữ nguyên `content_type` cũ và
  không có phần tử con nửa vời — chiều xoá cũng vậy: mutation và thay đổi type cùng sống hoặc
  cùng chết.
- **E3 — Cố tạo card trong root deck:** không đường nào của app dẫn tới đây. Nếu xảy ra qua deep
  link hoặc lỗi lập trình, từ chối và log — đây là vi phạm ràng buộc "root deck chỉ chứa deck
  con" và validation phải bắt được.
- **E4 — Deck cha đã ở cấp 10:** tạo deck con bị chặn trước khi ghi. Không tạo gì và không đổi
  `content_type` của deck cha — kể cả khi nó đang `unset`. Tạo card không bị giới hạn này: card
  không thêm cấp cho cây.

#### Acceptance criteria

- [ ] **Given** một root deck, **when** người dùng muốn tạo phần tử con, **then** chỉ tạo được deck con.
- [ ] **Given** một deck con `content_type = 'unset'`, **when** người dùng muốn tạo phần tử con, **then** tạo được cả card và deck con.
- [ ] **Given** một deck con `unset`, **when** tạo deck con đầu tiên, **then** nó thành `content_type = 'deck'` trong cùng transaction với việc tạo, và deck mới có `root_id` bằng root của cha.
- [ ] **Given** một deck con `unset`, **when** tạo card đầu tiên, **then** nó thành `content_type = 'card'`, và study state của card được tạo cùng transaction theo scheduler và `generation` của root.
- [ ] **Given** một deck `content_type = 'card'`, **when** người dùng muốn tạo deck con, hoặc có lời gọi tạo deck con, **then** không tạo được và lời gọi bị từ chối (A1).
- [ ] **Given** một deck `content_type = 'deck'`, **when** người dùng muốn tạo card, hoặc có lời gọi tạo card, **then** không tạo được và lời gọi bị từ chối (A2).
- [ ] **Given** một deck con chỉ còn một phần tử con active, **when** phần tử đó bị xoá hoặc di chuyển đi, **then** deck con về `unset` trong cùng transaction, không cần thao tác tay (A3).
- [ ] **Given** người dùng đang tạo deck con hoặc card, **when** người dùng huỷ, **then** không tạo gì và `content_type` của deck cha không đổi (A4).
- [ ] **Given** tên deck con rỗng hoặc card thiếu một mặt, **when** xác nhận, **then** người dùng được báo cái gì chưa hợp lệ, không tạo gì và `content_type` không đổi (E1).
- [ ] **Given** ghi thất bại giữa chừng (ví dụ không ghi được study state), **when** tạo card, **then** không có card nào được ghi và `content_type` của deck cha không đổi (E2).
- [ ] **Given** một root deck, **when** có lời gọi tạo card trực tiếp trong nó, **then** thao tác bị từ chối và không tạo gì (E3).
- [ ] **Given** deck cha ở cấp 10, **when** tạo deck con, **then** bị chặn trước khi ghi và `content_type` của deck cha không đổi; tạo card ở cấp 10 vẫn được (E4).

### UC-DECK-005 — Di chuyển deck trong cây
Status: ready · Code: [lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart, lib/features/deck/domain/usecases/move_deck_use_case.dart] · Invokes: [FN-DECK-010, FN-DECK-011]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Đưa một deck con, cùng mọi thứ bên dưới nó, sang dưới một deck cha khác.
**Preconditions:** Deck nguồn và deck đích tồn tại

#### Main flow

**Main flow:**
1. Hệ thống thực hiện FN-DECK-010; người dùng chọn deck đích trong các đích hợp lệ.
2. Hệ thống thực hiện FN-DECK-011, kiểm tra theo thứ tự:
   - đích không phải chính deck nguồn hoặc descendant của nó;
   - đích có `content_type = 'deck'` hoặc `'unset'` — không thể đưa deck vào một deck chỉ chứa
     card;
   - độ sâu sau move không vượt giới hạn: với `targetDepth` là cấp của deck đích (root là cấp 1)
     và `subtreeHeight` là chiều cao subtree nguồn (deck nguồn tính là 1), MUST có
     `targetDepth + subtreeHeight <= 10`;
   - root của đích có cùng `scheduler_type` và `generation` với root của nguồn.
3. Hệ thống thực hiện **trong một transaction**:
   - đặt `parent_id` của deck nguồn thành deck đích;
   - cập nhật `root_id` và `depth` cho **toàn bộ subtree** của deck nguồn;
   - nếu đích đang `unset`, đặt `content_type = 'deck'`;
   - nếu deck cha **cũ** là sub-deck và vừa mất phần tử con cuối cùng, đặt `content_type` của nó
     về `unset`; cha cũ là root thì giữ `deck`.
4. Người dùng thấy cây ở hình dạng mới.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Di chuyển trong cùng một cây (cùng root):** `root_id` không đổi, nhưng vẫn phải chạy
  trong transaction cùng với việc đổi `parent_id`.
- **A2 — Di chuyển lên thành root deck:** ngoài phạm vi MVP — deck nguồn sẽ cần scheduler riêng,
  tức là một quyết định mới, không phải một phép di chuyển.

**Error flows:**
- **E1 — Đích là chính nó hoặc descendant:** chặn; người dùng biết vì sao. Đây là phép kiểm tra
  chống cycle.
- **E2 — Đích có `content_type = 'card'`:** chặn; người dùng biết deck đích chỉ chứa card.
- **E3 — Root đích khác scheduler hoặc generation:** **chặn**, và đề nghị đặt lại tiến độ học một
  cách tường minh. Không im lặng chuyển đổi state — không có ánh xạ nào có cơ sở giữa box và ease
  factor.
- **E4 — Thất bại giữa chừng:** transaction rollback — con trỏ cha, con trỏ root của cả subtree,
  `content_type` của đích **và** `content_type` của cha cũ cùng quay lại nguyên trạng. Không có
  descendant nào trỏ sai root.
- **E5 — Vượt độ sâu tối đa:** `targetDepth + subtreeHeight > 10` → chặn trước khi ghi. Không
  đổi `parent_id`, `root_id`, `content_type` của đích hay bất kỳ timestamp nào.

#### Acceptance criteria

- [ ] **Given** deck nguồn và đích hợp lệ (đích không phải chính nó hay descendant, đích `deck` hoặc `unset`, độ sâu sau khi di chuyển không quá 10, cùng scheduler và generation), **when** di chuyển, **then** deck nguồn nhận `parent_id` mới và cả subtree có `root_id` và độ sâu đúng, trong một transaction.
- [ ] **Given** đích đang `unset` và deck cha cũ (không phải root) vừa mất phần tử con cuối cùng, **when** di chuyển xong, **then** đích thành `content_type = 'deck'` và cha cũ về `unset`, cùng transaction với việc di chuyển.
- [ ] **Given** nguồn và đích cùng một root, **when** di chuyển, **then** `root_id` không đổi và việc đổi `parent_id` vẫn chạy trong transaction (A1).
- [ ] **Given** deck nguồn là root, **when** di chuyển, **then** bị từ chối: đưa một deck lên hay xuống vị trí root nằm ngoài phạm vi (A2).
- [ ] **Given** đích là chính deck nguồn hoặc một descendant của nó, **when** di chuyển, **then** bị chặn, người dùng biết vì sao, và `parent_id` không đổi (E1).
- [ ] **Given** đích có `content_type = 'card'`, **when** di chuyển, **then** bị chặn, người dùng biết vì sao, và `parent_id` không đổi (E2).
- [ ] **Given** root của đích khác `scheduler_type` hoặc `generation` với root của nguồn, **when** di chuyển, **then** bị chặn và không có chuyển đổi study state ngầm nào (E3).
- [ ] **Given** di chuyển thất bại giữa chừng, **when** transaction dừng, **then** con trỏ cha, `root_id` của cả subtree, `content_type` của đích và của cha cũ đều trở lại như trước (E4).
- [ ] **Given** cấp của đích cộng chiều cao subtree vượt 10, **when** di chuyển, **then** bị chặn trước khi ghi, và không `parent_id`, `root_id`, `content_type` hay timestamp nào đổi (E5).

### UC-DECK-006 — Sắp xếp lại Deck cùng cấp
Status: ready · Code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart] · Invokes: [FN-DECK-012]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Đặt một deck vào chỗ khác giữa các deck cùng cấp, theo thứ tự thủ công.
**Preconditions:** Deck và deck mốc là deck active cùng một cấp; cấp đó đang theo thứ tự Manual,
để thứ tự người dùng thấy chính là thứ tự đã lưu.

#### Main flow

**Main flow:**
1. Người dùng chỉ ra chỗ mới của deck: ngay trước hoặc ngay sau một deck cùng cấp.
2. Hệ thống thực hiện FN-DECK-012 với deck mốc là sibling liền kề theo thứ tự Manual đã lưu và
   vị trí `before`/`after`, không phải một index database thô.
3. Danh sách cập nhật tại chỗ. Mọi parent, root pointer, scheduler, card, study state và subtree
   giữ nguyên.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Cấp chỉ có một deck:** không có gì để sắp xếp lại.
- **A2 — Đang dùng một cách sắp xếp chỉ để xem** (tên, ngày, due hoặc tiến độ): không sắp xếp lại
  được, để deck mốc không bị suy ra từ một thứ tự chỉ để xem.

**Error flows:** Deck hoặc deck mốc đã stale, hoặc hai deck không còn cùng cấp → transaction từ
chối và không ghi gì. Lỗi database ở bất kỳ update nào → toàn transaction rollback, thứ tự cũ
giữ nguyên.

#### Acceptance criteria

- [ ] **Given** hai deck cùng `parent_id` ở thứ tự Manual, **when** hệ thống nhận thao tác `before` hoặc `after` theo sibling liền kề, **then** chỉ `sibling_position` (và `updated_at` của các sibling đổi chỗ) thay đổi; `parent_id`, `root_id`, scheduler, card, study state và subtree giữ nguyên, trong một transaction.
- [ ] **Given** nhiều root deck, **when** sắp xếp lại, **then** chúng đổi chỗ trong đúng nhóm sibling gốc.
- [ ] **Given** cấp đang ở thứ tự Manual và chỉ có một deck, **when** người dùng muốn sắp xếp lại, **then** không có gì để sắp xếp; có từ hai deck trở lên thì sắp xếp được (A1).
- [ ] **Given** cấp đang dùng một cách sắp xếp chỉ để xem (tên, ngày, due hoặc tiến độ), **when** người dùng muốn sắp xếp lại, **then** không sắp xếp lại được (A2).
- [ ] **Given** hai deck không còn cùng `parent_id`, **when** sắp xếp lại, **then** transaction từ chối và không ghi gì.
- [ ] **Given** deck hoặc deck mốc không còn, **when** sắp xếp lại, **then** thao tác bị từ chối, không ghi gì và thứ tự cũ giữ nguyên.
- [ ] **Given** một update lỗi giữa lúc đánh số lại nhóm sibling, **when** transaction dừng, **then** toàn bộ rollback và thứ tự cũ giữ nguyên.
- [ ] **Given** cấp đang ở thứ tự Manual với từ hai deck, **when** người dùng chuyển một deck lên trước hoặc xuống sau sibling kề nó, **then** deck đổi chỗ với sibling đó và không có deck nào khác đổi thứ tự.
