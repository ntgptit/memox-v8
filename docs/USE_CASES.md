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
Status: ready · Code: [lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/usecases/create_sub_deck_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart] · Invokes: [FN-DECK-008, FN-DECK-009, FN-CARD-002]

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
   - tạo phần tử con: một card kèm study state qua FN-CARD-002, hoặc một deck con qua FN-DECK-009.
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

## Card

### UC-CARD-001 — Quản lý card trong deck
Status: ready · Code: [lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart, lib/features/card/domain/usecases/edit_card_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/move_cards_use_case.dart, lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart, lib/features/card/domain/usecases/set_cards_flagged_use_case.dart, lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart, lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart] · Invokes: [FN-CARD-001, FN-CARD-002, FN-CARD-003, FN-CARD-004, FN-CARD-005, FN-CARD-006, FN-CARD-007, FN-CARD-008, FN-CARD-009, FN-CARD-010, FN-CARD-011, FN-CARD-012]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Xem, thêm, sửa, sắp xếp lại và bỏ các card của một deck chứa card.
**Preconditions:** Deck tồn tại và `content_type = 'card'`.

#### Main flow

**Main flow:**
1. Hệ thống thực hiện FN-CARD-001; người dùng biết các card của deck.
2. Người dùng thêm một card: mặt trước và mặt sau, tuỳ chọn ví dụ, gợi ý và phiên âm.
3. Hệ thống thực hiện FN-CARD-002.
4. Card mới có trong deck; số card của deck tăng.

Card đầu tiên của một deck `unset` được tạo qua use case tạo phần tử con, và chính nó xác lập
`content_type = 'card'`.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Sửa card:** hệ thống thực hiện FN-CARD-003; nội dung đổi, study state và lịch sử **không**
  đổi.
- **A2 — Xoá card:** hệ thống chờ người dùng xác nhận, rồi thực hiện FN-CARD-004. Xoá **một** card
  thì người dùng có thể hoàn tác ngay (hệ thống thực hiện FN-CARD-005); khôi phục về sau qua
  Trash. Nếu đó là card active **cuối cùng**, deck trở về `unset` trong cùng transaction; người
  dùng lại chọn được tạo card hay tạo deck con. "Deck `card` rỗng" không còn là một trạng thái ổn
  định của hệ thống.
- **A3 — Deck còn card nhưng không card nào khớp bộ lọc:** đó là kết quả rỗng của bộ lọc, không
  phải deck rỗng, và người dùng có lối bỏ bộ lọc.
- **A4 — Thêm liên tiếp nhiều card:** sau mỗi lần lưu, người dùng thêm được card kế tiếp ngay.
- **A5 — Di chuyển card sang deck khác:** hệ thống thực hiện FN-CARD-006, người dùng chọn deck
  đích trong cùng root, rồi hệ thống thực hiện FN-CARD-007; card chỉ đổi chỗ.
- **A6 — Thao tác trên nhiều card:** người dùng chọn nhiều card và áp một thao tác hàng loạt: di
  chuyển, gắn tag, bật cờ, bỏ cờ, xoá. Chọn tất cả lấy mọi card khớp bộ lọc và tìm kiếm hiện tại,
  không chỉ phần đã tải (FN-CARD-008). Mỗi thao tác là all-or-nothing.
- **A7 — Cờ:** người dùng bật hoặc bỏ cờ của card (FN-CARD-009).
- **A8 — Tag:** người dùng gắn tag theo tên — dùng lại tag cùng tên, tạo mới nếu chưa có
  (FN-CARD-010) — hoặc gỡ tag khỏi card (FN-CARD-011); người dùng lọc danh sách theo tag
  (FN-CARD-012).
- **A9 — Mở chi tiết:** chọn một card khi không ở chế độ chọn nhiều mở chi tiết chỉ đọc của nó;
  sửa là một hành động riêng.

**Error flows:**
- **E1 — Mặt trước hoặc mặt sau rỗng:** không ghi gì; người dùng được báo đúng mặt nào.
- **E2 — Vượt giới hạn độ dài:** không ghi gì; người dùng được báo đúng trường nào.
- **E3 — Ghi thất bại:** người dùng được báo lỗi, nội dung đã nhập vẫn còn; không có card nào thiếu
  study state.
- **E5 — Deck đích không hợp lệ:** chỉ deck cùng root, không phải root, không chứa deck con và
  không phải chính deck nguồn mới là đích. Nếu một thao tác vẫn mang đích không hợp lệ tới trước
  khi ghi — deep link, hoặc cây đổi giữa lúc chọn và lúc xác nhận — nó bị từ chối kèm lý do có kiểu
  và không ghi gì.
- **E6 — Một card trong lô vi phạm:** cả lô rollback; danh sách và lựa chọn giữ nguyên; người dùng
  biết vì sao.
- **E7 — Tag không hợp lệ, hoặc card đã đủ 10 tag:** lỗi có kiểu; tag của card giữ nguyên.

#### Acceptance criteria

- [ ] **Given** một deck `unset` và một bản nháp hợp lệ, **when** người dùng thêm card, **then** card và study state mới của nó (theo scheduler và generation của root) được ghi trong một transaction, và deck thành `content_type = card`.
- [ ] **Given** một card đã có study state và lịch sử, **when** người dùng sửa nội dung, **then** nội dung, cờ và tag đổi nhưng study state và `review_log` không đổi (A1).
- [ ] **Given** người dùng xoá đúng một card, **when** xác nhận, **then** card vào Trash, nội dung, study state và lịch sử giữ nguyên tới khi purge, và người dùng có thể hoàn tác ngay (A2).
- [ ] **Given** người dùng xoá nhiều card, **when** xác nhận, **then** tất cả vào Trash cùng lúc và không có hoàn tác ngay (A2).
- [ ] **Given** card bị xoá là card active cuối cùng của deck, **when** xoá thành công, **then** deck về `content_type = unset` trong cùng transaction (A2).
- [ ] **Given** deck còn card nhưng bộ lọc đang bật không khớp card nào, **when** xem danh sách, **then** người dùng biết đó là kết quả của bộ lọc, khác với deck rỗng, và có lối hiện tất cả (A3).
- [ ] **Given** người dùng đang thêm card, **when** một card được lưu xong, **then** người dùng thêm được card kế tiếp ngay mà không phải mở lại (A4).
- [ ] **Given** người dùng di chuyển card sang deck khác cùng root, **when** xác nhận, **then** id, nội dung, study state, lịch sử, cờ và tag giữ nguyên, chỉ `deck_id` và `updated_at` đổi; deck nguồn rỗng thì về `unset`, deck đích `unset` thì thành `card` (A5).
- [ ] **Given** bộ lọc hoặc tìm kiếm đang áp và mới tải một phần kết quả, **when** người dùng chọn tất cả, **then** mọi id khớp bộ lọc và tìm kiếm hiện tại được chọn, không chỉ các hàng đã tải (A6).
- [ ] **Given** một hoặc nhiều card đã chọn, **when** bật hoặc bỏ cờ, **then** `is_flagged` đúng giá trị trên mọi card, và card đã đúng giá trị không bị ghi lại (A7).
- [ ] **Given** một tên tag gắn cho nhiều card, **when** gắn, **then** hệ thống dùng lại tag có cùng tên đã gập hoặc tạo tag mới, và gắn cho mọi card đã chọn; gỡ tag chỉ xoá liên kết, không xoá tag (A8).
- [ ] **Given** không ở chế độ chọn nhiều, **when** người dùng chọn một card, **then** chi tiết chỉ đọc của đúng card đó mở ra; khi đang chọn nhiều, cùng lựa chọn đó chỉ đổi trạng thái chọn (A9).
- [ ] **Given** mặt trước hoặc mặt sau rỗng, hoặc vượt giới hạn độ dài, **when** người dùng nhập, **then** người dùng được báo đúng trường sai và không lưu được (E1, E2).
- [ ] **Given** ghi card mới thất bại, **when** người dùng được báo lỗi, **then** nội dung đã nhập vẫn còn, có thể thử lại, và không có card nào được tạo mà thiếu study state (E3).
- [ ] **Given** deck đích không còn hợp lệ (mất, là root, chứa deck con, hoặc chính deck nguồn), **when** di chuyển chạy, **then** bị từ chối với lý do có kiểu và không ghi gì (E5).
- [ ] **Given** một card trong lô vi phạm luật (ví dụ đã đủ 10 tag), **when** thao tác hàng loạt chạy, **then** cả lô không ghi gì, danh sách và lựa chọn giữ nguyên, và người dùng biết lý do (E6, E7).

### UC-CARD-002 — Xem chi tiết một card và lịch sử học của nó
Status: ready · Code: [lib/features/card/domain/usecases/watch_card_detail_use_case.dart, lib/features/card/domain/usecases/load_card_history_page_use_case.dart] · Invokes: [FN-CARD-013, FN-CARD-014, FN-CARD-003]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Biết toàn bộ nội dung một card, trạng thái học hiện tại của nó, và nó đã được ôn ra
sao.
**Preconditions:** Deck đang mở là deck con loại `card`; card được chọn còn tồn tại.

#### Main flow

**Main flow:**
1. Người dùng chọn một card khi không ở chế độ chọn nhiều. Hệ thống thực hiện FN-CARD-013 và cho
   người dùng xem chi tiết **chỉ đọc** của đúng card đó, mà không bỏ danh sách đang xem.
2. Người dùng biết toàn bộ nội dung card: mặt trước, mặt sau, và các trường tuỳ chọn có giá trị.
3. Người dùng biết trạng thái học hiện tại: tag, cờ, trạng thái hiển thị, ngày tới hạn, lần trả
   lời gần nhất, số lượt đã trả lời, số lần quên, và các trường riêng của scheduler.
4. Hệ thống thực hiện FN-CARD-014 cho trang lịch sử đầu tiên; người dùng biết lịch sử, nhóm theo
   generation của scheduler.
5. Mỗi event cho biết thời điểm, chế độ học, loại lượt, hành động, lý do kết thúc và việc dùng
   gợi ý khi có, cùng thay đổi lịch trước → sau đã lưu.
6. Người dùng xin thêm lịch sử; hệ thống thực hiện FN-CARD-014 với con trỏ của trang trước và nối
   thêm, không lặp event nào.
7. Người dùng quay lại danh sách, **đúng như lúc rời đi** — bộ lọc, tìm kiếm, sắp xếp, phần đã tải
   và lựa chọn đều nguyên vẹn.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Sửa card:** người dùng chọn sửa một cách tường minh; hệ thống thực hiện FN-CARD-003 cho
  đúng card đó. Sửa nội dung không đụng tới trạng thái lịch hay lịch sử; quay lại thì chi tiết có
  nội dung mới và lịch sử không đổi.
- **A2 — Card chưa có lịch sử:** người dùng được giải thích là chưa có lịch sử, không phải lỗi; nội
  dung và trạng thái hiện tại vẫn đủ.
- **A3 — Lịch sử trải nhiều generation:** sau một lần Reset, các event cũ vẫn còn, dưới nhóm
  generation của chúng; generation hiện tại trên cùng.
- **A4 — Chọn khi đang ở chế độ chọn nhiều:** chỉ đổi trạng thái chọn; không mở chi tiết.
- **A5 — Đã hết lịch sử:** người dùng biết đã hết, thay vì được mời tải thêm vô ích.

**Error flows:**
- **E1 — Card không tồn tại khi mở:** deep link hoặc route cũ trỏ tới một id đã bị xoá → người dùng
  được báo card không còn và có lối quay lại danh sách; không lộ id hay chi tiết kỹ thuật.
- **E2 — Card bị xoá ở nơi khác khi đang xem:** như E1; không có mutation nào được thực hiện từ
  đây.
- **E3 — Đọc nội dung hoặc trạng thái thất bại:** người dùng được báo lỗi có kiểu và thử lại được;
  thử lại chạy lại đúng lần đọc đó.
- **E4 — Tải một trang lịch sử thất bại:** các event đã có **giữ nguyên**; người dùng thử lại được,
  và thử lại tiếp tục từ đúng con trỏ trước đó chứ không tải lại từ đầu.
- **E5 — Kết quả một trang tới muộn sau khi người dùng đã rời hoặc đã thử lại:** kết quả cũ bị bỏ
  qua; lịch sử MUST NOT bị nối hai lần cùng một tập event.

#### Acceptance criteria

