# Card — functional specification

Các chức năng của feature card. Định dạng: [docs/README.md](../README.md), mục "UC, FN và
screen spec". Lỗi là các giá trị của `CardRejection`
(`lib/features/card/domain/failures/card_failure.dart`) hoặc `TagRejection`
(`lib/features/tags/domain/failures/tag_failure.dart`); lỗi ghi hay đọc database đi theo mô hình
lỗi của ADR-016.

## FN-CARD-001 — Xem danh sách card của một deck
Status: active · Code: [lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/models/card_list_query_model.dart, lib/features/card/domain/models/card_list_view_model.dart]

### Precondition

Deck tồn tại và có `content_type = 'card'`.

### Input

- Deck.
- Bộ lọc: tất cả, đến hạn, chưa học (New), hoặc có cờ.
- Cách sắp xếp: mới nhất trước, hoặc sắp đến hạn trước (thẻ New ở cuối).
- Từ khoá tìm kiếm, gập trước khi so khớp; từ khoá trống không loại thẻ nào.
- Tập tag: một thẻ qua khi mang **bất kỳ** tag nào trong tập (OR); tập rỗng cho mọi thẻ qua.
- Kích thước cửa sổ: số hàng muốn tải.

### Kết quả

Một luồng dữ liệu, phát lại mỗi khi dữ liệu đổi và mỗi nửa đêm theo giờ local (khi thẻ tới hạn
mà không có lần ghi nào). Mỗi lần phát gồm:

- một cửa sổ các thẻ khớp query, mỗi thẻ có mặt trước, mặt sau, cờ, ngày tới hạn (không có với
  thẻ chưa học), trạng thái hiển thị, khi nào thẻ quay lại, và các tag;
- số thẻ mà mỗi bộ lọc sẽ cho dưới từ khoá và tập tag hiện tại: tất cả, đến hạn, New, có cờ.
  "Đến hạn" và "New" dùng đúng định nghĩa mà các con số New/Due ở nơi khác dùng.

Mỗi bộ deck, bộ lọc, cách sắp xếp, từ khoá và tập tag là một query riêng: đổi một trong số đó thì
người gọi đọc lại từ cửa sổ đầu, và kết quả của query cũ không bao giờ thay kết quả của query hiện
tại. Không ghi gì.

### Lỗi

- Đọc database thất bại — luồng báo lỗi (ADR-016).

### Business rules

- BR-CARD-006
- BR-CARD-007
- BR-CARD-008
- BR-CARD-009
- BR-TAG-001
- BR-TAG-004
- BR-TAG-005
- BR-STUDY-047
- BR-STUDY-068

## FN-CARD-002 — Tạo card
Status: active · Code: [lib/features/card/domain/usecases/create_card_use_case.dart, lib/features/card/domain/models/card_draft_model.dart]

### Precondition

Deck tồn tại, là deck con, và chứa card hoặc chưa chứa gì.

### Input

- Deck.
- Bản nháp: mặt trước, mặt sau; tuỳ chọn ví dụ, gợi ý, phiên âm; cờ; tên các tag.

### Kết quả

Trong một transaction:

- nếu deck đang `unset`, nó thành `content_type = 'card'`;
- card mới được tạo **cùng** study state của nó, theo scheduler của root deck (tra qua
  `root_id`) và generation hiện tại; card không bao giờ tồn tại mà thiếu study state;
- các tag được gắn theo tên: dùng lại tag có cùng tên đã gập, tạo mới nếu chưa có.

Card mới là New; số thẻ của deck và của cây tăng theo.

### Lỗi

- `blankContent` — mặt trước hoặc mặt sau rỗng sau khi trim.
- `frontTooLong` — mặt trước dài hơn 60 ký tự.
- `backTooLong` — mặt sau dài hơn 240 ký tự.
- `optionalFieldTooLong` — ví dụ, gợi ý hoặc phiên âm dài hơn 240 ký tự.
- `invalidTagName` — một tên tag không hợp lệ.
- `tooManyTags` — thẻ sẽ mang quá 10 tag.
- `notFound` — deck không còn.
- `notACardContainer` — deck là root hoặc đang chứa deck con.
- Mọi lỗi trên và lỗi ghi database: không ghi gì; `content_type` của deck không đổi.

### Business rules

- BR-CARD-001
- BR-CARD-002
- BR-CARD-003
- BR-CARD-004
- BR-CARD-009
- BR-DECK-004
- BR-DECK-008
- BR-DECK-009
- BR-DECK-010
- BR-TAG-001
- BR-TAG-002

## FN-CARD-003 — Sửa card
Status: active · Code: [lib/features/card/domain/usecases/edit_card_use_case.dart, lib/features/card/domain/models/card_draft_model.dart]

### Precondition

Card tồn tại và đang active.

### Input

- Card.
- Bản nháp mới: như khi tạo card.

### Kết quả

Nội dung, cờ và tag của card đổi theo bản nháp và `updated_at` cập nhật. Study state và lịch sử
học (`review_log`) **không** đổi.

### Lỗi

