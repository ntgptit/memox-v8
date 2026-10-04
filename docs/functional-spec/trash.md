# Trash — functional specification

Các chức năng của feature trash. Định dạng: [docs/README.md](../README.md), mục "UC, FN và screen
spec". Khôi phục deck trả lỗi `DeckRejection`
(`lib/features/deck/domain/failures/deck_failure.dart`), khôi phục card trả lỗi `CardRejection`
(`lib/features/card/domain/failures/card_failure.dart`); lỗi ghi hay đọc database đi theo mô hình
lỗi của ADR-016.

Xoá một deck hay một card là đưa nó vào Trash dưới dạng một **batch**, và hoàn tác ngay sau đó trả
batch về chỗ cũ; hai việc đó là chức năng của feature deck và card. Các chức năng ở đây là của
chính Trash. Một batch ở trong Trash 30 ngày (720 giờ); quá hạn thì nó bị xoá vĩnh viễn. Mỗi thao
tác khôi phục hay xoá vĩnh viễn nhận các batch **cùng một loại** — toàn deck hoặc toàn card.

## FN-TRASH-001 — Dọn các batch đã hết hạn
Status: active · Code: [lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart, lib/features/trash/domain/models/purge_report_model.dart]

### Precondition

Không có. Chạy lúc app khởi động, khi app trở lại, khi Trash được mở và khi nó được focus lại.

### Input

Không có. Thời điểm hiện tại đến từ đồng hồ của app.

### Kết quả

Trong một transaction, mọi batch đã ở Trash từ 720 giờ trở lên bị xoá vĩnh viễn cùng mọi thứ gắn
với chúng — nội dung, lịch học và lịch sử ôn tập của các card trong đó. Batch cũ hơn nằm bên trong
một deck đi trước, nên một deck chỉ chặn được việc dọn khi bên trong nó còn batch **chưa** hết hạn;
deck đó được bỏ qua nguyên vẹn. Kết quả là báo cáo: các batch đã xoá, và các batch bị bỏ qua cùng
batch đang chặn chúng.

### Lỗi

- Ghi database thất bại: rollback, không batch nào bị xoá.

### Business rules

- BR-TRASH-009
- BR-TRASH-010

## FN-TRASH-002 — Xem Trash
Status: active · Code: [lib/features/trash/domain/usecases/watch_trash_use_case.dart, lib/features/trash/domain/entities/trash_entry_entity.dart]

### Precondition

Không có. Trash rỗng là một kết quả hợp lệ.

### Input

Không có.

### Kết quả

Một stream các batch đang ở Trash, mới xoá nhất trước, phát lại sau mỗi thay đổi. Mỗi batch mang
thời điểm bị xoá, thời điểm sẽ bị xoá vĩnh viễn, và đường dẫn các deck nó từng nằm trong, từ root
xuống — **chỉ là thông tin**, không phải nơi nó sẽ được khôi phục về. Batch deck mang tên deck, deck
đó có phải root không, số deck con và số card đi cùng trong batch; một batch cũ hơn nằm bên trong là
một mục riêng, không được đếm vào. Batch card mang mặt trước và mặt sau.

Việc xem không dọn gì: dọn batch hết hạn là việc của FN-TRASH-001, chạy trước. Không ghi gì.

### Lỗi

- Đọc database thất bại: stream báo lỗi.

### Business rules

- BR-CORE-001
- BR-TRASH-003
- BR-TRASH-009
- BR-TRASH-012

## FN-TRASH-003 — Xem các đích khôi phục của deck
Status: active · Code: [lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart, lib/features/deck/domain/models/deck_restore_targets_model.dart]

### Precondition

Không có.

### Input

- Một hoặc nhiều batch deck.

### Kết quả

Một stream, phát lại khi cây deck đổi, là một trong hai:

- **Cấp gốc** — mọi deck được chọn đều là root: root chỉ về được cấp gốc.
- **Dưới một deck** — mọi deck được chọn đều là deck con: các deck đang active nhận được **tất cả**
  chúng, theo đúng điều kiện của việc di chuyển deck — độ sâu tối đa của cây, deck đích chứa deck
  chứ không chứa card, và root của đích cùng scheduler và cùng generation với root của deck được
  khôi phục. Danh sách rỗng khi không có đích nào, khi lựa chọn trộn root với deck con, hoặc khi một
  batch không còn.

Không ghi gì.

### Lỗi

- Đọc database thất bại: stream báo lỗi.

### Business rules

- BR-DECK-001
- BR-DECK-009
- BR-DECK-010
- BR-DECK-017
- BR-DECK-018
- BR-SRS-006
- BR-TRASH-006

