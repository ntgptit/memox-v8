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