- `blankContent`, `frontTooLong`, `backTooLong`, `optionalFieldTooLong`, `invalidTagName`,
  `tooManyTags` — như các giới hạn của bản nháp khi tạo card.
- `notFound` — card không còn; không ghi gì.

### Business rules

- BR-CARD-001
- BR-CARD-002
- BR-CARD-003
- BR-CARD-005
- BR-CARD-009
- BR-TAG-001
- BR-TAG-002

## FN-CARD-004 — Chuyển card vào Trash
Status: active · Code: [lib/features/card/domain/usecases/delete_cards_use_case.dart]

### Precondition

Mọi card được chọn tồn tại và đang active.

### Input

- Một hoặc nhiều card.

### Kết quả

Trong một transaction, tất cả hoặc không card nào:

- mỗi card vào Trash thành **một** batch của riêng nó, cùng một `deleted_at`;
- nội dung, study state và lịch sử giữ nguyên tới khi purge;
- phiên `in_progress` có card trong hàng đợi, hoặc dùng card làm lựa chọn của một câu `guess`,
  kết thúc với `content_deleted`;
- deck mất card active cuối cùng về `content_type = 'unset'`.

Kết quả trả về id của các batch, thứ mà FN-CARD-005 nhận.

### Lỗi

- `notFound` — một card không còn; không card nào được chuyển.
- Lỗi ghi database — rollback, không card nào được chuyển.

### Business rules

- BR-CARD-011
- BR-DECK-015
- BR-TRASH-001
- BR-TRASH-004
- BR-TRASH-005

## FN-CARD-005 — Hoàn tác xoá card
Status: active · Code: [lib/features/card/domain/usecases/undo_card_deletion_use_case.dart]

### Precondition

Batch do FN-CARD-004 tạo cho đúng một card còn trong Trash.

### Input

- Id của batch.

### Kết quả

Card trở lại deck của nó, cùng nội dung, study state và lịch sử; deck đang `unset` lại thành
`card`.

### Lỗi

- `notFound` — batch hoặc card không còn.
- `targetNotFound` — deck của card không còn.
- `targetInTrash` — deck của card đang ở Trash.
- `targetIsRoot`, `targetHoldsDecks` — deck nay không còn nhận card.

### Business rules

- BR-CARD-010
- BR-DECK-015
- BR-TRASH-006
- BR-TRASH-008

## FN-CARD-006 — Xem các deck đích để di chuyển card
Status: active · Code: [lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart]

### Precondition

Deck nguồn tồn tại.

### Input

- Deck nguồn.

### Kết quả

Một luồng các deck active, mỗi deck kèm đường dẫn, mà card của deck nguồn có thể chuyển vào: cùng
root, không phải root, không chứa deck con, và không phải chính deck nguồn.

### Lỗi

Không áp dụng — deck nguồn không còn cho danh sách rỗng.

### Business rules

- BR-CARD-010

## FN-CARD-007 — Di chuyển card sang deck khác
Status: active · Code: [lib/features/card/domain/usecases/move_cards_use_case.dart]

### Precondition

Mọi card được chọn tồn tại và đang active.

### Input

- Một hoặc nhiều card.
- Deck đích.

### Kết quả

Trong một transaction, tất cả hoặc không card nào: mỗi card chỉ đổi `deck_id` và `updated_at`;
id, nội dung, study state, lịch sử, cờ và tag giữ nguyên. Deck nguồn mất card cuối về `unset`;
deck đích đang `unset` thành `card`.

### Lỗi

- `notFound` — một card không còn.
- `targetNotFound` — deck đích không còn.
- `targetIsRoot` — deck đích là root.
- `targetHoldsDecks` — deck đích chứa deck con.
- `sameDeck` — một card đã ở trong deck đích.
- `crossRootMove` — card và deck đích thuộc hai root khác nhau.
- Mọi lỗi trên và lỗi ghi database: không card nào được chuyển.

### Business rules

- BR-CARD-010
- BR-CARD-011
- BR-DECK-015

## FN-CARD-008 — Chọn mọi card khớp danh sách
Status: active · Code: [lib/features/card/domain/usecases/select_all_card_ids_use_case.dart]

### Precondition

Deck tồn tại.

### Input

- Deck.
- Query hiện tại của danh sách: bộ lọc, từ khoá, tập tag.

### Kết quả

Id của **mọi** card khớp query, không chỉ các hàng đã tải. Danh sách, các con số và lựa chọn này
đọc cùng một query. Không ghi gì.

### Lỗi

Không áp dụng — không có card khớp cho tập rỗng.

### Business rules

- BR-CARD-012

## FN-CARD-009 — Bật hoặc bỏ cờ của card
Status: active · Code: [lib/features/card/domain/usecases/set_cards_flagged_use_case.dart]

### Precondition

Mọi card được chọn tồn tại và đang active.

### Input

- Một hoặc nhiều card.
- Giá trị cờ: bật hoặc bỏ.

### Kết quả

Trong một transaction, tất cả hoặc không card nào: `is_flagged` đúng giá trị trên mọi card; card
đã đúng giá trị không bị ghi lại.

### Lỗi

