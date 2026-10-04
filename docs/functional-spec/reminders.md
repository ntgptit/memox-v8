# Reminders — functional specification

Các chức năng của feature reminders. Định dạng: [docs/README.md](../README.md), mục "UC, FN và
screen spec". Lỗi là các giá trị của `ReminderRejection`
(`lib/features/reminders/domain/failures/reminder_failure.dart`); lỗi ghi hay đọc database đi theo
mô hình lỗi của ADR-016.

Nhắc học nằm trên dòng `app_settings` (bật hay tắt, giờ dưới dạng phút trong ngày theo giờ địa
phương, lần gửi gần nhất). Lịch nhắc là lịch **không chính xác** của hệ điều hành, và đặt lịch
luôn thay lượt đang chờ, nên không bao giờ có hai lượt chờ.
Bật, tắt, đổi giờ và đồng bộ lịch chạy lần lượt, từng thao tác một, để giá trị đã lưu và lượt
đang chờ không lệch nhau; việc gửi nhắc chạy trong nền và không chờ chúng.

Đồng bộ lịch với giá trị đã lưu (`reconcile_reminder_use_case.dart`) không phải một FN: nó chạy
lúc app khởi động, sau khi tuỳ chọn ứng dụng về mặc định, và sau một sự kiện của nền tảng như đổi
múi giờ. Đang bật thì nó đặt lại lượt kế tiếp; đang tắt thì nó huỷ lượt còn sót; nền tảng không hỗ
trợ thì nó không làm gì. Chạy lại bao nhiêu lần cũng cho đúng một lượt chờ, và nó không bao giờ xin
quyền.

## FN-REMINDER-001 — Theo dõi nhắc học
Status: active · Code: [lib/features/reminders/domain/usecases/watch_reminder_use_case.dart]

### Precondition

Không có. Màn nhắc học mở được cả khi thư viện rỗng.

### Input

Không có.

### Kết quả

Một stream: nền tảng có hỗ trợ nhắc học hay không (đọc một lần), nhắc học đang bật hay tắt, và giờ
nhắc. Lần đầu dùng, nhắc học **tắt** với giờ gợi ý 20:00. Stream phát lại sau mỗi lần lưu. Không
ghi gì, không xin quyền.

### Lỗi

- Đọc database thất bại: stream báo lỗi; không có giá trị bịa nào thay chỗ.

### Business rules

- BR-REMINDER-001
- BR-REMINDER-002
- BR-REMINDER-012

## FN-REMINDER-002 — Xem trước nội dung nhắc học
Status: active · Code: [lib/features/reminders/domain/usecases/read_reminder_preview_use_case.dart, lib/features/reminders/domain/models/reminder_digest_model.dart]

### Precondition

Không có.

### Input

Không có.

### Kết quả

Nội dung notification sẽ có **nếu nó hiện ngay lúc này**, đọc một lần như notification đọc lúc
đến giờ: tên root deck cấp bách nhất, số thẻ đến hạn của deck đó, và số root deck khác còn thẻ đến
hạn. Không có gì khi không root deck nào còn thẻ đến hạn. Không ghi gì.

### Lỗi

- Đọc database thất bại.

### Business rules

- BR-REMINDER-003
- BR-REMINDER-005
- BR-REMINDER-006
- BR-REMINDER-007

## FN-REMINDER-003 — Bật nhắc học
Status: active · Code: [lib/features/reminders/domain/usecases/enable_reminder_use_case.dart]

### Precondition

Không có.

### Input

- Giờ nhắc: phút trong ngày theo giờ địa phương.

### Kết quả

Theo thứ tự: quyền notification được xin **lúc này**, không sớm hơn; lượt nhắc kế tiếp ở giờ đó
được đặt; rồi nhắc học được lưu là bật cùng giờ đó. Kết quả là thời điểm của lượt kế tiếp. "Bật"
không bao giờ được lưu khi không có lượt nào đang chờ.

### Lỗi

- `minuteOutOfRange` — giờ ngoài 0–1439.
- `unsupported` — nền tảng không có nhắc học.
- `permissionDenied` — người dùng từ chối quyền; hệ thống không tự xin lại.
- `couldNotSchedule` — nền tảng từ chối đặt lịch.

Bốn lỗi trên để mọi thứ như cũ: nhắc học vẫn tắt và không có lượt nào chờ. Lưu thất bại thì lượt
vừa đặt bị gỡ trước khi lỗi đi ra.

### Business rules

- BR-REMINDER-001
- BR-REMINDER-002
- BR-REMINDER-009
- BR-REMINDER-010
- BR-REMINDER-011
- BR-REMINDER-012