- [ ] **Given** chọn một card khi không ở chế độ chọn nhiều, **when** chi tiết mở, **then** người dùng thấy toàn bộ mặt trước, mặt sau và chỉ các trường tuỳ chọn có giá trị; việc đọc không ghi gì.
- [ ] **Given** chi tiết đang mở, **when** tag, study state hoặc nội dung đổi, **then** thông tin hiện tại (tag, cờ, trạng thái, ngày tới hạn, số liệu học) cập nhật theo.
- [ ] **Given** một card có lịch sử, **when** chi tiết tải, **then** trang đầu là 50 event gần nhất, mới nhất trước, nhóm theo generation với generation hiện tại trên cùng, kể cả event của generation cũ sau một lần Reset (A3).
- [ ] **Given** một event lịch sử, **when** người dùng xem nó, **then** nó nêu thời điểm, chế độ học, loại lượt, hành động và đúng giá trị lịch trước và sau đã lưu trên hàng đó.
- [ ] **Given** đã tới cuối phần lịch sử đã tải, **when** người dùng xin thêm, **then** 50 event kế tiếp nối vào theo con trỏ keyset, không lặp và không sót, kể cả khi có câu trả lời mới ghi giữa lúc phân trang.
- [ ] **Given** người dùng chọn sửa trên chi tiết, **when** sửa xong, **then** đó là việc sửa đúng card đó, và sửa nội dung không đụng study state hay lịch sử (A1).
- [ ] **Given** một card chưa có lịch sử, **when** chi tiết mở, **then** người dùng được giải thích là chưa có lịch sử, không phải lỗi, và nội dung cùng trạng thái hiện tại vẫn đủ (A2).
- [ ] **Given** người dùng đang xem chi tiết mở từ danh sách card, **when** quay lại, **then** danh sách giữ nguyên bộ lọc, tìm kiếm, sắp xếp, phần đã tải và lựa chọn.
- [ ] **Given** đang ở chế độ chọn nhiều, **when** chọn một card, **then** card chỉ đổi trạng thái chọn, chi tiết không mở (A4).
- [ ] **Given** đã tải hết lịch sử, **when** tới cuối, **then** người dùng biết đã hết thay vì được mời tải thêm vô ích (A5).
- [ ] **Given** id card không còn tồn tại (deep link hoặc route cũ), **when** mở chi tiết, **then** người dùng được báo card không còn và có lối về danh sách, không lộ id hay chi tiết kỹ thuật (E1).
- [ ] **Given** chi tiết đang mở, **when** card bị xoá ở nơi khác, **then** người dùng được báo card không còn, và không có thao tác ghi nào từ đây (E2).
- [ ] **Given** đọc nội dung hoặc trạng thái thất bại, **when** lỗi xảy ra, **then** người dùng được báo lỗi kèm thử lại, không lộ nguyên nhân kỹ thuật, và thử lại chạy lại đúng lần đọc đó (E3).
- [ ] **Given** tải một trang lịch sử thất bại, **when** lỗi xảy ra, **then** các event đã có giữ nguyên, người dùng thử lại được, và thử lại tiếp tục từ đúng con trỏ trước đó (E4).
- [ ] **Given** một trang lịch sử đang tải, **when** người dùng rời đi hoặc xin thêm lần nữa trước khi nó về, **then** kết quả tới muộn bị bỏ qua và lịch sử không bao giờ nối cùng một tập event hai lần (E5).

## SRS

### UC-SRS-001 — Reset learning progress
Status: ready · Code: [lib/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart, lib/features/srs/domain/usecases/reset_learning_progress_use_case.dart] · Invokes: [FN-SRS-001, FN-SRS-002]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Học lại cả một cây deck từ đầu, thường để đổi chế độ ôn tập khi chế độ đã khoá.
**Preconditions:** Root deck tồn tại

#### Main flow

**Main flow:**
1. Người dùng muốn đặt lại tiến độ học của một root deck.
2. Hệ thống thực hiện FN-SRS-001 và cho người dùng biết rõ hai danh sách trước khi xác nhận: những
   gì **giữ nguyên** và những gì **mất** — mọi thẻ trở lại tập Học mới và đi lại chuỗi stage.
3. Người dùng có thể chọn **chế độ ôn tập mới** ngay trong bước này — đây là mục đích chính của
   thao tác.
4. Người dùng xác nhận.
5. Hệ thống thực hiện FN-SRS-002.
6. Người dùng quay về deck; toàn bộ card đã trở lại trạng thái Học mới và chưa thuộc tập Due;
   chế độ ôn tập mở khoá lại; lịch sử trả lời cũ vẫn còn.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Đặt lại mà không đổi chế độ:** hợp lệ. Dùng khi người dùng chỉ muốn học lại từ đầu.
- **A2 — Đặt lại trên deck chưa có lượt học:** vẫn được, và người dùng biết là không có gì để mất.
- **A3 — Người dùng không xác nhận:** không xảy ra gì.
- **A4 — Đặt lại trên deck con:** không có thao tác này. Đặt lại chỉ tồn tại ở root vì scheduler
  và generation thuộc root.

**Error flows:**
- **E1 — Thất bại giữa chừng:** transaction rollback. Root giữ nguyên generation cũ, scheduler cũ
  và toàn bộ state cũ. **Không** có trạng thái nửa vời với card thuộc hai generation.
- **E2 — Người dùng có phiên đang mở ở nơi khác:** phiên đó đã bị chuyển `invalidated` ở bước 5;
  lần đánh giá tiếp theo trong phiên đó bị từ chối.

#### Acceptance criteria

- [ ] **Given** một root đã khoá scheduler và đã học, **when** người dùng xác nhận đặt lại với một chế độ, **then** trong một transaction `generation` tăng đúng 1, `first_answered_at = NULL`, và mọi study state trong cây khởi tạo lại ở giá trị đầu của chế độ đó, cùng generation mới.
- [ ] **Given** một lần đặt lại vừa xong, **when** kiểm tra dữ liệu, **then** cây deck, card, tag và `content_type` không đổi.
- [ ] **Given** một lần đặt lại vừa xong, **when** kiểm tra `review_log`, **then** các dòng cũ còn nguyên và vẫn mang generation cũ.
- [ ] **Given** nhiều cây deck độc lập, **when** một cây được đặt lại, **then** các cây khác không đổi gì.
- [ ] **Given** đặt lại giữ nguyên chế độ đang chạy, **when** người dùng xác nhận, **then** chế độ giữ nguyên nhưng `generation` vẫn tăng và study state vẫn khởi tạo lại (A1).
- [ ] **Given** một root chưa từng học hoặc không có card, **when** người dùng được cho biết những gì sẽ mất, **then** người dùng biết là không có gì để mất, và vẫn đặt lại được (A2).
- [ ] **Given** hệ thống đang chờ xác nhận đặt lại, **when** người dùng không xác nhận, **then** không có gì thay đổi (A3).
- [ ] **Given** một deck con, **when** người dùng muốn đặt lại tiến độ học, **then** không có thao tác đó; chỉ root mới đặt lại được (A4).
- [ ] **Given** một ghi lỗi giữa transaction đặt lại, **when** hệ thống xử lý, **then** toàn bộ rollback: root giữ `generation`, chế độ, study state và trạng thái phiên cũ (E1).
- [ ] **Given** cây có một phiên `in_progress`, **when** đặt lại được thực hiện, **then** phiên đó thành `invalidated` với `end_reason = scheduler_reset`, lượt trả lời kế tiếp của nó bị từ chối, và các lượt đã ghi trước khi đặt lại vẫn giữ (E2).
- [ ] **Given** một root không tồn tại hoặc đang ở Trash, **when** yêu cầu đặt lại hoặc xem những gì sẽ mất, **then** thao tác bị từ chối và không ghi gì.

## Study

### UC-STUDY-001 — Ôn tập một deck — luồng chính
Status: ready · Code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/features/study/domain/usecases/open_learning_session_use_case.dart, lib/features/study/domain/usecases/open_review_session_use_case.dart, lib/features/study/domain/usecases/watch_study_session_use_case.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/domain/usecases/reveal_recall_answer_use_case.dart, lib/features/study/domain/usecases/save_recall_time_use_case.dart, lib/features/study/domain/usecases/show_fill_hint_use_case.dart, lib/features/study/domain/usecases/abandon_study_session_use_case.dart, lib/features/study/domain/usecases/resume_study_session_use_case.dart, lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart] · Invokes: [FN-STUDY-001, FN-STUDY-002, FN-STUDY-003, FN-STUDY-004, FN-STUDY-005, FN-STUDY-006, FN-STUDY-007, FN-STUDY-008, FN-STUDY-009, FN-STUDY-010, FN-STUDY-011]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Học thẻ mới hoặc ôn thẻ đến hạn của một deck, và để lịch ôn của từng thẻ được cập
nhật đúng. Chỉ hành động học tường minh của người dùng tạo phiên — con số đến hạn ở bất kỳ đâu
không tạo phiên.
**Preconditions:** Deck tồn tại và có ít nhất một thẻ thuộc một trong hai tập học mới và ôn tập.

Đây là luồng chạy hằng ngày và là vertical slice đầu tiên nên xây.

**Hai loại phiên, không phải một.** *Học mới* đưa thẻ chưa biết qua chuỗi stage và kết thúc bằng
việc khởi tạo lịch; *ôn tập* đưa thẻ đến hạn qua **một** cách hỏi do người dùng chọn và cập nhật
lịch. Chúng không bao giờ trộn thẻ.

#### Main flow

**Main flow:**
1. Người dùng muốn học một deck. Hệ thống thực hiện FN-STUDY-001: người dùng biết hai tập học
   mới và ôn tập, mỗi tập kèm số lượng, **không trộn**. Còn phiên `in_progress` của cùng ngày
   học thì người dùng có thêm lựa chọn tiếp tục phiên đó (FN-STUDY-010); chọn học mới hay ôn tập
   sẽ đóng nó lại.
2. Tập ôn tập rỗng ⇒ không ôn tập được, và người dùng biết khi nào thẻ gần nhất đến hạn. Không có
   thao tác nào ôn sớm hơn hạn.
3. **Chọn học mới** — hệ thống thực hiện FN-STUDY-002. Người dùng **không chọn** stage.
4. **Chọn ôn tập** — người dùng chọn một trong các mode thuật toán của deck cung cấp, mỗi mode với
   số thẻ của riêng nó; mode không đủ dữ liệu không chọn được, và người dùng biết vì sao. Chỉ có
   một mode thì không phải chọn. Hệ thống thực hiện FN-STUDY-003.
5. Hệ thống thực hiện FN-STUDY-004: người dùng làm từng lượt mà mode đang chạy đưa ra.
6. Người dùng trả lời một lượt; hệ thống thực hiện FN-STUDY-005. Với `recall`, người dùng có thể
   mở đáp án trước khi hết giờ (FN-STUDY-006), và thời gian còn lại được giữ khi app vào nền
   (FN-STUDY-007); với `fill`, người dùng có thể xin gợi ý (FN-STUDY-008).
7. Lượt kế tiếp được đưa ra, cho tới khi hết hàng đợi — hoặc, với phiên học mới, hết stage cuối.
8. Hết phiên: phiên `completed` và người dùng biết tổng kết của phiên.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Thẻ trả lời sai:** cách nó quay lại **tùy mode**, không tùy loại phiên. Với `self_assess`:
  quay lại trong cùng hàng đợi sau ít nhất 3 thẻ khác, trần 3 lượt. Với bốn mode chấm điểm: thẻ ở
  lại tập không đạt và quay lại ở **round sau**, không trần — xem A0c.
- **A0 — Hết hàng đợi của một stage (chỉ phiên học mới):** phiên chuyển sang stage kế trên **cùng
  tập thẻ**, với thứ tự xáo riêng. Hết stage cuối mới là hết phiên. Phiên ôn tập chỉ có một mode,
  nên hết hàng đợi là hết phiên.
- **A0c — Hết một round của stage chấm điểm:** tập thẻ không đạt rỗng thì stage hoàn tất; còn thẻ
  thì có round mới **chỉ từ tập đó**, với thứ tự xáo riêng. Thẻ từng sai trong round vẫn thuộc tập
  đó kể cả khi sau đó làm đúng. Không có trần số round.
- **A0b — Thẻ không đủ dữ liệu cho stage đang chạy:** bỏ qua **có ghi nhận** ở stage đó, không xoá
  khỏi deck, và vẫn xuất hiện ở các stage khác mà nó đủ dữ liệu — ví dụ thẻ không có `example` thì
  vắng ở `fill` nhưng có ở `guess`.
- **A2b — Thẻ chạm trần 3 lượt `relearning` ở `self_assess`:** thẻ rời hàng đợi dù lượt cuối vẫn
  là `forgotten`/`again`, và cờ của thẻ được bật. Trong phiên ôn tập, lịch đã được đặt ở lượt
  `scheduled` đầu nên thẻ vẫn đến hạn lại sớm. Trong phiên học mới, thẻ chưa có lịch và chưa
  `learned_at`, nên nó ở lại tập học mới — cờ là dấu cho lần sau. Cờ chỉ được bật, không bao giờ
  tự tắt.
- **A2 — Thẻ quay lại được đánh giá lần nữa:** lượt đó là `relearning`: ghi lịch sử và cập nhật
  `last_answered_at`, nhưng không đổi lịch. Đánh giá khác `forgotten`/`again` thì rời hàng đợi;
  lại `forgotten`/`again` thì quay lại lần nữa.
- **A3 — Rời giữa phiên:** hệ thống thực hiện FN-STUDY-009. Mọi đánh giá đã ghi **vẫn giữ**. Hàng
  đợi **được lưu**, nên xem A3b.
- **A3b — Mở lại app khi còn phiên `in_progress`:** cùng ngày học thì tiếp đúng hàng đợi đó
  (FN-STUDY-010) — đúng thẻ đang dở, đúng thứ tự, đúng số lượt đã dùng. Ngày học khác thì phiên đó
  đóng `interrupted` (FN-STUDY-011), và người dùng dựng phiên mới. App bị hệ điều hành thu hồi rơi
  vào đúng nhánh này, và nó khác `user_exit`: người dùng không hề bỏ cuộc.
- **A4 — Còn thẻ đến hạn ngoài giới hạn của phiên:** tổng kết cho người dùng biết còn bao nhiêu và
  cho bắt đầu phiên tiếp theo ngay.
- **A5 — Deck đang ôn dở vào Trash:** phiên kết thúc với `content_deleted`; người dùng biết phiên đã
  kết thúc vì nội dung vào Trash (quyết định của chủ dự án 2026-09-28).

**Error flows:**
- **E1 — Không còn thẻ nào đến hạn lúc bắt đầu:** một trạng thái bình thường, kèm thời điểm thẻ
  gần nhất đến hạn. **Không** phải lỗi, và **không** tạo phiên.
