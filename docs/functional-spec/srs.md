# SRS — functional specification

Các chức năng của feature srs. Định dạng: [docs/README.md](../README.md), mục "UC, FN và screen
spec". Lỗi là các giá trị của `SrsRejection`
(`lib/features/srs/domain/failures/srs_failure.dart`); lỗi ghi hay đọc database đi theo mô hình
lỗi của ADR-016.

## FN-SRS-001 — Xem những gì đặt lại tiến độ học sẽ xoá
Status: active · Code: [lib/features/srs/domain/usecases/get_reset_learning_summary_use_case.dart, lib/features/srs/domain/models/reset_learning_summary_model.dart]

### Precondition

Root deck tồn tại và đang active.

### Input

- Root deck.

### Kết quả

Các dữ kiện cho bước xác nhận: chế độ ôn tập cây đang chạy, cây đã khoá chế độ hay chưa, số card
của cây, và cây đã có gì để mất hay chưa (một cây chưa từng học vẫn đặt lại được, nhưng không mất
gì). Những gì **giữ nguyên** — deck, toàn bộ cây deck con, card, media, tag, mọi nội dung, và lịch
sử ôn tập cũ — và những gì **mất** — lịch ôn hiện tại, ngày đến hạn, box / ease factor / interval,
trạng thái thành thạo, phiên đang dở, và dấu đã học xong lần đầu — là hai danh sách cố định mà
người dùng phải được cho biết trước khi xác nhận. Không ghi gì.

### Lỗi

- `notFound` — root không tồn tại hoặc đang ở Trash.
- `notARootDeck` — deck là deck con: chỉ root mới đặt lại được.

### Business rules

- BR-DECK-024
- BR-SRS-003
- BR-SRS-030

## FN-SRS-002 — Đặt lại tiến độ học của một cây
Status: active · Code: [lib/features/srs/domain/usecases/reset_learning_progress_use_case.dart]

### Precondition

Root deck tồn tại và đang active.

### Input

- Root deck.
- Chế độ ôn tập mới; không có nghĩa là giữ chế độ đang chạy.

### Kết quả

Trong **một** transaction:

- `generation` của root tăng đúng 1;
- `scheduler_type` / `version` / `config` mới nếu một chế độ mới được chọn;
- `first_answered_at = NULL`: chế độ ôn tập mở khoá lại;
- study state của **toàn bộ** card trong cây, ở mọi cấp, khởi tạo lại theo scheduler và
  generation mới: mọi thẻ trở lại tập New (`learned_at` và `due_at` về NULL), không thuộc tập
  Due;
- mọi phiên `in_progress` của cây thành `invalidated`, `end_reason = scheduler_reset`, `ended_at`
  được đặt; lượt trả lời kế tiếp của phiên đó bị từ chối, các lượt đã ghi trước vẫn giữ;
- `review_log` **không** đổi: các dòng cũ giữ generation cũ;
- `content_type` và cấu trúc cây **không** đổi.

Đặt lại mà giữ chế độ đang chạy vẫn tăng `generation` và vẫn khởi tạo lại study state. Các cây
khác không đổi gì. Sau đó mọi study state của cây cùng scheduler và generation với root.

### Lỗi

- `notFound` — root không tồn tại hoặc đang ở Trash; không ghi gì.
- `notARootDeck` — deck là deck con; không ghi gì.
- Thất bại giữa chừng — rollback: root giữ `generation`, chế độ, study state và trạng thái phiên
  cũ; không có card nào thuộc hai generation.

### Business rules

- BR-CARD-004
- BR-DECK-024
- BR-SRS-020
- BR-SRS-021
- BR-SRS-022
- BR-SRS-023
- BR-SRS-024
- BR-SRS-025
- BR-SRS-026
- BR-SRS-027
- BR-SRS-028
- BR-SRS-029
- BR-STUDY-015
- BR-STUDY-017
- BR-STUDY-050
- BR-STUDY-051
