# Starter decks — functional specification

Các chức năng của feature starter-decks. Định dạng: [docs/README.md](../README.md), mục "UC, FN và
screen spec". Lỗi là các giá trị của `StarterRejection`
(`lib/features/starter_decks/domain/failures/starter_failure.dart`); lỗi ghi hay đọc database đi
theo mô hình lỗi của ADR-016.

Một starter deck là một **template** đóng gói cùng app, có id ổn định qua các phiên bản app và một
version. Nó chỉ trở thành dữ liệu của người dùng khi người dùng thêm nó: app không bao giờ tự chèn
template vào thư viện. Nội dung starter là fixture cho development và test.

## FN-STARTER-001 — Xem thư viện starter
Status: active · Code: [lib/features/starter_decks/domain/usecases/watch_starter_library_use_case.dart, lib/features/starter_decks/domain/models/starter_library_entry_model.dart, lib/features/starter_decks/data/datasources/template_asset_data_source.dart]

### Precondition

Không có. Thư viện thường được mở khi chưa có deck nào, nhưng mở được bất cứ lúc nào.

### Input

Không có.

### Kết quả

Một stream các template, theo thứ tự của manifest, phát lại sau mỗi lần một bản sao được thêm hay
bị xoá. Mỗi template mang tên, ngôn ngữ của hai mặt, locale, nguồn nội dung, chế độ ôn tập gợi ý,
số deck con và số card, và việc thư viện **đã có** nó chưa — đã có khi một bản sao của đúng
template và version đó nằm ngoài Trash. Một version mới của template coi như chưa có. Manifest thiếu
hoặc hỏng cho danh sách rỗng; một file template hỏng chỉ làm mất đúng template đó. Không ghi gì.

### Lỗi

- Đọc database thất bại: stream báo lỗi.

### Business rules

- BR-STARTER-001
- BR-STARTER-002
- BR-STARTER-006
- BR-STARTER-010

## FN-STARTER-002 — Thêm một starter deck vào thư viện
Status: active · Code: [lib/features/starter_decks/domain/usecases/add_starter_deck_use_case.dart, lib/features/starter_decks/domain/models/added_starter_deck_model.dart]

### Precondition

Không có.

### Input

- Template.
- Chế độ ôn tập cho bản sao; gợi ý là chế độ của template.
- Người dùng có xác nhận thêm một bản sao nữa không: mặc định không.

### Kết quả

Trong một transaction, tất cả hoặc không gì: một root deck mới mang tên template, chế độ ôn tập đã
chọn, generation 1, chưa khoá chế độ, và ghi nhận template cùng version nguồn; toàn bộ cây deck con
theo đúng thứ tự và loại nội dung của template; toàn bộ card, mỗi card với đúng một trạng thái học
khởi tạo theo chế độ đó — chưa học. Bản sao là một deck bình thường của người dùng: sửa, di chuyển,
xoá như mọi deck, và một version mới của template không bao giờ ghi đè lên nó. Kết quả: root deck
mới, tên, chế độ ôn tập và số card.

### Lỗi

- `templateNotFound` — không còn template nào có id đó; không gì được ghi.
- `alreadyInLibrary` — đã có bản sao của đúng template và version đó ngoài Trash, và người dùng chưa
  xác nhận thêm bản nữa; không gì được ghi.
- Ghi database thất bại: rollback, không có cây deck nửa vời.

### Business rules

- BR-CARD-004
- BR-DECK-002
- BR-STARTER-003
- BR-STARTER-004
- BR-STARTER-005
- BR-STARTER-006
- BR-STARTER-007
- BR-STARTER-008
- BR-STARTER-009