- **E2 — Ghi đánh giá thất bại nhưng còn tiếp tục được:** người dùng được báo ngay, và **không**
  sang thẻ tiếp theo. Người dùng thử lại đúng câu trả lời đó. Chuyển tiếp khi chưa ghi được là âm
  thầm mất tiến độ.
- **E3 — Lỗi ghi không thể tiếp tục:** phiên `failed`, `end_reason = persistence_error`. Các lượt
  đã ghi thành công **vẫn giữ**. Người dùng được báo lỗi và rời phiên.
- **E4 — Generation của phiên đã lỗi thời** (root bị đặt lại ở nơi khác trong lúc phiên đang mở):
  **từ chối ghi**, phiên `invalidated`, `end_reason = stale_generation`. Người dùng biết phiên đã hết
  hiệu lực vì tiến độ học vừa được đặt lại, và rời phiên. **Không** ghi phần nào của đánh giá đó.
- **E5 — Đọc phiên thất bại:** người dùng được báo lỗi và thử lại được.

#### Acceptance criteria

- [ ] **Given** một deck có cả thẻ `learned_at IS NULL` và thẻ đến hạn, **when** người dùng muốn học deck đó, **then** hệ thống đếm hai tập tách biệt, không thẻ nào thuộc cả hai.
- [ ] **Given** một root có nhiều thẻ chưa học hơn `card_limit`, **when** người dùng chọn học mới, **then** phiên `learning` lấy đúng `card_limit` thẻ theo `new_card_order` đang hiệu lực (`created` lấy thẻ cũ nhất, `random` lấy một tập con) và giữ số này cho phiên dù cấu hình đổi ngay sau đó.
- [ ] **Given** một phiên `learning` vừa mở, **when** hết hàng đợi của một stage, **then** phiên chuyển sang stage kế (`eight_box`: `browse → match → guess → recall → fill`; `sm2`: `browse → self_assess`) trên cùng tập thẻ với thứ tự xáo riêng, và hết stage cuối mới hết phiên (A0).
- [ ] **Given** một root có thẻ đến hạn, **when** người dùng chọn ôn tập, **then** mỗi mode có số thẻ của riêng nó, `fill` chỉ tính thẻ có `example`, và mode không đủ dữ liệu không chọn được kèm lý do.
- [ ] **Given** một phiên `reviewing` đã mở, **when** hệ thống dựng hàng đợi, **then** các thẻ đến hạn được lấy theo `due_at` tăng dần, tối đa `card_limit`.
- [ ] **Given** một lượt trả lời của mode khác mode đang chạy, hoặc mang action mà thuật toán không có, **when** hệ thống nhận nó, **then** lượt bị từ chối và không ghi gì.
- [ ] **Given** một thẻ học mới đi hết stage cuối mà nó tham gia, **when** lượt đó được ghi, **then** thẻ được đặt `learned_at` và khởi tạo lịch ở mức đầu; nếu đây là thẻ đầu tiên của root hoàn tất chuỗi học mới ở generation hiện tại thì `first_answered_at` cũng được đặt.
- [ ] **Given** một thẻ được đánh giá khác `forgotten`/`again`, **when** lượt được ghi, **then** thẻ rời hàng đợi; khi hàng đợi hết, phiên thành `completed` với `end_reason = NULL`.
- [ ] **Given** một thẻ bị đánh giá `forgotten`/`again` ở `self_assess`, **when** hàng đợi dựng lại, **then** thẻ quay lại trong cùng hàng đợi sau ít nhất 3 thẻ khác, hoặc ở cuối hàng đợi khi còn ít hơn 3 thẻ khác (A1).
- [ ] **Given** một thẻ sai trong một round của stage chấm điểm, **when** round kết thúc, **then** round mới chỉ gồm các thẻ không đạt với thứ tự xáo riêng, và stage hoàn tất khi tập không đạt rỗng (A0c).
- [ ] **Given** một phiên `reviewing` `eight_box` có một thẻ sai ở lượt đầu rồi đúng ở round sau, **when** hai lượt được ghi, **then** lượt đầu có `kind = scheduled` và đổi lịch (về box 1), lượt sau có `kind = relearning`, được ghi lịch sử nhưng không đổi lịch (A2).
- [ ] **Given** một thẻ thiếu dữ liệu cho stage đang chạy (ví dụ không có `example` ở `fill`), **when** stage đó chạy, **then** thẻ bị bỏ qua có ghi nhận, không bị xoá khỏi deck, và vẫn có ở các stage khác mà nó đủ dữ liệu (A0b).
- [ ] **Given** một thẻ đã quay lại 3 lượt `relearning` ở `self_assess`, **when** lượt thứ ba vẫn là `forgotten`/`again`, **then** thẻ rời hàng đợi, cờ được bật và không bao giờ tự tắt (A2b).
- [ ] **Given** người dùng rời giữa phiên, **when** rời, **then** phiên thành `abandoned` với `end_reason = user_exit`, và mọi lượt đã ghi vẫn giữ (A3).
- [ ] **Given** còn một phiên `in_progress`, **when** người dùng mở lại app cùng ngày học, **then** tiếp tục phiên phục hồi đúng thẻ, thứ tự và số lượt đã dùng; mở lại ở ngày học khác thì phiên cũ thành `abandoned` với `end_reason = interrupted` (A3b).
- [ ] **Given** deck đang ôn dở bị chuyển vào Trash, **when** việc xoá xảy ra, **then** phiên kết thúc với `end_reason = content_deleted`, và tiếp tục phiên đó bị từ chối (A5).
- [ ] **Given** deck đang ôn dở bị chuyển vào Trash, **when** phiên nhận việc xoá, **then** người dùng biết phiên đã kết thúc vì nội dung vào Trash (A5).
- [ ] **Given** tập ôn tập rỗng, **when** người dùng muốn học deck, **then** không ôn tập được, người dùng biết thời điểm thẻ gần nhất đến hạn như một trạng thái bình thường, và không có phiên nào được tạo (E1).
- [ ] **Given** ghi một đánh giá gặp database bận, **when** người dùng thử lại đúng câu trả lời đó, **then** lượt được ghi đúng một lần, không sang thẻ trước khi ghi được, và phiên vẫn `in_progress` (E2).
- [ ] **Given** ghi một đánh giá gặp lỗi không thể tiếp tục, **when** hệ thống xử lý, **then** phiên thành `failed` với `end_reason = persistence_error`, và các lượt đã ghi trước đó vẫn giữ (E3).
- [ ] **Given** root của phiên vừa bị đặt lại ở nơi khác, **when** người dùng trả lời hoặc tiếp tục phiên, **then** hệ thống từ chối ghi, phiên thành `invalidated` với `end_reason = stale_generation`, và không phần nào của lượt đó được ghi (E4).
- [ ] **Given** phiên không đọc được, **when** người dùng mở phiên, **then** người dùng được báo lỗi, và thử lại thì đọc lại (E5).
- [ ] **Given** một phiên ôn chạm giới hạn thẻ trong khi cây deck còn thẻ đến hạn, **when** tổng kết đến, **then** người dùng biết số thẻ còn đến hạn và có thể mở phiên tiếp theo; dưới giới hạn thì không nêu số này (A4).

### UC-STUDY-002 — Mở tab Study và chọn việc để học
Status: ready · Code: [lib/features/study/domain/usecases/watch_study_home_use_case.dart] · Invokes: [FN-STUDY-012, FN-STUDY-010, FN-STUDY-001]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Biết ở đâu có việc để học và bắt đầu từ đó, hoặc học tiếp phiên đang dở.
**Preconditions:** Không có

#### Main flow

**Main flow:**
1. Hệ thống thực hiện FN-STUDY-012: **một snapshot** gồm phiên có thể học tiếp và toàn bộ root
   deck kèm khối lượng việc. Xem không ghi gì.
2. Nếu có đúng một phiên hợp lệ đang mở, người dùng biết trước hết nó là phiên của deck nào, loại
   gì, đang ở chặng nào.
3. Người dùng biết mọi root deck với tên và ba con số Overdue / Due today / New, theo thứ tự giảm
   dần của ba con số đó, hoà thì theo tên.
4. Học tiếp mở đúng phiên đó và đúng lượt đã lưu (FN-STUDY-010), không tạo phiên thứ hai. Chọn học
   một deck đưa người dùng tới lối vào học của deck đó (FN-STUDY-001), nơi có lựa chọn giữa học mới
   và ôn tập.
5. Kết thúc, bỏ dở hay mất hiệu lực một phiên rồi quay lại: danh sách tự cập nhật, không giữ con
   số cũ.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Không có phiên nào đang mở:** không có gì để học tiếp.
- **A2 — Phiên của ngày học cũ, generation đã đổi, deck hoặc thẻ đã bị xoá:** không được đưa ra để
  học tiếp. Việc đóng phiên cũ xảy ra khi người dùng thực sự vào học, không phải khi xem tab.
- **A3 — Mọi deck đều không còn gì đến hạn:** danh sách vẫn có, và người dùng biết hiện chưa có thẻ
  nào tới hạn; deck vẫn mở được để học trước.
- **A4 — Thư viện chưa có deck nào:** người dùng được đưa tới thư viện starter, hoặc về Library.
- **A5 — Có deck nhưng chưa có card nào:** người dùng được đưa về Library để thêm thẻ — không phải
  tới thư viện starter, và không có con số Due bịa ra.

**Error flows:**
- **E1 — Đọc thất bại:** người dùng được báo lỗi, không kèm chi tiết kỹ thuật, và thử lại được;
  không có gì bị thay đổi, vì xem tab không ghi gì.

#### Acceptance criteria

- [ ] **Given** tab Study được mở, **when** hệ thống đọc dữ liệu, **then** phiên có thể tiếp tục và khối lượng việc của các root deck đến từ một snapshot, và việc đọc không ghi gì, kể cả khi còn phiên của ngày trước đang mở.
- [ ] **Given** đúng một phiên hợp lệ đang mở, **when** người dùng xem tab, **then** người dùng biết đúng tên deck, `kind` và mode lấy từ hàng session, kể cả khi phiên mở trên deck con.
- [ ] **Given** nhiều root deck có khối lượng việc khác nhau, **when** người dùng xem danh sách, **then** thứ tự giảm dần theo Overdue, rồi Due today, rồi New (không theo tổng), hoà thì theo tên đã gập rồi `id`.
- [ ] **Given** có một phiên để học tiếp, **when** người dùng học tiếp, **then** đúng phiên đó được mở lại tại lượt đã lưu và không có phiên thứ hai; nếu phiên vừa hết hạn thì bị từ chối và tab sẵn sàng lại.
- [ ] **Given** không có phiên nào đang mở, hoặc phiên đang mở đã kết thúc, thuộc ngày học cũ, hết hàng đợi hay thuộc generation cũ, **when** người dùng xem tab, **then** không có phiên nào để học tiếp (A1, A2).
- [ ] **Given** mọi deck đều không còn gì đến hạn, **when** người dùng xem tab, **then** người dùng biết mình đã bắt kịp, và các deck vẫn mở được để học trước (A3).
- [ ] **Given** thư viện có deck nhưng chưa deck nào có card, **when** người dùng xem tab, **then** người dùng được đưa về Library để thêm thẻ, không có con số nào (A5).
- [ ] **Given** việc đọc thất bại, **when** người dùng xem tab, **then** người dùng được báo lỗi, và thử lại thì đọc lại (E1).
- [ ] **Given** thư viện chưa có root deck nào, **when** người dùng xem tab, **then** người dùng được đưa tới thư viện starter, hoặc về Library (A4).

### UC-STUDY-003 — Chọn chiều hỏi cho một phiên self-assess
Status: ready · Code: [lib/features/study/domain/usecases/open_review_session_use_case.dart, lib/features/study/domain/usecases/watch_study_entry_use_case.dart] · Invokes: [FN-STUDY-001, FN-STUDY-003, FN-STUDY-004, FN-STUDY-010]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Ôn một deck `sm2` theo chiều hỏi mình muốn: hỏi thuật ngữ, hỏi nghĩa, hay trộn.
**Preconditions:** Root deck của deck đang mở dùng scheduler `sm2`, có ít nhất một thẻ đến hạn, và
mode ôn duy nhất thuật toán này cung cấp là `self_assess`.

#### Main flow

**Main flow:**
1. Người dùng chọn ôn tập (FN-STUDY-001 cho biết mode `self_assess` nhận chiều). Vì `sm2` chỉ có
   một mode, người dùng không phải chọn mode mà chọn **chiều hỏi**.
2. Người dùng biết ba chiều — hỏi thuật ngữ trước (khuyến nghị), hỏi nghĩa trước, trộn — mỗi chiều
   là bài tập gì, và rằng chiều không đổi được sau khi phiên bắt đầu.
3. Người dùng chọn một chiều. Chọn chiều chưa mở phiên: chiều bị khoá suốt phiên, nên một lựa chọn
   nhầm không được phép tiêu mất một phiên.
4. Người dùng bắt đầu ôn. Dù yêu cầu bắt đầu đến hai lần, chỉ một phiên được tạo.
5. Hệ thống thực hiện FN-STUDY-003 với chiều đã chọn.
6. Hệ thống thực hiện FN-STUDY-004: mỗi thẻ hỏi theo chiều của dòng nó, đáp án sau khi lật; tập
   action vẫn là bốn action của `sm2` và lịch chạy như thường.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Người dùng thôi chọn chiều:** chưa có gì được ghi, nên không có phiên nào để dọn.
- **A2 — Deck chạy `eight_box`:** không có chọn chiều; người dùng chọn mode, và không mode nào của
  nó nhận chiều.