- `notFound` — một card không còn; không card nào đổi.

### Business rules

- BR-CARD-009
- BR-CARD-011

## FN-CARD-010 — Gắn tag cho card theo tên
Status: active · Code: [lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart]

### Precondition

Mọi card được chọn tồn tại và đang active.

### Input

- Một hoặc nhiều card.
- Tên tag.

### Kết quả

Trong một transaction, tất cả hoặc không card nào: dùng lại tag có cùng tên đã gập, hoặc tạo tag
mới, rồi gắn nó cho mọi card.

### Lỗi

- `blankName`, `nameTooLong`, `controlCharacter` — tên tag không hợp lệ.
- `tooManyTags` — một card sẽ mang quá 10 tag; không card nào được gắn.
- `notFound` — một card không còn.

### Business rules

- BR-CARD-011
- BR-TAG-001
- BR-TAG-002

## FN-CARD-011 — Gỡ tag khỏi card
Status: active · Code: [lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart]

### Precondition

Mọi card được chọn và tag tồn tại.

### Input

- Một hoặc nhiều card.
- Tag.

### Kết quả

Liên kết giữa tag và mọi card đó bị xoá trong một transaction; bản thân tag vẫn còn.

### Lỗi

- `notFound` — một card hoặc tag không còn; không liên kết nào bị xoá.

### Business rules

- BR-CARD-011
- BR-TAG-001

## FN-CARD-012 — Xem tag của thư viện kèm số card của một deck
Status: active · Code: [lib/features/card/domain/usecases/watch_card_tag_filter_use_case.dart]

### Precondition

Deck tồn tại.

### Input

- Deck.

### Kết quả

Một luồng mọi tag của thư viện, mỗi tag kèm số card active **của deck này** mang nó, kể cả 0 —
nguồn của bộ lọc tag trong danh sách card. Không ghi gì.

### Lỗi

- Đọc database thất bại — luồng báo lỗi (ADR-016).

### Business rules

- BR-TAG-001
- BR-TAG-004

## FN-CARD-013 — Xem chi tiết một card
Status: active · Code: [lib/features/card/domain/usecases/watch_card_detail_use_case.dart, lib/features/card/domain/models/card_detail_model.dart]

### Precondition

Không có.

### Input

- Card.

### Kết quả

Một luồng chi tiết của card, phát lại mỗi khi nó đổi:

- toàn bộ mặt trước, mặt sau, và ba trường tuỳ chọn `example`, `hint`, `pronunciation` khi có
  giá trị;
- trạng thái hiện tại: tag, cờ, trạng thái hiển thị, ngày tới hạn, lần trả lời gần nhất, số lượt
  đã trả lời, số lần quên, và các trường riêng của scheduler đang gắn với thẻ.

Việc xem chi tiết không ghi gì: nội dung, `updated_at`, study state, `learned_at`, lịch sử, cờ và
tag đều nguyên vẹn. Mở chi tiết là nghĩa của một lần chọn card khi không ở chế độ chọn nhiều.

### Lỗi

- `notFound` — card không tồn tại, hoặc bị xoá trong lúc đang xem; lý do có kiểu, không lộ id hay
  chi tiết kỹ thuật.
- Đọc database thất bại — lý do có kiểu (ADR-016), đọc lại được.

### Business rules

- BR-CARD-003
- BR-CARD-006
- BR-CARD-007
- BR-CARD-008
- BR-CARD-009
- BR-CARD-013
- BR-CARD-014
- BR-CARD-019
- BR-CARD-020
- BR-CORE-005
- BR-TAG-001

## FN-CARD-014 — Tải một trang lịch sử học của card
Status: active · Code: [lib/features/card/domain/usecases/load_card_history_page_use_case.dart, lib/features/card/domain/models/review_history_model.dart]

### Precondition

Không có.

### Input

- Card.
- Con trỏ keyset của trang trước; không có nghĩa là trang mới nhất.

### Kết quả

Một trang tối đa 50 event, mới nhất trước, theo con trỏ keyset: không lặp, không sót, kể cả khi
có câu trả lời mới được ghi giữa lúc phân trang. Event nhóm theo generation của scheduler,
generation hiện tại trên cùng; event của generation cũ còn nguyên sau một lần Reset. Mỗi event
nêu thời điểm, chế độ học, loại lượt, hành động đã ghi, lý do kết thúc và việc dùng gợi ý khi có,
cùng giá trị lịch trước và sau đúng như đã lưu trên hàng đó. Trang cuối cho biết đã hết. Card
chưa có lịch sử cho trang rỗng, không phải lỗi. Không ghi gì.

### Lỗi

- `notFound` — card không còn.
- Đọc database thất bại — lý do có kiểu (ADR-016); thử lại tiếp tục từ đúng con trỏ đó.

### Business rules

- BR-CARD-015
- BR-CARD-016
- BR-CARD-017
- BR-CARD-018
- BR-CORE-005
- BR-MODE-008
- BR-SRS-014
- BR-SRS-015
- BR-STUDY-028
- BR-STUDY-034
- BR-STUDY-035
- BR-STUDY-053
