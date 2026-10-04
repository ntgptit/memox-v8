# Settings — functional specification

Các chức năng của feature settings. Định dạng: [docs/README.md](../README.md), mục "UC, FN và
screen spec". Lỗi là các giá trị của `SettingsRejection`
(`lib/features/settings/domain/failures/settings_failure.dart`); lỗi ghi hay đọc database đi theo
mô hình lỗi của ADR-016.

Mọi giá trị ở đây nằm trên **một** dòng `app_settings`, trừ tuỳ chọn học riêng của một root deck
(`deck.study_config`). Mỗi lần lưu là một transaction riêng: hỏng khi lưu một giá trị không ghi
giá trị nào khác.

## FN-SETTINGS-001 — Theo dõi tuỳ chọn ứng dụng
Status: active · Code: [lib/features/settings/domain/usecases/watch_app_settings_use_case.dart, lib/features/settings/domain/entities/app_settings_entity.dart, lib/app/startup_settings.dart]

### Precondition

Không có. Dòng `app_settings` luôn tồn tại.

### Input

Không có.

### Kết quả

Một stream các giá trị đang có hiệu lực: mặc định học toàn app (trần thẻ mỗi phiên, thứ tự thẻ
mới), theme, ngôn ngữ, và nhắc học hằng ngày (bật hay tắt, giờ). Stream phát lại sau mỗi lần lưu,
nên mọi nơi đọc cùng một stream đều thấy giá trị mới. Không ghi gì.

Lúc app khởi động, giá trị được đọc một lần trước khung hình đầu, chờ tối đa 2 giây, để theme
và ngôn ngữ đã lưu áp ngay từ đầu. Đọc lỗi hoặc quá hạn thì app theo hệ điều hành cho tới khi
stream trả lời.

### Lỗi

- Đọc database thất bại: stream báo lỗi; không có giá trị bịa nào thay chỗ.

### Business rules

- BR-SETTINGS-001

## FN-SETTINGS-002 — Lưu mặc định học toàn app
Status: active · Code: [lib/features/settings/domain/usecases/save_study_defaults_use_case.dart, lib/features/settings/domain/models/study_options_model.dart]

### Precondition

Không có.

### Input

- Trần thẻ mỗi phiên: số nguyên.
- Thứ tự thẻ mới: `created` hoặc `random`.

### Kết quả

Hai giá trị được ghi trong một transaction. Chúng áp cho mọi root deck **không** có tuỳ chọn riêng,
và chỉ cho phiên **mở sau đó**: phiên đang chạy giữ trần thẻ đã chốt lúc mở, không dựng lại hàng
đợi và không đổi thứ tự đã sinh. Root deck có tuỳ chọn riêng không đổi gì.

### Lỗi

- `cardLimitOutOfRange` — trần thẻ ngoài khoảng 1–200; không ghi gì.

### Business rules

- BR-SETTINGS-002
- BR-SETTINGS-004
- BR-SETTINGS-007
- BR-STUDY-003
- BR-STUDY-024
- BR-STUDY-057

## FN-SETTINGS-003 — Đặt theme
Status: active · Code: [lib/features/settings/domain/usecases/set_theme_use_case.dart, lib/features/settings/domain/models/theme_choice_model.dart, lib/app/startup_settings.dart]

### Precondition

Không có.

### Input

- Theme: `system`, `light` hoặc `dark`.

### Kết quả

Giá trị được ghi trong một transaction riêng và áp ngay trong phiên chạy của app, không khởi động
lại. `system` đi theo brightness của hệ điều hành và đổi theo khi hệ điều hành đổi; giá trị tường
minh không đổi theo. Giá trị còn sau khi khởi động lại app.

### Lỗi

- Ghi database thất bại: không có giá trị nào đổi.

### Business rules

- BR-SETTINGS-005
- BR-SETTINGS-007

## FN-SETTINGS-004 — Đặt ngôn ngữ
Status: active · Code: [lib/features/settings/domain/usecases/set_language_use_case.dart, lib/features/settings/domain/models/language_choice_model.dart, lib/app/startup_settings.dart]

### Precondition

Không có.

### Input

- Ngôn ngữ: `system`, `en` hoặc `vi`.

### Kết quả

Giá trị được ghi trong một transaction riêng và áp ngay trong phiên chạy của app. `system` đi theo
locale của hệ điều hành trên các ngôn ngữ app hỗ trợ, và về `en` khi không khớp. Đổi ngôn ngữ chỉ
đổi nhãn hiển thị: không nội dung thẻ hay lịch sử ôn tập nào đổi, vì nhãn không bao giờ được lưu.