- **A3 — Còn phiên bỏ dở:** người dùng được hỏi tiếp tục, học mới hay ôn tập trước. Tiếp tục
  (FN-STUDY-010) dùng chiều đã lưu và **không** hỏi lại; ôn tập kết thúc phiên cũ rồi đi vào bước 1.
- **A4 — Phiên trộn đang chạy:** hai thẻ liên tiếp có thể hỏi hai chiều khác nhau. Đó là đúng bài
  tập người dùng chọn; chiều của mỗi thẻ đã cố định từ bước 5 và không đổi khi thẻ quay lại.

**Error flows:**
- **E1 — Deck đổi scheduler hoặc bị đặt lại trong lúc người dùng đang chọn:** hệ thống đọc lại trước
  khi mở phiên; nếu `self_assess` không còn được cung cấp thì phiên bị từ chối như một thay đổi giữa
  chừng, không ghi gì, và người dùng biết self-check không còn được cung cấp cho deck này (quyết định
  của chủ dự án 2026-09-28).
- **E2 — Không còn thẻ đến hạn lúc bắt đầu:** phiên bị từ chối và không ghi gì; người dùng được báo
  như E1.
- **E3 — Yêu cầu thiếu chiều:** không thể tạo từ luồng này; hệ thống vẫn từ chối như một lỗi
  validation và không ghi phiên.

#### Acceptance criteria

- [ ] **Given** một root dùng `sm2` có thẻ đến hạn, **when** người dùng chọn ôn tập, **then** người dùng không phải chọn mode mà chọn chiều hỏi, với hỏi thuật ngữ trước được chọn sẵn.
- [ ] **Given** người dùng đang chọn chiều, **when** người dùng chọn hỏi nghĩa trước rồi bắt đầu, **then** phiên mở với đúng chiều đó, lưu ở `study_session.direction`.
- [ ] **Given** phiên mở với hỏi thuật ngữ trước hoặc hỏi nghĩa trước, **when** hệ thống dựng hàng đợi, **then** mọi dòng có cùng chiều đó; với trộn, mỗi dòng nhận một trong hai chiều, chia gần đều một lần lúc mở phiên.
- [ ] **Given** một thẻ hỏi theo hỏi nghĩa trước, **when** thẻ được đưa ra, **then** đề là mặt nghĩa, mặt thuật ngữ và ví dụ chỉ có sau khi lật, và vẫn là 4 action của `sm2` với lịch chạy như thường.
- [ ] **Given** yêu cầu bắt đầu đang mở phiên, **when** người dùng yêu cầu lần nữa, **then** chỉ một phiên được tạo.
- [ ] **Given** người dùng đang chọn chiều, **when** người dùng thôi mà không bắt đầu, **then** không có gì được ghi (A1).
- [ ] **Given** deck chạy `eight_box`, **when** người dùng chọn ôn tập, **then** không có chọn chiều, chỉ có chọn mode (A2).
- [ ] **Given** còn một phiên `self_assess` bỏ dở, **when** người dùng tiếp tục, **then** phiên tiếp tục với chiều đã lưu ở `study_session.direction` và không hỏi lại chiều (A3).
- [ ] **Given** một phiên trộn đang chạy, **when** một thẻ quay lại hàng đợi, **then** chiều của thẻ vẫn là chiều đã gán lúc mở phiên (A4).
- [ ] **Given** không còn thẻ nào đến hạn lúc bắt đầu, **when** người dùng bắt đầu, **then** phiên bị từ chối, người dùng được báo, và không ghi gì (E2).
- [ ] **Given** yêu cầu mở phiên `self_assess` không kèm chiều, hoặc kèm chiều cho một mode không dùng chiều, **when** hệ thống xử lý, **then** yêu cầu bị từ chối và không ghi gì (E3).
- [ ] **Given** người dùng đang chọn chiều và scheduler của root đổi sang `eight_box`, **when** người dùng bắt đầu, **then** phiên bị từ chối với `modeNotOffered`, không ghi gì, và người dùng biết self-check không còn được cung cấp (E1).

## Settings

### UC-SETTINGS-001 — Đặt tuỳ chọn ứng dụng
Status: ready · Code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/usecases/reset_app_settings_use_case.dart, lib/features/settings/domain/usecases/watch_study_options_use_case.dart, lib/features/settings/domain/usecases/save_root_study_options_use_case.dart, lib/features/settings/domain/usecases/use_app_defaults_use_case.dart, lib/app/startup_settings.dart] · Invokes: [FN-SETTINGS-001, FN-SETTINGS-002, FN-SETTINGS-003, FN-SETTINGS-004, FN-SETTINGS-005, FN-SETTINGS-006, FN-SETTINGS-007, FN-SETTINGS-008]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Đặt cách app học và trình bày — trần thẻ mỗi phiên, thứ tự thẻ mới, theme, ngôn ngữ
— một lần cho cả app, và cho riêng một cây deck khi cần.
**Preconditions:** Không có. Chỉ có một hồ sơ cục bộ, và tuỳ chọn ứng dụng luôn tồn tại.

#### Main flow

**Main flow:**
1. Người dùng muốn xem tuỳ chọn. Hệ thống thực hiện FN-SETTINGS-001: người dùng biết giá trị
   **đang có hiệu lực** của mặc định học, theme và ngôn ngữ — không phải giá trị giả định.
2. Người dùng đổi trần thẻ mỗi phiên và/hoặc thứ tự thẻ mới. Không có bước lưu riêng: mỗi thay đổi
   đã dừng là một lần lưu (FN-SETTINGS-002), và mọi nơi đang dùng giá trị thấy giá trị mới.
3. Người dùng biết mặc định mới áp cho **phiên mở sau đó**; phiên đang chạy giữ nguyên trần đã
   chốt.
4. Người dùng chọn theme `System`, `Light` hoặc `Dark` (FN-SETTINGS-003). Lựa chọn là một lần lưu
   riêng, và giao diện đổi ngay trong phiên chạy — không khởi động lại, không mất chỗ người dùng
   đang đứng.
5. Người dùng chọn ngôn ngữ `System`, `English` hoặc `Tiếng Việt` (FN-SETTINGS-004), cùng cách và
   cùng ràng buộc như theme.
6. Rời đi rồi quay lại, hoặc khởi động lại app: mọi lựa chọn tường minh vẫn còn.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Một cây deck có tuỳ chọn riêng:** cây đó không đổi gì khi mặc định toàn app đổi. Người
  dùng biết tuỳ chọn đang áp cho một deck và chúng đến từ đâu (FN-SETTINGS-006), có thể đặt tuỳ
  chọn riêng cho root của nó (FN-SETTINGS-007), và có thể cho cây dùng lại mặc định toàn app
  (FN-SETTINGS-008). Tiến độ học, chế độ ôn tập và lịch sử không bị đụng. Cây không có tuỳ chọn
  riêng thì không có gì để bỏ.
- **A2 — `System` khi hệ điều hành đổi:** người dùng đổi chế độ tối hoặc ngôn ngữ của hệ điều hành
  trong lúc app đang chạy. Đang để `System` thì app đổi theo ngay; đang để giá trị tường minh thì
  app không đổi.
- **A3 — Về mặc định:** người dùng muốn đưa mọi tuỳ chọn về mặc định. Người dùng xác nhận trước,
  biết rằng việc này **không** đụng tiến độ học, rồi hệ thống thực hiện FN-SETTINGS-005: sáu giá
  trị — bốn tuỳ chọn học và trình bày, cùng công tắc và giờ của nhắc học hằng ngày — về mặc định
  cùng lúc.
- **A4 — Yêu cầu lưu lần thứ hai khi lần đầu chưa xong:** lần sau bị bỏ qua; một thay đổi không bao
  giờ thành hai lần ghi.

**Error flows:**
- **E1 — Trần thẻ không hợp lệ:** không phải số, nhỏ hơn tối thiểu hoặc lớn hơn tối đa — người
  dùng biết lý do ngay, không gì được ghi, và giá trị đang nhập giữ nguyên.
- **E2 — Ghi thất bại:** người dùng được báo lỗi, không kèm chi tiết kỹ thuật, và thử lại được.
  Giá trị đang nhập giữ nguyên; các tuỳ chọn khác vẫn là giá trị đã lưu.
- **E3 — Đọc thất bại:** người dùng được báo lỗi và thử lại được; không tuỳ chọn nào hiện giá trị
  bịa ra.
- **E4 — Cho cây dùng lại mặc định thất bại:** tuỳ chọn riêng giữ nguyên, người dùng biết lý do,
  và không có thay đổi một phần.

#### Acceptance criteria

- [ ] **Given** app vừa cài hoặc người dùng mở tuỳ chọn, **when** đọc xong tuỳ chọn ứng dụng, **then** người dùng biết đúng giá trị đang có hiệu lực của mặc định học, theme và ngôn ngữ, không phải giá trị giả định.
- [ ] **Given** người dùng đổi trần thẻ mỗi phiên nhiều lần liên tiếp, **when** thao tác dừng, **then** hệ thống ghi đúng một transaction với giá trị cuối cùng.
- [ ] **Given** người dùng đổi thứ tự thẻ mới hoặc nhập một trần thẻ hợp lệ (1–200), **when** thao tác dừng, **then** hệ thống ghi ngay không cần bước lưu riêng, và mọi nơi đang dùng giá trị thấy giá trị mới.
- [ ] **Given** người dùng chọn theme `System`, `Light` hoặc `Dark`, **when** chọn, **then** hệ thống ghi ngay trong một transaction riêng và giao diện đổi trong cùng phiên chạy, không mất chỗ người dùng đang đứng.
- [ ] **Given** người dùng chọn ngôn ngữ `System`, `English` hoặc `Tiếng Việt`, **when** chọn, **then** hệ thống ghi ngay và áp dụng ngay trong cùng phiên, cùng cách như theme, và giá trị còn sau khi khởi động lại app.
- [ ] **Given** một root deck đang có tuỳ chọn riêng, **when** mặc định học toàn app đổi, **then** deck đó không đổi số nào; root không có tuỳ chọn riêng đọc mặc định mới ở lần đọc kế tiếp (A1).
- [ ] **Given** một root deck đang có tuỳ chọn riêng, **when** người dùng cho cây dùng lại mặc định toàn app, **then** hệ thống xoá tuỳ chọn riêng của root trong một transaction, cây quay về đọc mặc định toàn app, và tiến độ học cùng lịch sử không đổi (A1).
- [ ] **Given** một deck không phải root, **when** ghi hoặc xoá tuỳ chọn riêng qua đường của root, **then** hệ thống từ chối và không ghi gì (A1).
- [ ] **Given** app đang để `System` cho theme hoặc ngôn ngữ, **when** chế độ tối hoặc ngôn ngữ của hệ điều hành đổi trong lúc app chạy, **then** app đổi theo ngay; nếu đang để giá trị tường minh thì app không đổi (A2).
- [ ] **Given** người dùng muốn về mặc định và xác nhận, **when** transaction chạy xong, **then** cả sáu giá trị của tuỳ chọn ứng dụng về mặc định trong một lần ghi, và tuỳ chọn riêng của mọi root không đổi (A3).
- [ ] **Given** một lần ghi của một nhóm (theme, ngôn ngữ hoặc mặc định học) đang chạy, **when** người dùng yêu cầu lại cùng thay đổi đó, **then** lần sau bị bỏ qua, không có hai transaction (A4).
- [ ] **Given** người dùng nhập một trần thẻ không phải số, nhỏ hơn 1 hoặc lớn hơn 200, **when** dừng nhập, **then** người dùng biết lý do ngay, không gì được ghi, và giá trị đang nhập giữ nguyên (E1).
- [ ] **Given** một lần ghi tuỳ chọn thất bại, **when** người dùng được báo, **then** thông báo không lộ SQL hay đường dẫn file, các tuỳ chọn khác vẫn là giá trị đã lưu, và thử lại ghi lại đúng thay đổi đó (E2).
- [ ] **Given** việc đọc tuỳ chọn ứng dụng lỗi, **when** người dùng mở tuỳ chọn, **then** người dùng được báo lỗi và thử lại được, và không tuỳ chọn nào hiện giá trị bịa ra (E3).
- [ ] **Given** việc cho cây dùng lại mặc định thất bại khi ghi, **when** người dùng được báo, **then** tuỳ chọn riêng của root giữ nguyên như trước, người dùng biết lý do, và không có thay đổi một phần (E4).

## Reminders

### UC-REMINDER-001 — Bật nhắc học hằng ngày
Status: ready · Code: [lib/features/reminders/domain/usecases/watch_reminder_use_case.dart, lib/features/reminders/domain/usecases/read_reminder_preview_use_case.dart, lib/features/reminders/domain/usecases/enable_reminder_use_case.dart, lib/features/reminders/domain/usecases/deliver_reminder_use_case.dart, lib/features/reminders/domain/usecases/change_reminder_time_use_case.dart, lib/features/reminders/domain/usecases/disable_reminder_use_case.dart, lib/features/reminders/domain/usecases/reconcile_reminder_use_case.dart, lib/app/app.dart] · Invokes: [FN-REMINDER-001, FN-REMINDER-002, FN-REMINDER-003, FN-REMINDER-004, FN-REMINDER-005, FN-REMINDER-006, FN-REMINDER-007]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Được nhắc mỗi ngày một lần, vào giờ mình chọn, khi còn thẻ đến hạn — và không bị
làm phiền khi không có gì để ôn.
**Preconditions:** Không có. Nhắc học mặc định tắt và không phụ thuộc dữ liệu nào; người dùng đặt
được nó cả khi thư viện rỗng.

#### Main flow

