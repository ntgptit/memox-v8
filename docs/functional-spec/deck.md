# Deck — functional specification

Các chức năng của feature deck. Định dạng: [docs/README.md](../README.md), mục "UC, FN và
screen spec". Lỗi là các giá trị của `DeckRejection`
(`lib/features/deck/domain/failures/deck_failure.dart`) hoặc `SrsRejection`
(`lib/features/srs/domain/failures/srs_failure.dart`); lỗi ghi database đi theo mô hình lỗi
của ADR-016.

## FN-DECK-001 — Tạo root deck
Status: active · Code: [lib/features/deck/domain/usecases/create_root_deck_use_case.dart]

### Precondition

Không có.

### Input

- Tên deck.
- Chế độ ôn tập: `eight_box` hoặc `sm2`. Bắt buộc, không có giá trị mặc định ngầm.

### Kết quả

Trong một transaction, một root deck mới với `parent_id = NULL`, `root_id = id`,
`content_type = 'deck'` (bất biến), `generation = 1`, `first_answered_at = NULL` và chế độ ôn
tập đã chọn. Tên được lưu sau khi trim. Tên trùng với deck khác được chấp nhận. Deck còn sau khi
khởi động lại app.

### Lỗi

- `blankName` — tên rỗng hoặc chỉ có khoảng trắng.
- `nameTooLong` — tên dài hơn 200 ký tự sau khi trim.
- Ghi database thất bại — transaction rollback, không tạo gì (ADR-016).

### Business rules

- BR-DECK-002
- BR-DECK-004
- BR-DECK-020
- BR-DECK-021
- BR-SRS-001

## FN-DECK-002 — Đổi tên deck
Status: active · Code: [lib/features/deck/domain/usecases/rename_deck_use_case.dart]

### Precondition

Deck tồn tại và đang active.

### Input

- Deck.
- Tên mới.

### Kết quả

Tên đã trim được lưu và `updated_at` cập nhật.

### Lỗi

- `blankName` — tên rỗng hoặc chỉ có khoảng trắng.
- `nameTooLong` — tên dài hơn 200 ký tự sau khi trim.
- `notFound` — deck đã bị xoá ở nơi khác; không ghi gì.

### Business rules

- BR-DECK-020
- BR-DECK-021

## FN-DECK-003 — Đổi chế độ ôn tập của root deck
Status: active · Code: [lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart]

### Precondition

Deck là root deck và chưa có thẻ nào của cây hoàn tất chuỗi học mới
(`first_answered_at IS NULL`). Hệ thống đọc lại điều kiện này **bên trong** transaction; trạng
thái đang vẽ trên màn hình không quyết định thao tác có hợp lệ hay không.

### Input

- Root deck.
- Chế độ ôn tập mới.

### Kết quả

Trong một transaction: scheduler đổi, study state của toàn bộ card trong cây được khởi tạo lại
theo chế độ mới, `generation` giữ nguyên, `first_answered_at` vẫn NULL, và mọi phiên đang mở của
cây đóng với `end_reason = 'scheduler_changed'`. Đây không phải Reset learning progress: không
generation nào bị tiêu, không lịch sử nào bị bỏ.

Chọn lại đúng chế độ deck đang chạy, khoá hay chưa khoá: thao tác được chấp nhận và không ghi
gì — không seed lại cây, không đóng phiên đang mở.

### Lỗi

- `schedulerLocked` — cây đã khoá (đọc lại trong transaction); không đổi gì.
- `notARootDeck` — deck là deck con: scheduler sống ở root.
- `notFound` — deck không còn.
- Thất bại giữa chừng — rollback; deck giữ scheduler cũ và study state cũ.

### Business rules

- BR-DECK-025
- BR-SRS-002
- BR-SRS-003
- BR-SRS-004
- BR-STUDY-016

## FN-DECK-004 — Xem số deck con và card sẽ vào Trash cùng deck
Status: active · Code: [lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart]

### Precondition

Deck tồn tại và đang active.

### Input

- Deck.

### Kết quả

Số deck con active và số card active bên dưới deck, những thứ sẽ vào Trash cùng nó. Không ghi gì.

### Lỗi

- `notFound` — deck không còn.

### Business rules

- BR-DECK-023