### Lỗi

- Ghi database thất bại: không có giá trị nào đổi.

### Business rules

- BR-SETTINGS-006
- BR-SETTINGS-007
- BR-STUDY-035

## FN-SETTINGS-005 — Đưa tuỳ chọn ứng dụng về mặc định
Status: active · Code: [lib/features/settings/domain/usecases/reset_app_settings_use_case.dart]

### Precondition

Người dùng đã xác nhận.

### Input

Không có.

### Kết quả

Trong một transaction, sáu giá trị về mặc định: trần thẻ 20, thứ tự thẻ mới `created`, theme
`system`, ngôn ngữ `system`, nhắc học tắt, và giờ nhắc 20:00. Lần gửi nhắc gần nhất là
bookkeeping và không đổi. Tuỳ chọn riêng của các root deck, tiến độ học, lịch, lịch sử, phiên,
chế độ ôn tập và nội dung không đổi — đây không phải đặt lại tiến độ học.

### Lỗi

- Ghi database thất bại: không có giá trị nào đổi.

### Business rules

- BR-SETTINGS-007
- BR-SETTINGS-008

## FN-SETTINGS-006 — Theo dõi tuỳ chọn học đang áp cho một deck
Status: active · Code: [lib/features/settings/domain/usecases/watch_study_options_use_case.dart, lib/features/settings/domain/models/effective_study_options_model.dart]

### Precondition

Không có.

### Input

- Deck: root hoặc deck con.

### Kết quả

Một stream: root của deck (id và tên), tuỳ chọn học đang áp cho cả cây, và nguồn của chúng —
mặc định toàn app, tuỳ chọn riêng của root, hoặc tuỳ chọn riêng không đọc được (khi đó mặc định
toàn app được áp, tuỳ chọn đã lưu giữ nguyên, và việc học không bị chặn). Deck con không có tuỳ
chọn của riêng nó. Stream phát lại khi tuỳ chọn của root hoặc mặc định toàn app đổi. Không ghi gì.

### Lỗi

- `deckNotFound` — deck không tồn tại hoặc đang ở Trash, kể cả khi nó vào Trash trong lúc đang
  theo dõi.

### Business rules

- BR-SETTINGS-003
- BR-STUDY-056

## FN-SETTINGS-007 — Lưu tuỳ chọn học riêng của một root deck
Status: active · Code: [lib/features/settings/domain/usecases/save_root_study_options_use_case.dart]

### Precondition

Không có.

### Input

- Root deck.
- Trần thẻ mỗi phiên và thứ tự thẻ mới, cùng kiểu và cùng giới hạn với FN-SETTINGS-002.

### Kết quả

Tuỳ chọn riêng của root được ghi trong một transaction. Từ đó mọi phiên mở sau trên cây dùng
chúng thay cho mặc định toàn app, kể cả khi mặc định toàn app đổi về sau; phiên đang chạy không
đổi.

### Lỗi

- `cardLimitOutOfRange` — trần thẻ ngoài khoảng 1–200.
- `deckNotFound` — root không tồn tại hoặc đang ở Trash.
- `notARootDeck` — deck là deck con: tuỳ chọn học nằm trên root.

Mọi lỗi đều không ghi gì.

### Business rules

- BR-SETTINGS-002
- BR-SETTINGS-003
- BR-SETTINGS-004
- BR-SETTINGS-007
- BR-STUDY-056

## FN-SETTINGS-008 — Cho một root deck dùng lại mặc định toàn app
Status: active · Code: [lib/features/settings/domain/usecases/use_app_defaults_use_case.dart]

### Precondition

Không có.

### Input

- Root deck.

### Kết quả

Tuỳ chọn riêng của root bị xoá trong một transaction, và cây bắt đầu dùng mặc định toàn app ở
lần đọc kế tiếp. Root không có tuỳ chọn riêng thì không có gì đổi và không phải lỗi. Tiến độ học,
chế độ ôn tập và lịch sử không đổi.

### Lỗi

- `deckNotFound` — root không tồn tại hoặc đang ở Trash.
- `notARootDeck` — deck là deck con.

Mọi lỗi đều để tuỳ chọn riêng giữ nguyên, không có thay đổi một phần.

### Business rules

- BR-SETTINGS-003
- BR-SETTINGS-007