**Main flow:**
1. Người dùng muốn đặt nhắc học. Hệ thống thực hiện FN-REMINDER-001: người dùng biết nhắc học đang
   **tắt**, giờ gợi ý 20:00, rằng nhắc chỉ đến khi còn thẻ đến hạn, và rằng notification có thể nêu
   tên deck cùng số thẻ trên màn khoá. Người dùng biết notification sẽ nói gì nếu nó đến ngay lúc
   này (FN-REMINDER-002).
2. Người dùng bật nhắc học. Hệ thống thực hiện FN-REMINDER-003, và **chỉ lúc này** mới xin quyền
   notification của hệ điều hành.
3. Người dùng cấp quyền. Nhắc học bật ở giờ đã chọn, và người dùng biết nó đã bật cùng giờ đó.
4. Đến giờ, hệ thống thực hiện FN-REMINDER-004: còn thẻ đến hạn thì người dùng nhận đúng một
   notification tóm tắt, rồi lượt của ngày kế tiếp được đặt.
5. Người dùng mở notification. Hệ thống thực hiện FN-REMINDER-005: người dùng tới tab Study, và
   không phiên nào được mở thay cho họ.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Đổi giờ nhắc:** người dùng chọn giờ mới (FN-REMINDER-006); giờ mới được lưu và lịch đặt lại
  trong cùng một thao tác. Thôi chọn thì không đổi gì.
- **A2 — Tắt nhắc:** hệ thống thực hiện FN-REMINDER-007; lượt đang chờ bị huỷ. Không xin quyền,
  không hỏi xác nhận.
- **A3 — Đến giờ nhưng không còn thẻ đến hạn:** không có gì đến tay người dùng, và lượt ngày kế tiếp
  vẫn được đặt.
- **A4 — Chỉ còn thẻ chưa học:** như A3 — thẻ mới không làm phát notification.
- **A5 — Đổi múi giờ hoặc mở lại app:** lịch nhắc được đưa về khớp với giá trị đã lưu lúc khởi động;
  dù việc này chạy bao nhiêu lần, vẫn chỉ có đúng một lượt chờ.
- **A6 — Bỏ qua notification:** không gì thay đổi; lượt nhắc hôm sau giữ nguyên.

**Error flows:**
- **E1 — Từ chối quyền:** nhắc học giữ nguyên **tắt** và không có lượt nào được đặt. Người dùng biết
  lý do, biết cách bật lại quyền ở cài đặt hệ thống, và thử lại được. Hệ thống không tự xin lại.
- **E2 — Nền tảng không hỗ trợ:** người dùng biết nhắc học chưa có trên nền tảng này và không bật
  được; không có trạng thái bật giả.
- **E3 — Đặt lịch thất bại:** nhắc học **không** ở trạng thái bật; người dùng biết lý do, không kèm
  chi tiết kỹ thuật, và thử lại được.
- **E4 — Lưu thất bại:** không có lượt nào được đặt cho thay đổi đó; người dùng thấy lại giá trị
  đang lưu, biết lý do và thử lại được.
- **E5 — Đọc khối lượng việc thất bại lúc đến giờ:** không có notification đoán mò nào; lượt ngày kế
  tiếp vẫn được đặt.
- **E6 — Huỷ lịch thất bại khi tắt:** nhắc học **đã** tắt — chỉ lượt đang chờ là chưa huỷ được.
  Người dùng biết có thể còn một lần nhắc cũ và thử lại được; đây không phải "chưa bật được gì".
  Lần nhắc cũ đó vô hại: lúc đến giờ, nó đọc lại tuỳ chọn và không hiện gì.
- **E7 — Đọc tuỳ chọn thất bại:** người dùng được báo một lần **đọc** thất bại — không phải một thay
  đổi chưa lưu được, vì người dùng chưa đổi gì — và thử lại được; không giá trị nào được bịa ra.

#### Acceptance criteria

- [ ] **Given** nhắc học đang tắt, **when** người dùng bật lúc 20:00 và cấp quyền, **then** quyền được xin đúng lúc này, đúng một lượt nhắc được đặt cho lần 20:00 địa phương kế tiếp, rồi nhắc học mới được lưu bật cùng giờ.
- [ ] **Given** người dùng từ chối quyền, **when** bật, **then** nhắc học vẫn tắt, không có lượt nào chờ, và hệ thống không tự xin lại (E1).
- [ ] **Given** nền tảng không hỗ trợ nhắc học, **when** người dùng muốn đặt hoặc bật nhắc học, **then** người dùng biết nó không có trên nền tảng này, và không có gì được xin, lưu hay đặt lịch (E2).
- [ ] **Given** nền tảng từ chối đặt lịch, **when** bật hoặc đổi giờ, **then** nhắc học giữ nguyên giá trị cũ và không có gì được ghi (E3).
- [ ] **Given** lưu thất bại, **when** bật, **then** lượt vừa đặt bị gỡ và người dùng được báo lỗi (E4).
- [ ] **Given** nhắc học đang bật và có thẻ đến hạn, **when** đến giờ, **then** khối lượng việc được đọc lại, đúng một notification nêu tên root deck cấp bách nhất, số thẻ đến hạn của deck đó và số deck khác còn thẻ đến hạn, lần gửi được ghi, và lượt của ngày mai được đặt.
- [ ] **Given** không còn thẻ đến hạn, hoặc chỉ còn thẻ chưa học, **when** đến giờ, **then** không có gì hiện và lượt kế tiếp vẫn được đặt (A3, A4).
- [ ] **Given** đọc khối lượng việc thất bại lúc đến giờ, **when** đến giờ, **then** không có gì hiện và lượt kế tiếp vẫn được đặt (E5).
- [ ] **Given** một ngày địa phương đã có notification, **when** lượt nhắc đến giờ lần nữa trong ngày đó, **then** không có thêm notification.
- [ ] **Given** nhắc học đang bật, **when** người dùng đổi giờ, **then** giờ mới được đặt lịch rồi mới lưu, trong cùng một thao tác (A1).
- [ ] **Given** người dùng tắt nhắc học, **when** huỷ lịch thất bại, **then** nhắc học đã tắt, người dùng biết chỉ lượt chờ còn sót, và thử lại chỉ huỷ, không ghi gì (A2, E6).
- [ ] **Given** app mở lại nhiều lần trong ngày khi đang bật, **when** lịch được đưa về khớp, **then** vẫn đúng một lượt chờ; khi đang tắt, lượt còn sót bị huỷ (A5).
- [ ] **Given** đọc tuỳ chọn thất bại, **when** người dùng muốn đặt nhắc học, **then** người dùng được báo lỗi đọc, và không giá trị nào được bịa ra (E7).
- [ ] **Given** notification đang hiện, **when** người dùng mở nó, **then** người dùng tới tab Study, không phiên nào được mở và không gì được ghi; bỏ qua notification thì không gì thay đổi (bước 5, A6 — kiểm trên thiết bị).

## Progress

### UC-PROGRESS-001 — Xem tiến độ học
Status: ready · Code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart] · Invokes: [FN-PROGRESS-001]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Biết mình đã học đều đặn tới đâu: hôm nay học bao nhiêu, bảy ngày qua ra sao, và chuỗi
ngày học liên tiếp đang là bao nhiêu.
**Preconditions:** Không có. Chưa từng học lượt nào là một trạng thái hợp lệ, không phải lỗi.

#### Main flow

**Main flow:**
1. Người dùng muốn xem tiến độ. Hệ thống thực hiện FN-PROGRESS-001.
2. Người dùng biết ba điều, từ cùng một thời điểm: chuỗi ngày học hiện tại; hôm nay — tổng số thẻ
   cùng phân rã học mới / ôn tập; và bảy ngày gần nhất, cũ → mới, ngày không học là 0.
3. Tổng quan này đi cùng tiến độ theo deck của thư viện: hai thứ là một chỗ xem, không phải hai.
4. Người dùng xem xong và rời đi. Không gì được ghi trong toàn bộ luồng.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Hôm nay chưa học nhưng hôm qua có:** hôm nay là 0, và chuỗi **vẫn giữ** tới hôm qua. Người
  dùng biết đây là chuỗi đang giữ, không phải chuỗi đã mất.
- **A2 — Chưa từng học lượt nào:** người dùng biết mình chưa có gì để xem — không phải ba con số 0 —
  và được đưa tới chỗ học.
- **A3 — Một lượt học mới được ghi trong lúc đang xem:** các con số tự cập nhật, không cần thử lại.
- **A4 — Nửa đêm địa phương trôi qua trong lúc đang xem:** bảy ngày trượt một ngày, hôm nay về 0, và
  chuỗi chuyển sang nhánh đang giữ nếu phù hợp — không cần thao tác nào.
- **A5 — Đặt lại tiến độ học ở nơi khác rồi quay lại:** mọi con số giữ nguyên, vì việc đó không đụng
  lịch sử.
- **A6 — Xoá một card hoặc một deck ở nơi khác rồi quay lại:** hoạt động của các card đã xoá biến
  mất khỏi mọi ngày, kể cả ngày quá khứ.
- **A7 — Chỉ lướt `browse` rồi thoát:** không gì đổi — `browse` không tạo hoạt động.

**Error flows:**
- **E1 — Đọc lịch sử thất bại:** người dùng được báo lỗi, không kèm SQL, tên bảng hay nội dung thẻ,
  và thử lại được.
- **E2 — Thử lại vẫn lỗi:** người dùng vẫn được báo lỗi; hệ thống không tự thử lại theo vòng lặp và
  không ghi gì.

#### Acceptance criteria

- [ ] **Given** người dùng muốn xem tiến độ, **when** hệ thống đọc xong, **then** chuỗi hiện tại, hôm nay (kèm phân rã học mới / ôn tập) và bảy ngày gần nhất đến từ đúng một lần đọc đồng hồ và múi giờ.
- [ ] **Given** người dùng đang xem tiến độ, **when** người dùng chỉ xem rồi rời đi hoặc thử lại, **then** không có hàng nào trong `card_schedule`, `review_log`, `app_settings` hay `study_session` bị ghi, và không phiên nào được mở, tiếp tục hay đóng.
- [ ] **Given** hôm nay chưa học nhưng hôm qua có, **when** người dùng xem tiến độ, **then** hôm nay là 0 và chuỗi vẫn giữ nguyên số ngày tính tới hôm qua, và người dùng biết đây là chuỗi đang giữ (A1).
- [ ] **Given** đã có deck nhưng chưa từng học lượt nào, **when** người dùng xem tiến độ, **then** người dùng biết chưa có gì để xem, không phải các số 0 trần, và được đưa tới chỗ học (A2).
- [ ] **Given** người dùng đang xem tiến độ, **when** một lượt mới được ghi ở nơi khác, **then** các con số tự cập nhật mà không quay về trạng thái đang tải (A3).
- [ ] **Given** người dùng đang xem tiến độ lúc gần nửa đêm, **when** nửa đêm địa phương trôi qua, **then** bảy ngày trượt một ngày, hôm nay về 0, chuỗi chuyển sang nhánh đang giữ khi phù hợp, và không có ghi nào trong database (A4).
- [ ] **Given** đã học rồi đặt lại tiến độ học ở nơi khác, **when** quay lại xem tiến độ, **then** mọi con số giữ nguyên như trước khi đặt lại (A5).
- [ ] **Given** một card đã được trả lời rồi bị xoá cứng (trực tiếp hoặc theo cascade từ deck), **when** quay lại xem tiến độ, **then** hoạt động của card đó biến mất khỏi mọi ngày, kể cả ngày quá khứ (A6).
- [ ] **Given** một phiên chỉ lướt `browse`, một card hoặc deck trong Trash, hoặc một lượt có thời điểm sau ranh giới hôm nay, **when** đọc tiến độ, **then** các trường hợp đó không tạo card-day, không làm ngày thành có hoạt động và không giữ chuỗi (A7).
- [ ] **Given** lần đọc lịch sử thất bại, **when** người dùng xem tiến độ, **then** người dùng được báo lỗi, và thử lại thì đọc lại (E1).
- [ ] **Given** thử lại vẫn lỗi, **when** người dùng ở lại, **then** hệ thống không tự thử lại theo vòng lặp và không ghi gì (E2).

### UC-PROGRESS-002 — Xem tiến độ theo deck
Status: ready · Code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart] · Invokes: [FN-PROGRESS-001, FN-PROGRESS-002]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Biết mình đã học deck nào bao nhiêu trong 7 hoặc 30 ngày qua, và đi sâu vào từng cây
deck.
**Preconditions:** Không có. Thư viện rỗng và thư viện chưa học lần nào đều là trạng thái hợp lệ.

#### Main flow

**Main flow:**
1. Người dùng muốn xem tiến độ theo deck của thư viện. Hệ thống thực hiện FN-PROGRESS-001: người
   dùng biết, cho khoảng đang chọn (7 hoặc 30 ngày), bốn số của toàn bộ dữ liệu và bốn số của mỗi
   root deck.
2. Bốn số của một deck — số thẻ đã học, số ngày có học, số card-day học mới, số card-day ôn tập —
   phủ **toàn bộ cây con** của nó.
3. Deck học nhiều nhất trong khoảng đứng đầu; deck chưa học gì vẫn có mặt, ở cuối.
4. Người dùng đổi sang khoảng kia. Mọi con số và thứ tự đổi ngay, không phải chờ đọc lại.
5. Người dùng chọn một deck. Hệ thống thực hiện FN-PROGRESS-002: người dùng biết tổng của riêng cây
   con đó và bốn số của mỗi deck con trực tiếp, và đi sâu tiếp được. Quay lại đưa người dùng về
   đúng cấp vừa rời, ở mọi độ sâu.