## FN-REMINDER-004 — Gửi nhắc học khi đến giờ
Status: active · Code: [lib/features/reminders/domain/usecases/deliver_reminder_use_case.dart, lib/features/reminders/domain/models/reminder_digest_model.dart]

### Precondition

Một lượt nhắc đã đặt vừa đến giờ; chạy trong nền, không cần app đang mở.

### Input

Không có. Mọi thứ được đọc lại **lúc đến giờ**, không phải lúc đặt lịch.

### Kết quả

- Nhắc học đã tắt, hoặc nền tảng không hỗ trợ, hoặc tuỳ chọn không đọc được: không hiện gì và
  không đặt lượt nào.
- Chưa tới giờ nhắc của hôm nay, hôm nay đã gửi rồi, không root deck nào còn thẻ đến hạn (thẻ chưa
  học xong chuỗi học mới không được tính), khối lượng việc không đọc được, hoặc nền tảng không hiện
  được: không hiện gì, và lượt kế tiếp vẫn được đặt.
- Còn thẻ đến hạn: đúng **một** notification tóm tắt cho ngày địa phương đó, thay notification của
  hôm trước nếu nó còn. Nó nêu tên root deck cấp bách nhất, số thẻ đến hạn của deck đó và số root
  deck khác còn thẻ đến hạn — không mặt thẻ, ví dụ, tag hay dữ liệu học nào của từng thẻ, kể cả trên
  màn khoá. Lần gửi được ghi, rồi lượt của ngày kế tiếp được đặt.

Lần gửi là thứ duy nhất được ghi. Ghi lần gửi thất bại thì được báo lại, không ném lỗi, vì
notification đã hiện rồi. Kết quả chỉ mang lý do có kiểu và các con số, không mang nội dung thẻ.

### Lỗi

Không có lỗi đi ra: mọi tình huống ở trên là một kết quả có kiểu.

### Business rules

- BR-CORE-001
- BR-REMINDER-003
- BR-REMINDER-004
- BR-REMINDER-005
- BR-REMINDER-006
- BR-REMINDER-007
- BR-REMINDER-009
- BR-REMINDER-010
- BR-STUDY-074

## FN-REMINDER-005 — Mở lối học từ notification
Status: active · Code: [lib/app/app.dart, lib/features/reminders/data/datasources/plugin_reminder_plugins_data_source.dart]

### Precondition

Notification nhắc học đang hiện.

### Input

- Chạm notification, khi app đang chạy hoặc khi chạm làm app khởi động.

### Kết quả

App mở tab Study. Không phiên nào được mở, không deck nào được chọn, không gì được ghi. Vuốt bỏ
notification không đổi gì: không trạng thái học, lịch thẻ hay lịch sử nào đổi, và lượt nhắc hôm
sau giữ nguyên.

### Lỗi

Không có.

### Business rules

- BR-REMINDER-008

## FN-REMINDER-006 — Đổi giờ nhắc
Status: active · Code: [lib/features/reminders/domain/usecases/change_reminder_time_use_case.dart]

### Precondition

Không có.

### Input

- Giờ nhắc mới: phút trong ngày theo giờ địa phương.

### Kết quả

Đang bật: lượt nhắc kế tiếp ở giờ mới được đặt **trước**, rồi giờ mới được lưu; kết quả là thời
điểm của lượt kế tiếp. Đang tắt, hoặc nền tảng không hỗ trợ: chỉ giờ được lưu. Không xin quyền.

### Lỗi

- `minuteOutOfRange` — giờ ngoài 0–1439; không gì đổi.
- `couldNotSchedule` — nền tảng từ chối đặt lịch; giờ cũ và lịch của nó giữ nguyên.

Lưu thất bại sau khi đã đặt lịch thì lịch của giờ cũ được đặt lại, trong chừng mực nền tảng cho
phép, trước khi lỗi đi ra.

### Business rules

- BR-REMINDER-002
- BR-REMINDER-009
- BR-REMINDER-010

## FN-REMINDER-007 — Tắt nhắc học
Status: active · Code: [lib/features/reminders/domain/usecases/disable_reminder_use_case.dart]

### Precondition

Không có.

### Input

Không có.

### Kết quả

Nhắc học được lưu là tắt **trước**, giữ nguyên giờ, rồi lượt đang chờ bị huỷ. Không xin quyền,
không cần xác nhận. Gọi lại khi đã tắt thì không ghi gì, chỉ huỷ — đó là cách thử lại.

### Lỗi

- `couldNotCancel` — nhắc học **đã** tắt; chỉ lượt đang chờ là chưa huỷ được. Nếu nó đến giờ, nó
  đọc lại tuỳ chọn và không hiện gì.

Lưu thất bại thì không có gì bị huỷ, và nhắc học vẫn bật.

### Business rules

- BR-REMINDER-003
- BR-REMINDER-009