## FN-TRASH-004 — Xem các đích khôi phục của card
Status: active · Code: [lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart]

### Precondition

Không có.

### Input

- Một hoặc nhiều batch card.

### Kết quả

Một stream các deck đang active, mỗi deck kèm đường dẫn, mà các card được chọn về được: deck không
phải root, chứa card hoặc chưa chứa gì, và cùng root với các card đó. Phát lại khi cây deck đổi.
Không ghi gì.

### Lỗi

- Đọc database thất bại: stream báo lỗi.

### Business rules

- BR-CARD-010
- BR-TRASH-006

## FN-TRASH-005 — Khôi phục deck từ Trash
Status: active · Code: [lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart]

### Precondition

Người dùng đã chọn đích và xác nhận; vị trí cũ không bao giờ được chọn tự động.

### Input

- Một hoặc nhiều batch deck.
- Deck cha đích, hoặc không có để về cấp gốc.

### Kết quả

Trong một transaction, tất cả hoặc không batch nào: mỗi batch hồi sinh **đúng** những hàng mang
batch đó — không hàng nào của batch khác — với nguyên id, nội dung, trạng thái học, lịch sử và tag.
Root về cấp gốc, ở cuối các deck cùng cấp. Deck con vào dưới deck đích, ở cuối các deck con của
nó, và `root_id` của cả cây con — kể cả các batch cũ hơn còn nằm bên trong — được viết lại theo
root mới; loại nội dung của deck đích được cập nhật theo.

### Lỗi

- `notFound` — một batch không còn (đã bị xoá vĩnh viễn ở nơi khác).
- `rootRestoresToTopLevel` — có root mà đích là một deck.
- `subDeckNeedsParent` — có deck con mà đích là cấp gốc.
- `targetInTrash`, `targetNotFound` — deck đích đang ở Trash hoặc không còn.
- `notADeckContainer`, `depthExceeded`, `subtreeSchedulerMismatch` — deck đích không nhận được
  deck được khôi phục, như khi di chuyển deck; điều này có thể xảy ra khi cây đổi sau khi đích được
  chọn.

Mọi lỗi và lỗi ghi database: không gì được ghi.

### Business rules

- BR-DECK-001
- BR-DECK-009
- BR-DECK-010
- BR-DECK-015
- BR-DECK-017
- BR-DECK-018
- BR-SRS-006
- BR-TRASH-006
- BR-TRASH-007
- BR-TRASH-011

## FN-TRASH-006 — Khôi phục card từ Trash
Status: active · Code: [lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart]

### Precondition

Người dùng đã chọn đích và xác nhận; vị trí cũ không bao giờ được chọn tự động.

### Input

- Một hoặc nhiều batch card.
- Deck đích.

### Kết quả

Trong một transaction, tất cả hoặc không batch nào: mỗi card trở lại, vào deck đích, với nguyên id,
nội dung, trạng thái học, lịch sử, cờ và tag. Deck đích chưa chứa gì thì thành deck chứa card.

### Lỗi

- `notFound` — một batch không còn.
- `targetInTrash`, `targetNotFound` — deck đích đang ở Trash hoặc không còn.
- `targetIsRoot` — deck đích là root.
- `targetHoldsDecks` — deck đích chứa deck con.
- `crossRootMove` — card và deck đích thuộc hai root khác nhau.

Mọi lỗi và lỗi ghi database: không card nào trở lại.

### Business rules

- BR-CARD-010
- BR-DECK-015
- BR-TRASH-006
- BR-TRASH-007
- BR-TRASH-011

## FN-TRASH-007 — Xoá vĩnh viễn khỏi Trash
Status: active · Code: [lib/features/trash/domain/usecases/purge_trash_use_case.dart, lib/features/trash/domain/models/purge_report_model.dart]

### Precondition

Người dùng đã xác nhận, biết đúng số mục và biết lịch sử học không khôi phục được.

### Input

- Một hoặc nhiều batch cùng loại.

### Kết quả

Trong một transaction, các batch được chọn — cùng mọi batch đã hết hạn — bị xoá vĩnh viễn cùng mọi
thứ gắn với chúng. Một batch deck mà bên trong còn một batch khác không được chọn và chưa hết hạn
bị bỏ qua **nguyên vẹn**, không xoá một phần. Kết quả là báo cáo: các batch đã xoá, các batch bị bỏ
qua cùng batch đang chặn chúng, và các batch được chọn đã không còn.

### Lỗi

- Ghi database thất bại: rollback, dữ liệu giữ nguyên như trước.

### Business rules

- BR-TRASH-009
- BR-TRASH-010
- BR-TRASH-011