6. Trong lúc đang xem, một lượt học được ghi, một thẻ được chuyển deck hoặc một deck bị xoá ở nơi
   khác: các con số tự cập nhật.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Deck chứa thẻ chứ không chứa deck con:** không có gì để đi sâu thêm. Người dùng vẫn biết
  tổng của chính deck đó, và biết tổng đó đã là toàn bộ — cấp này không rỗng.
- **A2 — Thư viện chưa có deck nào:** người dùng biết chưa có deck nào, và không có con số hay khoảng
  nào được đưa ra; bước tiếp theo nằm ở Library.
- **A3 — Có deck nhưng khoảng đang chọn không có hoạt động nào:** mọi deck vẫn có mặt với số 0, và
  người dùng được gợi ý xem khoảng dài hơn. Đây là trạng thái trung tính, không phải lỗi.
- **A4 — Nửa đêm địa phương trôi qua trong lúc đang xem:** khoảng đang chọn trượt một ngày và các con
  số tự đọc lại, dù không có gì được ghi.

**Error flows:**
- **E1 — Đọc thất bại:** người dùng được báo lỗi theo **loại** lỗi, không kèm chi tiết kỹ thuật, biết
  rằng lịch sử học không bị ảnh hưởng, và thử lại được.
- **E2 — Deck được yêu cầu không còn tồn tại:** đây **không** phải lỗi. Người dùng biết deck không
  còn, và chỉ được đưa về cấp thư viện — thử lại sẽ cho cùng kết quả nên không được đưa ra.

#### Acceptance criteria

- [ ] **Given** thư viện có ít nhất một root deck, **when** người dùng xem tiến độ theo deck, **then** người dùng biết khoảng đang chọn (7/30 ngày), bốn số của toàn bộ dữ liệu, và bốn số của mỗi root deck, sắp theo số thẻ đã học giảm dần rồi tên đã gập rồi `id`.
- [ ] **Given** cấp thư viện hoặc cấp một deck đang xem ở khoảng 7 ngày, **when** người dùng đổi sang 30 ngày, **then** mọi số và thứ tự đổi ngay sang khoảng 30 ngày, không phải chờ đọc lại.
- [ ] **Given** người dùng chọn một deck, **when** cấp của deck đó mở ra, **then** người dùng biết tổng của riêng cây con deck đó và bốn số của mỗi deck con trực tiếp; quay lại về đúng cấp vừa rời.
- [ ] **Given** cấp của một deck đang xem, **when** một lượt học được ghi, một deck con đổi tên, hoặc deck bị xoá ở nơi khác, **then** các con số tự cập nhật.
- [ ] **Given** một deck chỉ chứa thẻ (không có deck con), **when** xem cấp của deck đó, **then** người dùng biết tổng của chính deck đó và biết tổng đó đã là toàn bộ, không có hàng nào để đi sâu (A1).
- [ ] **Given** thư viện chưa có deck nào, **when** người dùng xem tiến độ theo deck, **then** người dùng biết chưa có deck nào, không có khoảng và không có tổng nào được đưa ra (A2).
- [ ] **Given** có deck nhưng khoảng đang chọn không có hoạt động nào, **when** đọc xong, **then** mọi deck vẫn có mặt với số 0, và người dùng được gợi ý xem khoảng dài hơn (A3).
- [ ] **Given** cấp thư viện hoặc cấp một deck đang xem gần nửa đêm, **when** nửa đêm địa phương trôi qua, **then** khoảng đang chọn trượt một ngày và các con số tự đọc lại mà không có ghi nào trong database (A4).
- [ ] **Given** lần đọc tiến độ theo deck thất bại, **when** người dùng xem, **then** người dùng được báo lỗi theo đúng loại lỗi, không nêu nguyên nhân kỹ thuật, và thử lại thì đọc lại (E1).
- [ ] **Given** deck được yêu cầu đã bị xoá, ở trong Trash hoặc không tồn tại, **when** người dùng mở tiến độ của nó, **then** người dùng biết deck không còn và chỉ được đưa về cấp thư viện, không có thử lại (E2).

## Search

### UC-SEARCH-001 — Tìm kiếm toàn thư viện
Status: ready · Code: [lib/features/search/domain/usecases/search_library_use_case.dart] · Invokes: [FN-SEARCH-001]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Tìm nhanh một deck hay một card trong cả thư viện theo tên, mặt thẻ hoặc tag, rồi đi
tới nó — từ bất kỳ đâu trong Library.
**Preconditions:** Không có. Thư viện rỗng vẫn tìm được.

#### Main flow

**Main flow:**
1. Người dùng muốn tìm. Người dùng có thể gõ ngay, và quay lại đúng chỗ vừa rời khi thôi tìm.
2. Trước khi gõ, người dùng biết tìm được những gì: tên deck, mặt trước và mặt sau của card, tên
   tag. Chưa có gì được đọc.
3. Người dùng gõ. Khi người dùng ngừng gõ, hệ thống thực hiện FN-SEARCH-001 cho từ đó và đọc **một
   trang** kết quả; từ gõ dở trước đó không bao giờ được tìm.
4. Người dùng biết kết quả theo hai nhóm — deck trước, card sau — mỗi nhóm với số đếm riêng, khớp
   tốt nhất trước.
5. Với mỗi deck, người dùng biết nó nằm ở đâu trong cây. Với mỗi card, người dùng biết deck chứa nó,
   mặt trước, tóm tắt mặt sau, và tag đã làm nó khớp khi nó khớp **chỉ** qua tag.
6. Người dùng chọn một kết quả: deck thì tới deck đó, card thì xem chi tiết card ở chế độ chỉ đọc.
   Không phiên học nào được mở.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Còn kết quả phía sau:** người dùng biết còn nhiều hơn và đọc thêm được; trang kế tiếp không
  lặp và không sót dòng.
- **A2 — Chỉ có deck, hoặc chỉ có card:** nhóm không có kết quả không xuất hiện.
- **A3 — Dữ liệu đổi ở nơi khác:** đổi tên, di chuyển, xoá hoặc đổi tên tag cập nhật ngay các kết quả
  và đường dẫn người dùng đang thấy, không cần tìm lại.
- **A4 — Xoá hết từ đang tìm:** về trạng thái ban đầu ngay, không chờ và không đọc gì.

**Error flows:**
- **E1 — Trang đầu đọc lỗi:** người dùng được báo lỗi và thử lại được; không kết quả cũ nào còn lại,
  vì kết quả của từ cũ dưới một thông báo lỗi là sai.
- **E2 — Trang sau đọc lỗi:** những gì đã tìm được giữ nguyên; người dùng được báo lỗi ở phần đọc
  thêm và thử lại được đúng phần đó.

#### Acceptance criteria

- [ ] **Given** chưa có từ nào để tìm, **when** người dùng muốn tìm, **then** người dùng biết tìm được tên deck, mặt trước và mặt sau card, và tên tag, và chưa gì được đọc.
- [ ] **Given** người dùng gõ, **when** người dùng ngừng gõ, **then** từ cần tìm được gập bằng đúng hàm của các cột đã lưu và đúng một lần đọc trang đầu chạy; từ gõ trước đó không bao giờ được đọc.
- [ ] **Given** có kết quả, **when** người dùng xem, **then** deck đứng trước card, mỗi nhóm có số đếm riêng, và một card chỉ khớp qua mặt trước, mặt sau hoặc tên tag, không bao giờ qua example, hint hay phiên âm.
- [ ] **Given** nhiều kết quả khớp, **when** xếp hạng, **then** mỗi nhóm xếp khớp đúng trước khớp tiền tố trước khớp chứa, bậc của một card là bậc tốt nhất trong các trường nó khớp, và hoà thì xét văn bản đã gập, rồi `created_at`, rồi `id`.
- [ ] **Given** một card khớp qua nhiều trường, **when** người dùng xem, **then** nó xuất hiện đúng một lần; card chỉ khớp qua tag thì nêu tag khớp tốt nhất; deck có đường dẫn tổ tiên, card có đường dẫn deck chứa nó.
- [ ] **Given** một kết quả, **when** người dùng chọn nó, **then** kết quả deck đưa tới deck đó, kết quả card đưa tới chi tiết chỉ đọc của card đó.
- [ ] **Given** hơn 50 kết quả, **when** người dùng xem, **then** người dùng biết còn nhiều hơn, và đọc thêm nối trang kế tiếp theo con trỏ, không lặp và không sót (A1).
- [ ] **Given** chỉ một nhóm có kết quả, **when** người dùng xem, **then** nhóm còn lại không xuất hiện (A2).
- [ ] **Given** deck hoặc tag của một kết quả đang thấy bị đổi tên, di chuyển hoặc xoá ở nơi khác, **when** thay đổi xảy ra, **then** kết quả cập nhật tại chỗ mà không cần tìm lại (A3).
- [ ] **Given** đang có từ để tìm, **when** người dùng xoá hết, **then** về trạng thái ban đầu ngay, không chờ và không đọc gì (A4).
- [ ] **Given** đọc trang đầu thất bại, **when** lỗi xảy ra, **then** người dùng được báo lỗi, không còn kết quả cũ, và thử lại đọc lại từ trang đầu (E1).
- [ ] **Given** đọc một trang sau thất bại, **when** lỗi xảy ra, **then** kết quả đã có giữ nguyên, người dùng được báo lỗi ở phần đọc thêm, và thử lại đọc lại đúng con trỏ đó (E2).

## Tags

### UC-TAG-001 — Quản lý tag và lọc thẻ theo tag
Status: ready · Code: [lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart, lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart, lib/features/tags/domain/usecases/rename_tag_use_case.dart, lib/features/tags/domain/usecases/delete_tag_use_case.dart, lib/features/card/domain/usecases/watch_card_tag_filter_use_case.dart, lib/features/card/domain/usecases/watch_card_list_use_case.dart] · Invokes: [FN-TAG-001, FN-TAG-002, FN-TAG-003, FN-TAG-004, FN-CARD-012, FN-CARD-001]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Giữ bộ tag của thư viện gọn gàng — xem, tìm, đổi tên, gộp, xoá — và lọc thẻ của một
deck theo tag.
**Preconditions:** Không có. Thư viện chưa có tag nào là một trạng thái hợp lệ, không phải lỗi.

#### Main flow

**Main flow:**
1. Người dùng muốn xem các tag. Hệ thống thực hiện FN-TAG-001: người dùng biết mọi tag của thư viện
   cùng số thẻ đang mang mỗi tag.
2. Với mỗi tag, người dùng có thể đổi tên hoặc xoá nó.
3. Người dùng tìm trong danh mục để thu hẹp nó. Việc tìm không phân biệt hoa thường hay khoảng
   trắng hai đầu, đúng như khi tag được tạo: `ĐỘNG TỪ` và `động từ` tìm thấy nhau.
4. Người dùng muốn đổi tên một tag, bắt đầu từ tên hiện tại.
5. Người dùng sửa tên và xác nhận. Hệ thống thực hiện FN-TAG-003; khi tên mới không trùng tag nào
   khác, đó vẫn là chính tag đó và mọi thẻ của nó giữ nguyên.
6. Trong một deck, người dùng muốn lọc thẻ theo tag. Hệ thống thực hiện FN-CARD-012: người dùng biết
   mọi tag cùng số thẻ của deck mang nó, và tập tag đang chọn.
7. Người dùng chọn nhiều tag và áp dụng. Hệ thống thực hiện FN-CARD-001 với tập đó: một thẻ qua khi
   mang **bất kỳ** tag nào đã chọn, đồng thời vẫn khớp bộ lọc trạng thái và từ khoá đang bật. Danh
   sách bắt đầu lại từ đầu, và lựa chọn đang có bị bỏ.
8. Người dùng biết đúng tập thẻ khớp, mỗi thẻ đúng một lần, với số đếm khớp danh sách.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Đổi tên gây trùng (gộp):** tên mới trùng một tag khác khi bỏ qua hoa thường. Hệ thống thực
  hiện FN-TAG-002, và người dùng biết **trước khi xác nhận** rằng việc này sẽ gộp vào tag đích, tên
  của nó và số thẻ sau khi gộp. Xác nhận thì mọi thẻ của hai tag về chung tag đích, liên kết trùng
  được bỏ và tag nguồn biến mất — tất cả cùng lúc. Không thẻ nào vượt quá 10 tag.
- **A2 — Đổi tên chỉ đổi cách viết hoa:** `noun` → `Noun` là đổi cách viết, không phải gộp: vẫn là
  chính tag đó, mọi thẻ giữ nguyên.
- **A3 — Xoá tag:** người dùng xác nhận trước, biết số thẻ sẽ bị gỡ tag và biết rằng thẻ **không**
  bị xoá. Hệ thống thực hiện FN-TAG-004.
- **A4 — Bỏ chọn hết tag khi lọc:** tập rỗng không lọc gì — danh sách trở lại đúng như trước khi lọc.
- **A5 — Thôi lọc mà không áp dụng:** tập tag đang áp giữ nguyên; lựa chọn dở bị bỏ.
- **A6 — Tìm trong danh mục không khớp gì:** người dùng biết không có tag nào khớp với từ đã gõ, khác
  với việc thư viện chưa có tag nào.
- **A7 — Lọc theo tag không còn thẻ nào khớp:** người dùng biết bộ lọc không cho kết quả nào, và bỏ
  được bộ lọc tag.

**Error flows:**
- **E1 — Đọc danh mục thất bại:** người dùng được báo lỗi và thử lại được; chưa gì bị thay đổi.
- **E2 — Đổi tên với tên không hợp lệ:** rỗng, quá 50 ký tự, hoặc chứa ký tự điều khiển — người dùng
  biết lý do ngay, và tên đang nhập giữ nguyên.
