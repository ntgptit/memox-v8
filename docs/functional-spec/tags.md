# Tags — functional specification

Các chức năng của feature tags. Định dạng: [docs/README.md](../README.md), mục "UC, FN và screen
spec". Lỗi là các giá trị của `TagRejection` (`lib/features/tags/domain/failures/tag_failure.dart`);
lỗi ghi hay đọc database đi theo mô hình lỗi của ADR-016.

Tag là nội dung của thư viện: danh tính của nó là tên đã gập (bỏ khoảng trắng hai đầu, không phân
biệt hoa thường), gập bằng đúng một hàm cho cả lúc ghi lẫn lúc tìm. Số card của một tag chỉ đếm
card đang active — card trong Trash không được tính. Thao tác trên tag chỉ đổi tag và liên kết
card–tag: nội dung, `updated_at`, cờ, lịch học, lịch sử và phiên của card không đổi.

Gắn và gỡ tag trên card, và nguồn của bộ lọc tag trong danh sách card, là chức năng của feature
card (functional-spec/card.md).

## FN-TAG-001 — Xem danh mục tag
Status: active · Code: [lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart, lib/features/tags/domain/models/tag_count_model.dart]

### Precondition

Không có. Thư viện chưa có tag nào là một kết quả hợp lệ.

### Input

- Từ cần tìm: trống thì giữ mọi tag.

### Kết quả

Một stream mọi tag của thư viện mà tên đã gập chứa từ cần tìm đã gập, mỗi tag kèm tên chuẩn đã lưu
và số card active mang nó, sắp theo tên đã gập rồi `id`. Phát lại sau mỗi thay đổi của tag hay liên
kết. Không ghi gì.

### Lỗi

- Đọc database thất bại: stream báo lỗi.

### Business rules

- BR-TAG-001
- BR-TAG-003
- BR-TAG-010
- BR-TAG-011

## FN-TAG-002 — Xem trước việc đổi tên một tag
Status: active · Code: [lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart, lib/features/tags/domain/models/tag_rename_plan_model.dart]

### Precondition

Không có.

### Input

- Tag.
- Tên mới.

### Kết quả

Việc đổi tên sẽ làm gì, đọc trong một transaction và trước mọi lần ghi:

- **Không đổi** — tên mới, sau khi bỏ khoảng trắng hai đầu, đúng là tên đang lưu.
- **Đổi tên** — không tag nào khác có cùng tên đã gập; đổi chỉ cách viết hoa của chính tag này cũng
  là đổi tên.
- **Gộp** — một tag khác có cùng tên đã gập: tag đích (tên và số card), và số card active riêng
  biệt sẽ mang tag đích sau khi gộp.

Không ghi gì.

### Lỗi

- `blankName` — tên rỗng sau khi bỏ khoảng trắng.
- `nameTooLong` — tên dài hơn 50 ký tự.
- `controlCharacter` — tên chứa ký tự điều khiển.
- `notFound` — tag không còn tồn tại.

### Business rules

- BR-TAG-001
- BR-TAG-006
- BR-TAG-007

## FN-TAG-003 — Đổi tên một tag
Status: active · Code: [lib/features/tags/domain/usecases/rename_tag_use_case.dart]

### Precondition

Không có.

### Input

- Tag.
- Tên mới.
- Tag đích đã được người dùng xác nhận gộp vào, khi có.

### Kết quả

Trong một transaction, việc đổi tên được xét lại trên dữ liệu hiện tại rồi:

- **Không đổi:** không ghi gì.
- **Đổi tên:** tên và tên đã gập mới ghi lên **chính tag đó**; `id` và mọi liên kết card giữ
  nguyên.
- **Gộp:** chỉ khi tag đích đúng là tag đã được xác nhận. Mọi card của tag nguồn chuyển sang tag
  đích, liên kết trùng được bỏ, rồi tag nguồn bị xoá. Không card nào vượt 10 tag, vì mỗi card đổi
  tag nguồn lấy tag đích chứ không thêm.

Ghi thất bại giữa chừng thì cả hai tag và mọi liên kết trở lại đúng như trước.

### Lỗi

- `blankName`, `nameTooLong`, `controlCharacter` — tên không hợp lệ; không ghi gì.
- `notFound` — tag không còn tồn tại; không ghi gì.
- `mergeNotConfirmed` — tên mới sẽ gộp vào một tag chưa được xác nhận (dữ liệu đã đổi từ lúc xem
  trước): không ghi gì, và phải xem trước lại.

### Business rules

- BR-TAG-001
- BR-TAG-002
- BR-TAG-006
- BR-TAG-007
- BR-TAG-009

## FN-TAG-004 — Xoá một tag
Status: active · Code: [lib/features/tags/domain/usecases/delete_tag_use_case.dart]

### Precondition

Người dùng đã xác nhận.

### Input

- Tag.

### Kết quả

Trong một transaction, mọi liên kết card–tag của tag bị gỡ rồi tag bị xoá. Không card nào bị xoá
hay đổi gì khác. Ghi thất bại thì tag và mọi liên kết còn nguyên.

### Lỗi

- `notFound` — tag không còn tồn tại; không ghi gì.

### Business rules

- BR-TAG-008
- BR-TAG-009