## FN-DECK-005 — Chuyển deck và cây con vào Trash
Status: active · Code: [lib/features/deck/domain/usecases/delete_deck_use_case.dart]

### Precondition

Deck tồn tại và đang active.

### Input

- Deck.

### Kết quả

Trong một transaction:

- deck cùng mọi deck con và card còn active bên dưới vào Trash thành **một** batch, cùng một
  `deleted_at`; tombstone đã có sẵn bên trong giữ batch cũ của nó;
- phiên `in_progress` chạm tới batch đóng với `status = invalidated`,
  `end_reason = content_deleted`;
- nếu deck cha là sub-deck và vừa mất phần tử con active cuối cùng, `content_type` của nó về
  `unset`; deck cha là root thì giữ `deck`.

Không bề mặt active nào còn hiện các hàng của batch. Nội dung, study state, study answers, id
và chỗ cũ của từng hàng giữ nguyên tới khi purge; chỉ purge mới xoá hẳn, theo cascade. Kết quả
trả về id của batch, thứ mà FN-DECK-006 nhận.

### Lỗi

- `notFound` — deck đã bị xoá ở nơi khác; không ghi gì.
- Thất bại giữa chừng — rollback; deck còn nguyên và `content_type` của deck cha không đổi.

### Business rules

- BR-DECK-004
- BR-DECK-015
- BR-DECK-022
- BR-TRASH-001
- BR-TRASH-002
- BR-TRASH-003
- BR-TRASH-004
- BR-TRASH-005
- BR-TRASH-010

## FN-DECK-006 — Hoàn tác xoá deck
Status: active · Code: [lib/features/deck/domain/usecases/undo_deck_deletion_use_case.dart]

### Precondition

Batch do FN-DECK-005 tạo còn trong Trash.

### Input

- Id của batch.

### Kết quả

Trong một transaction, deck cùng mọi phần tử của batch trở lại đúng chỗ cũ: dưới deck cha cũ, ở
vị trí sibling cũ (vị trí đó không bị ai chiếm, vì sibling mới đếm cả tombstone). Một root deck
trở lại cấp gốc.

### Lỗi

- `notFound` — batch không còn.
- `targetNotFound` — deck cha cũ không còn.
- `targetInTrash` — deck cha cũ đang ở Trash.
- `movingIntoOwnSubtree` — deck cha cũ nay nằm trong cây con của chính deck này.
- `notADeckContainer` — deck cha cũ nay chứa card.
- `depthExceeded` — trở lại dưới deck cha cũ sẽ vượt độ sâu tối đa.
- `subtreeSchedulerMismatch` — root của deck cha cũ nay khác scheduler hoặc generation.

### Business rules

- BR-DECK-001
- BR-DECK-009
- BR-DECK-017
- BR-SRS-006
- BR-TRASH-006
- BR-TRASH-008

## FN-DECK-007 — Xem một cấp của thư viện kèm tiến độ
Status: active · Code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/features/deck/domain/models/deck_level_model.dart, lib/features/deck/domain/models/deck_level_query_model.dart]

### Precondition

Không có.

### Input

- Deck cha của cấp; không có nghĩa là cấp gốc (các root deck).
- Cách sắp xếp: Manual (mặc định), Newest, Name, Most due hoặc Progress. Mọi cách sắp xếp kết
  thúc bằng thứ tự thủ công. Progress xếp mastery tăng dần, deck không có card đứng cuối.
- Bộ lọc: tất cả, hoặc chỉ deck có thẻ đến hạn.

### Kết quả

Một luồng dữ liệu, phát lại mỗi khi dữ liệu đổi và mỗi nửa đêm theo giờ local (khi Due today
thành Overdue mà không có lần ghi nào). Mỗi lần phát chỉ chạy **một** câu lệnh gộp theo
`root_id`, không phải một câu mỗi deck và không duyệt cây trong Dart, kể cả khi cây sâu nhiều
cấp. Với mỗi deck của cấp:

- tên, tổng số card trong cây, chế độ ôn tập đang dùng;
- hai số tách biệt, không bao giờ gộp: card chưa học (New) và card đến hạn (Due), với Due bằng
  Overdue cộng Due today. Hai tập này khớp hệt tập mà phiên học dùng, qua cùng một named query;