- **E3 — Tag đã biến mất:** tag bị xoá ở nơi khác giữa lúc bắt đầu đổi tên và lúc ghi — người dùng
  biết tag không còn, danh mục tự cập nhật, và không gì được ghi.
- **E4 — Ghi thất bại giữa lúc gộp:** cả hai tag và mọi liên kết trở lại đúng như trước, và người
  dùng được báo lỗi chứ không phải thành công.
- **E5 — Xoá thất bại:** tag và mọi liên kết còn nguyên, không thẻ nào bị đụng tới.

#### Acceptance criteria

- [ ] **Given** người dùng muốn xem các tag, **when** đọc xong, **then** mọi tag của thư viện có mặt kèm số card active đang mang nó, sắp theo tên đã gập rồi `id`.
- [ ] **Given** người dùng tìm trong danh mục, **when** lọc, **then** hệ thống dùng đúng hàm gập của danh tính tag, nên `ĐỘNG TỪ` tìm thấy `động từ`.
- [ ] **Given** đổi tên chỉ khác chữ hoa hoặc dấu và tên đã gập không trùng tag khác, **when** xác nhận, **then** `name` và `name_folded` được ghi lên chính hàng tag đó, `id` và liên kết thẻ giữ nguyên (A2).
- [ ] **Given** người dùng chọn nhiều tag để lọc, **when** áp dụng, **then** danh sách có các card mang bất kỳ tag nào đã chọn, đồng thời khớp bộ lọc và từ khoá hiện tại, mỗi card đúng một lần.
- [ ] **Given** một tập tag lọc mới, **when** áp dụng, **then** danh sách bắt đầu lại từ đầu và lựa chọn đang có bị bỏ.
- [ ] **Given** tên mới gập trùng một tag khác, **when** xác nhận đổi tên, **then** người dùng đã biết trước việc gộp và tên đích; xác nhận thì mọi thẻ của hai tag về chung tag đích, liên kết trùng được bỏ, tag nguồn bị xoá, tất cả trong một transaction, và không thẻ nào vượt 10 tag (A1).
- [ ] **Given** người dùng muốn xoá một tag, **when** xác nhận, **then** liên kết `card_tags` bị gỡ và hàng `tags` bị xoá trong một transaction, không card nào bị xoá (A3).
- [ ] **Given** đang có tag được chọn để lọc, **when** người dùng bỏ chọn hết rồi áp dụng, **then** không bộ lọc tag nào được áp và danh sách trở lại như trước khi lọc (A4).
- [ ] **Given** một tập tag đã áp dụng, **when** người dùng thôi mà không áp dụng lại, **then** tập tag đang áp giữ nguyên và lựa chọn dở bị bỏ (A5).
- [ ] **Given** tìm trong danh mục không khớp tag nào, **when** người dùng xem, **then** người dùng biết không có tag nào khớp từ đã gõ, khác với trạng thái chưa có tag nào (A6).
- [ ] **Given** lọc theo một tag không có card nào trong deck đang mở, **when** áp dụng, **then** người dùng biết không có kết quả và bỏ được bộ lọc tag (A7).
- [ ] **Given** đọc danh mục thất bại, **when** lỗi xảy ra, **then** người dùng được báo lỗi, thử lại được, và không gì được ghi (E1).
- [ ] **Given** tên mới rỗng sau khi bỏ khoảng trắng, quá 50 ký tự hoặc chứa ký tự điều khiển, **when** xác nhận, **then** người dùng biết lý do và tên đang nhập được giữ nguyên (E2).
- [ ] **Given** tag bị xoá ở nơi khác giữa lúc bắt đầu đổi tên và lúc ghi, **when** ghi chạy, **then** thao tác bị từ chối vì tag không còn, danh mục tự cập nhật, và không gì được ghi (E3).
- [ ] **Given** ghi thất bại giữa lúc gộp tag, **when** lỗi xảy ra, **then** cả hai tag và mọi liên kết trở lại đúng như trước, và người dùng được báo lỗi chứ không phải thành công (E4).
- [ ] **Given** ghi thất bại khi xoá tag, **when** lỗi xảy ra, **then** tag và mọi liên kết còn nguyên, không thẻ nào bị đụng tới (E5).

## Trash

### UC-TRASH-001 — Trash và khôi phục item đã xoá
Status: ready · Code: [lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart, lib/features/trash/domain/usecases/watch_trash_use_case.dart, lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart, lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart, lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart, lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart, lib/features/trash/domain/usecases/purge_trash_use_case.dart] · Invokes: [FN-DECK-005, FN-CARD-004, FN-DECK-006, FN-CARD-005, FN-TRASH-001, FN-TRASH-002, FN-TRASH-003, FN-TRASH-004, FN-TRASH-005, FN-TRASH-006, FN-TRASH-007]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Xoá mà không sợ mất: lấy lại ngay thứ vừa xoá, hoặc khôi phục nó trong 30 ngày vào nơi
mình chọn — và xoá hẳn khi thật sự muốn.
**Preconditions:** Không có. Trash rỗng vẫn xem được — đó là cách người dùng biết nó tồn tại.

#### Main flow

**Main flow:**
1. Người dùng xoá một deck (FN-DECK-005) hoặc một card (FN-CARD-004). Thứ bị xoá cùng mọi thứ bên
   trong nó vào Trash cùng lúc, và phiên học đang mở chạm tới nó kết thúc.
2. Người dùng biết thứ đó đã vào Trash và có thể hoàn tác trong một khoảng ngắn. Ở mọi nơi khác, nó
   biến mất ngay — khỏi danh sách, con số, tìm kiếm và việc học.
3. Người dùng muốn xem Trash. Hệ thống thực hiện FN-TRASH-001 trước rồi FN-TRASH-002: người dùng
   biết các mục còn lại, tách thành card và deck.
4. Với mỗi mục, người dùng biết tên, lúc bị xoá, nơi nó từng nằm — chỉ để biết — và còn bao nhiêu
   ngày trước khi bị xoá vĩnh viễn; với deck, cả số deck và card đi cùng.
5. Người dùng muốn khôi phục một mục. Hệ thống thực hiện FN-TRASH-003 hoặc FN-TRASH-004: người dùng
   chỉ được đưa ra những nơi thật sự nhận được mục đó.
6. Người dùng chọn một nơi và xác nhận. Hệ thống thực hiện FN-TRASH-005 hoặc FN-TRASH-006.
7. Mục rời Trash và có mặt ở nơi mới, nguyên vẹn: cùng nội dung, trạng thái học, lịch sử và tag.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Hoàn tác ngay sau khi xoá:** hệ thống thực hiện FN-DECK-006 hoặc FN-CARD-005; đúng thứ vừa
  xoá trở về **chỗ cũ**, không hỏi nơi nào.
- **A2 — Chọn nhiều:** người dùng chọn nhiều mục để khôi phục hoặc xoá vĩnh viễn cùng lúc. Một lựa
  chọn chỉ gồm một loại — toàn card hoặc toàn deck — và người dùng biết vì sao.
- **A3 — Xoá vĩnh viễn:** người dùng xác nhận trước, biết đúng số mục và biết lịch sử học không khôi
  phục được; mặc định là lựa chọn an toàn. Hệ thống thực hiện FN-TRASH-007.
- **A4 — Một mục hết hạn trong lúc đang xem:** khi người dùng quay lại, việc dọn chạy lại và mục hết
  hạn biến mất tại chỗ.
- **A5 — Deck có deck con đã vào Trash từ trước:** khôi phục deck cha chỉ đưa về những gì bị xoá
  cùng nó; deck con kia vẫn là một mục riêng trong Trash.
- **A6 — Trash rỗng:** người dùng biết thứ bị xoá sẽ nằm ở đây 30 ngày.

**Error flows:**
- **E1 — Không có nơi nào nhận được:** người dùng biết vì sao (cây đã quá sâu, hoặc không còn deck
  nào nhận loại nội dung này), và không có nơi nào trông như chọn được mà lại không.
- **E2 — Nơi đã chọn hết hợp lệ giữa chừng:** cây đổi sau khi chọn; việc khôi phục bị từ chối, người
  dùng biết lý do, không gì được ghi, và danh sách nơi nhận được cập nhật.
- **E3 — Hoàn tác không còn được:** chỗ cũ đã bị xoá, đã chứa loại nội dung khác, hoặc đã quá sâu.
  Người dùng biết lý do và được chỉ sang Trash; mục vẫn nằm nguyên trong Trash.
- **E4 — Xoá vĩnh viễn bị chặn:** bên trong một deck còn mục chưa được chọn và chưa hết hạn. Deck đó
  được bỏ qua nguyên vẹn, không xoá một phần, và người dùng biết lý do.
- **E5 — Lỗi ghi:** xoá, khôi phục hay xoá vĩnh viễn thất bại thì không gì thay đổi; người dùng được
  báo lỗi và thử lại được.
- **E6 — Mục đã biến mất:** mục được chọn đã bị xoá vĩnh viễn ở nơi khác. Người dùng biết nó không
  còn, và Trash tự cập nhật.

#### Acceptance criteria

- [ ] **Given** người dùng xoá một card hoặc một deck, **when** thao tác chạy, **then** hệ thống tạo đúng một batch trong một transaction, đánh dấu item cùng mọi descendant đang active bằng batch đó, đưa parent về `unset` khi nó vừa mất direct child active cuối, và đóng mọi phiên `in_progress` chạm tới item với `end_reason = content_deleted`.
- [ ] **Given** một item vừa xoá xong, **when** người dùng xem bất kỳ nơi nào khác, **then** item và mọi hoạt động của nó biến mất, và người dùng hoàn tác được.
- [ ] **Given** người dùng muốn xem Trash, **when** hệ thống đọc xong, **then** việc dọn mục hết hạn đã chạy trước, và mỗi batch còn lại có loại, tên, thời điểm bị xoá, đường dẫn gốc và số ngày còn lại.
- [ ] **Given** người dùng muốn khôi phục một mục, **when** các nơi nhận được đưa ra, **then** chỉ gồm deck đang active hợp lệ cho mục đó; xác nhận một nơi ghi lại đúng batch đó trong một transaction, giữ nguyên id, nội dung, trạng thái học, lịch sử và tag.
- [ ] **Given** người dùng hoàn tác ngay sau khi xoá, **when** hoàn tác chạy, **then** đúng batch đó trở về vị trí cũ mà không hỏi nơi nào (A1).
- [ ] **Given** người dùng chọn nhiều mục, **when** đã chọn một card rồi muốn chọn một deck, **then** lựa chọn chỉ gồm một loại, và khôi phục hay xoá vĩnh viễn áp cho đúng tập đang chọn (A2).
- [ ] **Given** người dùng muốn xoá vĩnh viễn một hoặc nhiều mục, **when** được hỏi xác nhận, **then** người dùng biết đúng số lượng, biết lịch sử học không khôi phục được, mặc định là giữ lại trong Trash, và chỉ xác nhận xoá mới xoá (A3).
- [ ] **Given** một batch vừa quá 30 ngày trong lúc người dùng đang xem Trash, **when** người dùng quay lại app, **then** việc dọn chạy lại và mục hết hạn biến mất tại chỗ (A4).
- [ ] **Given** một deck cha bị xoá trong khi một descendant đã ở Trash từ một batch cũ hơn, **when** xem lại Trash, **then** descendant đó vẫn là một mục riêng với batch cũ của nó (A5).
- [ ] **Given** Trash không có batch nào, **when** người dùng xem Trash, **then** người dùng biết thứ bị xoá sẽ nằm ở đây 30 ngày (A6).
- [ ] **Given** một mục không còn nơi nào nhận được, **when** người dùng muốn khôi phục, **then** người dùng biết lý do, và không có nơi nào trông như chọn được (E1).
- [ ] **Given** người dùng đang chọn nơi khôi phục, **when** cây deck đổi, **then** danh sách nơi nhận được đi theo cây; nếu nơi đã chọn không còn hợp lệ lúc xác nhận thì việc khôi phục bị từ chối và không gì được ghi (E2).
- [ ] **Given** vị trí cũ của một batch không còn nhận nó, **when** người dùng hoàn tác, **then** người dùng biết lý do và mục vẫn nằm trong Trash (E3).
- [ ] **Given** một deck được chọn để xoá vĩnh viễn còn giữ một batch khác không được chọn, **when** xoá vĩnh viễn chạy, **then** deck đó được bỏ qua nguyên vẹn và người dùng biết lý do (E4).
- [ ] **Given** một bước ghi giữa chừng của việc xoá vĩnh viễn lỗi, **when** transaction chạy, **then** toàn bộ rollback và dữ liệu giữ nguyên như trước (E5).
- [ ] **Given** một batch được chọn để khôi phục hoặc xoá vĩnh viễn đã bị xoá vĩnh viễn trước đó, **when** thao tác chạy, **then** người dùng biết đúng batch đó không còn (E6).

## Transfer

### UC-TRANSFER-001 — Import card hàng loạt vào một deck
Status: ready · Code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/usecases/commit_import_use_case.dart] · Invokes: [FN-TRANSFER-001, FN-TRANSFER-002, FN-TRANSFER-003]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Đưa nhiều card vào một deck cùng lúc từ một bảng tính hay văn bản có sẵn, biết trước
điều gì sẽ được ghi, và không bao giờ ghi nửa chừng.
**Preconditions:** Deck đích tồn tại, không phải root, và đang chứa card hoặc chưa chứa gì.

#### Main flow

**Main flow:**
1. Người dùng muốn import vào một deck. Người dùng biết deck đích, số card nó đang có, và các bước:
   chọn nguồn, ghép cột, xem trước, import.
2. Người dùng chọn nguồn: một file CSV, TSV hoặc XLSX, hoặc dán văn bản CSV/TSV.
3. Người dùng muốn xem trước. Hệ thống thực hiện FN-TRANSFER-001; không gì được ghi.
4. Hàng đầu được coi là header và các cột trùng tên được ghép sẵn; người dùng chỉnh cách ghép nếu
   cần. Mặt trước và mặt sau phải được ghép, và một cột nguồn không ghép vào hai nơi.
5. Hệ thống thực hiện FN-TRANSFER-002: người dùng biết tổng số hàng, số sẵn sàng, số trùng, số không
   hợp lệ kèm lý do, số hàng trống bị bỏ qua, và các hàng đầu tiên.
6. Người dùng xác nhận, biết deck đích, số card sẽ ghi, và số hàng trùng hay không hợp lệ bị bỏ.
7. Hệ thống thực hiện FN-TRANSFER-003: mọi card được ghi cùng lúc, hoặc không card nào.
8. Người dùng biết kết quả — số đã ghi, số trùng bỏ qua, số không hợp lệ, và từng hàng bị bỏ qua với
   số dòng và lý do — rồi xem các card của deck, hoặc import một nguồn khác vào cùng deck.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Dán văn bản:** người dùng dán các hàng CSV/TSV; nó chỉ được đọc khi người dùng muốn xem
  trước, và văn bản giữ nguyên nếu đọc lỗi.
- **A2 — XLSX nhiều sheet:** sheet không rỗng đầu tiên được chọn sẵn; người dùng đổi sheet được, và
  việc ghép cột cùng xem trước chạy lại.
- **A3 — Không có header:** người dùng cho biết hàng đầu không phải header; các cột mang tên theo vị
  trí, và hàng đầu là dữ liệu.
- **A4 — Ghi cả hàng trùng:** người dùng chọn ghi cả hàng trùng; chúng được tính là sẵn sàng và
  được ghi thành card mới.
- **A5 — Đổi nguồn:** người dùng thay nguồn đã chọn; thôi chọn file không phải lỗi và không bỏ lựa
  chọn trước đó.

**Error flows:**
- **E1 — Không đọc được nguồn:** file hỏng, có mật khẩu, định dạng không hỗ trợ hoặc không phải
  UTF-8 — người dùng biết lý do và cách sửa (lưu lại dạng UTF-8); nguồn đã chọn trước đó giữ nguyên.
- **E2 — Nguồn rỗng:** không có hàng dữ liệu nào — người dùng biết ngay khi xem trước, và không đi
  tiếp được.
- **E3 — Không còn hàng nào để ghi:** sau kiểm tra và cách xử lý trùng, số sẽ ghi là 0 — không đi
  tiếp được, và không gì được ghi.
- **E4 — Deck đích không còn nhận được lúc ghi:** deck biến mất, thành root, hoặc đã chứa deck con —
  việc ghi bị từ chối, người dùng biết lý do, không gì được ghi, và bản xem trước cùng cách ghép cột
  giữ nguyên.
- **E5 — Ghi thất bại giữa chừng:** không gì thay đổi; nguồn, cách ghép cột và bản xem trước giữ
  nguyên, và người dùng thử lại được.
- **E6 — Mọi hàng đã thành trùng lúc ghi:** giữa lúc xem trước và lúc ghi, deck đã nhận các card trùng
  với mọi hàng sẽ ghi — không card nào được ghi, deck không đổi gì, và người dùng biết không có gì
  được thêm.

#### Acceptance criteria

- [ ] **Given** một deck con chưa chứa gì và một file CSV có header `front,back,tags`, **when** người dùng import, **then** mỗi hàng hợp lệ thành một card mới có đúng một trạng thái học mới và tag của nó, deck thành deck chứa card, và không có lịch sử ôn tập nào.
- [ ] **Given** một hàng trùng mặt trước và mặt sau (sau khi gập) với card đã có trong deck và một hàng lặp lại trong file, **when** xem trước, **then** hai hàng đó được đánh dấu trùng và mặc định bị bỏ; chọn ghi cả hàng trùng thì cả hai được ghi thành card mới.
- [ ] **Given** một file UTF-16 hoặc Latin-1, **when** người dùng chọn file, **then** hệ thống từ chối với lý do encoding kèm cách sửa, và không gì được ghi.
- [ ] **Given** đã xem trước xong và deck vừa nhận deck con, **when** ghi, **then** việc ghi bị từ chối với lý do và không gì được ghi (E4).
- [ ] **Given** một lần ghi lỗi giữa chừng, **when** import, **then** không card, trạng thái học, tag hay loại nội dung nào đổi (E5).

### UC-TRANSFER-002 — Export card của một deck ra file
Status: ready · Code: [lib/features/transfer/domain/usecases/count_export_cards_use_case.dart, lib/features/transfer/domain/usecases/build_export_use_case.dart, lib/features/transfer/domain/usecases/share_export_use_case.dart] · Invokes: [FN-TRANSFER-004, FN-TRANSFER-005, FN-TRANSFER-006]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Mục tiêu:** Lấy card của một deck — cả deck hoặc những card đã chọn — ra một file để giữ hay dùng ở
nơi khác, mà không làm thay đổi gì trong app.
**Preconditions:** Deck là deck con chứa card và có ít nhất một card; khi export các card đã chọn thì
tập chọn không rỗng.

#### Main flow

**Main flow:**
1. Người dùng muốn export cả deck, hoặc các card đang chọn. Người dùng biết phạm vi — "toàn bộ N card
   của deck" (FN-TRANSFER-004) hoặc "N card đã chọn" — và không đổi được nó: phạm vi là hệ quả của
   nơi người dùng bắt đầu.
2. Người dùng biết ba định dạng — CSV (khuyến nghị, mặc định), TSV, XLSX — rằng file chứa nội dung và
   tag, và rằng tiến độ học cùng lịch sử **không** có trong file.
3. Người dùng chọn định dạng nếu muốn khác, rồi export.
4. Hệ thống thực hiện FN-TRANSFER-005: một file từ một lần đọc nhất quán, không ghi gì.
5. Hệ thống thực hiện FN-TRANSFER-006: file được giao cho bảng chia sẻ của hệ điều hành.
6. Người dùng chọn đích. Người dùng biết file đã được giao cho hệ thống — **không** phải đã được lưu ở
   một nơi nào đó.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Phạm vi là các card đã chọn:** file chứa đúng tập đã chọn, mỗi card một lần, theo thứ tự tạo
  chứ không theo thứ tự chọn. Lựa chọn giữ nguyên sau khi export.
- **A2 — Đổi định dạng:** sáu cột, thứ tự card và ô tag không đổi; chỉ cách mã hoá đổi.
- **A3 — Thoát bảng chia sẻ:** người dùng thoát mà không chọn đích. Đây là **huỷ**: không có lỗi,
  người dùng trở lại với phạm vi và định dạng đang chọn, và không có câu nào nói file đã được lưu.
- **A4 — Yêu cầu export lần thứ hai khi đang tạo file:** lần sau bị bỏ qua; một lần mở chỉ tạo một
  file.
- **A5 — Thôi trước khi export:** không file nào được tạo, lựa chọn không đổi.

**Error flows:**
- **E1 — Thiết bị không có bảng chia sẻ:** người dùng biết chia sẻ không khả dụng; phạm vi và định
  dạng giữ nguyên, và không file nào còn lại.
- **E2 — Lỗi từ nền tảng khi chia sẻ:** người dùng biết lý do, không kèm đường dẫn, tên file hay nội
  dung card, và thử lại được với cùng phạm vi và định dạng.
- **E3 — Đọc dữ liệu thất bại:** không có file và không gì thay đổi; người dùng biết lý do và thử lại
  được.
- **E4 — Không tạo được file:** người dùng biết lý do, phân biệt được với lỗi đọc; không có file một
  phần nào được giao đi.
- **E5 — Không có gì để export:** deck rỗng hoặc tập chọn rỗng — bị từ chối. Bình thường người dùng
  không tới được đây; đây là chặn cho trường hợp cây đã đổi.
- **E6 — Card đã chọn không còn hợp lệ:** một card đã bị xoá hoặc đã chuyển deck — cả yêu cầu thất
  bại, không có file một phần, và người dùng được mời chọn lại.

#### Acceptance criteria

- [ ] **Given** một deck chứa card, **when** export CSV, TSV hoặc XLSX, **then** file có sáu header chuẩn, card theo `created_at` rồi `id`, tag theo tên đã gập, và import lại file vào một deck trống cho đúng nội dung đó.
- [ ] **Given** một ô bắt đầu bằng `=` hoặc một chuỗi như `001`, **when** export XLSX, **then** ô được ghi là text, không thành công thức hay số.
- [ ] **Given** một tập chọn có một card đã bị xoá hoặc đã chuyển deck, **when** export, **then** cả yêu cầu thất bại và không có file (E6).
- [ ] **Given** bất kỳ lần export nào, **when** export xong hoặc thất bại, **then** database không đổi.
- [ ] **Given** người dùng thoát bảng chia sẻ, **when** việc chia sẻ trả về, **then** đó là huỷ, không phải lỗi, và app không nói file đã được lưu (A3).

## Starter decks

### UC-STARTER-001 — Khởi động lần đầu và chọn starter deck
Status: ready · Code: [lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart, lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart] · Invokes: [FN-STARTER-001, FN-STARTER-002, FN-DECK-001]

#### Mục tiêu / Actor / Precondition

**Actor:** Người dùng mới cài app
**Mục tiêu:** Có thứ để học ngay ở lần đầu mở app, bằng cách lấy một bộ thẻ có sẵn làm deck của
riêng mình — hoặc tự tạo deck đầu tiên.
**Preconditions:** Chưa có deck nào.

#### Main flow

**Main flow:**
1. Người dùng mở app lần đầu.
2. Dữ liệu của app được khởi tạo.
3. Người dùng biết thư viện còn trống, và có hai lối: chọn một starter deck, hoặc tự tạo deck mới.
4. Người dùng muốn xem các starter deck.
5. Hệ thống thực hiện FN-STARTER-001: người dùng biết mỗi template — tên, số card, ngôn ngữ, nguồn
   nội dung — và biết nội dung starter là fixture cho development và test.
6. Người dùng chọn một starter deck.
7. Người dùng chọn chế độ ôn tập cho bản sao; chế độ của template được gợi ý sẵn.
8. Hệ thống thực hiện FN-STARTER-002: bản sao được tạo trọn vẹn, cùng lúc.
9. Bản sao có mặt trong thư viện. Mọi card của nó đều chưa học, nên deck có thẻ mới để học chứ chưa
   có thẻ đến hạn.
10. Người dùng bắt đầu một phiên học mới ngay.

#### Alternative / Error flow

**Alternative flows:**
- **A1 — Bỏ qua thư viện, tự tạo deck:** hệ thống thực hiện FN-DECK-001.
- **A2 — Đã có bản sao từ đúng template và version đó:** người dùng biết nó đã có và xác nhận nếu
  vẫn muốn thêm. Đồng ý thì một bản sao thứ hai được tạo — một lựa chọn có ý thức, khác hẳn việc app
  tự tạo trùng.
- **A3 — Cập nhật app có template mới hoặc version mới:** template mới có mặt trong thư viện starter.
  Bản sao đã có **không** bị đụng tới.
- **A4 — Người dùng đã xoá bản sao:** template vẫn còn trong thư viện starter và lấy lại được, không
  cần xác nhận.

**Error flows:**
- **E1 — Không mở được dữ liệu của app:** người dùng được báo lỗi rõ ràng và thử lại được — không bao
  giờ là một màn trắng, vì màn trắng không phân biệt được với treo.
- **E2 — Danh mục template hỏng hoặc thiếu:** thư viện starter rỗng; app vẫn dùng bình thường với việc
  tự tạo deck.
- **E3 — Một template hỏng:** chỉ template đó vắng mặt, các template khác vẫn có.
- **E4 — Sao chép thất bại giữa chừng:** không gì được ghi; không có cây deck nửa vời.

#### Acceptance criteria

- [ ] **Given** thư viện starter có template "English → Vietnamese · Everyday" và chưa có bản sao nào của nó, **when** người dùng thêm nó với SM-2, **then** có một root deck mới mang tên template, `source_template_id` và `source_template_version` của nó, `generation = 1`, `first_answered_at` NULL; bốn sub-deck theo đúng thứ tự; 40 card chưa học, mỗi card đúng một trạng thái học khởi tạo theo SM-2.
- [ ] **Given** đã có một bản sao của đúng template và version đó nằm ngoài Trash, **when** người dùng thêm lại mà không xác nhận, **then** không gì được ghi và lý do là `alreadyInLibrary`; khi người dùng xác nhận thêm bản sao thứ hai, có một cây deck thứ hai độc lập (A2).
- [ ] **Given** bản sao duy nhất của một template nằm trong Trash, **when** người dùng thêm template đó, **then** một bản sao mới được tạo mà không hỏi (A4).
- [ ] **Given** bản app mới nâng version của một template đã có bản sao, **when** người dùng xem thư viện starter, **then** template được coi là chưa có, và thêm nó không đụng bản sao của version cũ (A3).
- [ ] **Given** danh mục template thiếu hoặc hỏng, **when** người dùng xem thư viện starter, **then** nó rỗng; **given** một file template hỏng, **then** chỉ template đó vắng mặt (E2, E3).
- [ ] **Given** một lần ghi thất bại giữa chừng khi sao chép, **when** thêm template, **then** không root, deck, card hay trạng thái học nào được ghi (E4).