- trạng thái lịch: chưa đến hạn, đến hạn hôm nay, hoặc quá hạn kèm số ngày;
- mastery: số card `mastered` trên mọi card active của cây; card ở Trash không tính ở cả tử số
  lẫn mẫu số; deck không có card không có tỉ lệ.

Cùng với đó là tóm tắt của cấp: bốn tập rời nhau Overdue, Due today, New, Scheduled; Scheduled
là tập trung tính, không actionable. Không có deck nào có thẻ đến hạn là trạng thái bình thường,
không phải lỗi. Không ghi gì.

### Lỗi

- Đọc database thất bại — luồng báo lỗi; đọc lại khi được yêu cầu (ADR-016).

### Business rules

- BR-DECK-002
- BR-DECK-003
- BR-DECK-026
- BR-DECK-027
- BR-STUDY-008
- BR-STUDY-046
- BR-STUDY-051
- BR-STUDY-067
- BR-STUDY-068

## FN-DECK-008 — Xem một deck đang mở
Status: active · Code: [lib/features/deck/domain/usecases/watch_deck_use_case.dart]

### Precondition

Không có.

### Input

- Deck.

### Kết quả

Một luồng dữ liệu, phát lại mỗi khi dữ liệu đổi:

- nội dung theo `content_type`: danh sách deck con, hoặc danh sách card, không bao giờ cả hai;
- các lựa chọn tạo phần tử con:

  | Deck | Lựa chọn |
  |---|---|
  | root deck (`content_type = 'deck'`, bất biến) | chỉ tạo deck con |
  | deck con, `content_type = 'unset'` | tạo card và tạo deck con |
  | deck con, `content_type = 'card'` | chỉ tạo card |
  | deck con, `content_type = 'deck'` | chỉ tạo deck con |

  Deck ở cấp 10 không có lựa chọn tạo deck con;
- trạng thái khoá chế độ ôn tập của root;
- breadcrumb từ thư viện tới deck.

### Lỗi

- `notFound` — deck không còn, kể cả khi nó vừa bị xoá trong lúc đang mở.

### Business rules

- BR-DECK-001
- BR-DECK-004
- BR-DECK-005
- BR-DECK-007
- BR-DECK-009
- BR-DECK-010
- BR-DECK-011
- BR-DECK-012
- BR-SRS-003

## FN-DECK-009 — Tạo deck con
Status: active · Code: [lib/features/deck/domain/usecases/create_sub_deck_use_case.dart]

### Precondition

Deck cha tồn tại, đang active, chứa deck con hoặc chưa chứa gì.

### Input

- Deck cha.
- Tên deck con.

### Kết quả

Trong một transaction:

- nếu deck cha đang `unset`, nó thành `content_type = 'deck'`;
- deck con mới ở cuối danh sách deck con của cha, với `content_type = 'unset'`,
  `parent_id` là deck cha, `root_id` là root của deck cha, và không có cột scheduler (nó theo
  scheduler của root).

`content_type` của deck cha chỉ đổi cùng với việc deck con thực sự được tạo.

### Lỗi

- `blankName` — tên rỗng hoặc chỉ có khoảng trắng.
- `nameTooLong` — tên dài hơn 200 ký tự sau khi trim.
- `notFound` — deck cha không còn.
- `notADeckContainer` — deck cha đã chứa card.
- `depthExceeded` — deck cha đã ở cấp 10; chặn trước khi ghi.
- Mọi lỗi trên và lỗi ghi database: không tạo gì và `content_type` của deck cha không đổi, kể cả
  khi nó đang `unset`.

### Business rules

- BR-DECK-001
- BR-DECK-002
- BR-DECK-006
- BR-DECK-008
- BR-DECK-009
- BR-DECK-011
- BR-DECK-019
- BR-DECK-020
- BR-DECK-024
- BR-DECK-025

## FN-DECK-010 — Xem các đích di chuyển hợp lệ
Status: active · Code: [lib/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart]

### Precondition

Deck là deck con đang active. Root deck không có đích nào.

### Input

- Deck sẽ di chuyển.

### Kết quả

Một luồng các deck active, mỗi deck kèm đường dẫn, mà deck này có thể chuyển vào: cùng scheduler
và generation với root của nó, nằm ngoài cây con của nó, chứa deck con hoặc chưa chứa gì, và đủ
nông cho chiều cao cây con. Deck cha hiện tại có mặt như một bước của đường dẫn nhưng không là
đích.

### Lỗi

Không áp dụng — một deck không còn hoặc là root cho danh sách rỗng.

### Business rules

- BR-DECK-001
- BR-DECK-009
- BR-DECK-017
- BR-DECK-024

## FN-DECK-011 — Di chuyển deck trong cây
Status: active · Code: [lib/features/deck/domain/usecases/move_deck_use_case.dart]

### Precondition

Deck nguồn là deck con active; deck đích tồn tại và đang active.

### Input

- Deck nguồn.
- Deck đích (deck cha mới).

### Kết quả

Hệ thống kiểm, theo thứ tự: đích không phải chính deck nguồn hoặc descendant của nó; đích có
`content_type = 'deck'` hoặc `'unset'`; độ sâu sau khi di chuyển không vượt 10 (với cấp của
đích, root là cấp 1, cộng chiều cao cây con nguồn, deck nguồn tính là 1); root của đích có cùng
`scheduler_type` và `generation` với root của nguồn. Hợp lệ thì, trong một transaction:

- `parent_id` của deck nguồn thành deck đích, deck nguồn ở cuối danh sách deck con của đích;
- `root_id` và `depth` của **toàn bộ** cây con được cập nhật (trong cùng một cây, `root_id`
  không đổi);
- đích đang `unset` thành `content_type = 'deck'`;
- deck cha cũ là sub-deck vừa mất phần tử con cuối cùng về `unset`; cha cũ là root hoặc còn
  sibling giữ `deck`.

Sau đó cây không có cycle, mọi deck của cây con trỏ đúng root, không deck nào vừa chứa card vừa
chứa deck con, và không study state nào lệch scheduler hay generation của root. Không có chuyển
đổi study state ngầm giữa hai chế độ ôn tập.

### Lỗi

- `rootCannotMove` — deck nguồn là root: đưa một deck lên hay xuống vị trí root nằm ngoài phạm
  vi.
- `sameParent` — đích đã là deck cha hiện tại.
- `movingIntoOwnSubtree` — đích là chính nó hoặc descendant.
- `notADeckContainer` — đích chỉ chứa card.
- `depthExceeded` — vượt độ sâu tối đa; chặn trước khi ghi, không `parent_id`, `root_id`,
  `content_type` hay timestamp nào đổi.
- `subtreeSchedulerMismatch` — root của đích khác scheduler hoặc generation; đề nghị đặt lại tiến
  độ học một cách tường minh.
- `notFound` — deck nguồn hoặc đích không còn.
- Thất bại giữa chừng — rollback: con trỏ cha, `root_id` của cả cây con, `content_type` của đích
  và của cha cũ trở lại như trước.

### Business rules

- BR-DECK-001
- BR-DECK-002
- BR-DECK-008
- BR-DECK-010
- BR-DECK-011
- BR-DECK-015
- BR-DECK-016
- BR-DECK-017
- BR-DECK-018
- BR-DECK-019
- BR-SRS-005
- BR-SRS-006
- BR-SRS-028
- BR-SRS-029

## FN-DECK-012 — Sắp xếp lại deck cùng cấp
Status: active · Code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart]

### Precondition

Deck và deck mốc là hai deck active cùng một deck cha (hoặc cùng là root deck).

### Input

- Deck cần đổi chỗ.
- Deck mốc: sibling liền trước hoặc liền sau theo thứ tự Manual đã lưu.
- Vị trí: `before` hoặc `after` deck mốc. Không nhận một index database thô.

### Kết quả

Trong một transaction, hệ thống đọc lại hai deck, xác nhận chúng còn cùng `parent_id`, rồi đánh
số lại nhóm sibling. Chỉ `sibling_position` (và `updated_at` của các sibling được đánh số lại)
đổi; mọi `parent_id`, `root_id`, scheduler, card, study state và cây con giữ nguyên.

### Lỗi

- `notFound` — deck hoặc deck mốc không còn; không ghi gì.
- `notSiblings` — hai deck không còn cùng deck cha; không ghi gì.
- Lỗi database ở bất kỳ lần cập nhật nào — rollback toàn bộ, thứ tự cũ giữ nguyên.

### Business rules

- BR-DECK-002
- BR-SRS-007
