# Monitoring — functional specification

Các chức năng của feature monitoring: cửa sổ của admin trên log của app. Định dạng:
[docs/README.md](../README.md), mục "UC, FN và screen spec". Feature monitoring chưa có UC và BR:
hành vi của nó theo [ADR-018](../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §6–§8 và
[monitoring spec](../superpowers/specs/2026-09-29-monitoring-screen-design.md). Lỗi là
`MonitoringRejection` (`lib/features/monitoring/domain/failures/monitoring_failure.dart`) và các
`Failure` của `lib/core/error/failure.dart`.

Chỉ admin đọc được log trên server; server là nơi kiểm quyền. Việc ghi, đệm và gửi log nằm ở
`lib/core/logging/`, ngoài feature này.

## FN-MONITORING-001 — Xem log trên server
Status: active · Code: [lib/features/monitoring/domain/usecases/query_server_logs_use_case.dart, lib/features/monitoring/domain/models/log_filter_model.dart, lib/features/monitoring/domain/models/log_window_model.dart, lib/features/monitoring/domain/models/log_page_model.dart]

### Precondition

Người gọi là admin.

### Input

- Bộ lọc: mức (mặc định cảnh báo và lỗi), trạng thái (mặc định đang mở), nhóm, khoảng thời gian (1
  giờ, 24 giờ, 7 ngày, 30 ngày hoặc tất cả — tính lùi từ lúc hỏi), một thiết bị, một người dùng, và
  từ cần tìm trong tên sự kiện và nội dung. Một tập rỗng không giới hạn gì. Chọn mức gỡ lỗi hay thông
  tin — hoặc mọi mức — thì bỏ lọc trạng thái, vì các mức đó không có trạng thái.
- Con trỏ của dòng cuối trang trước, khi đọc trang sau.

### Kết quả

Một trang tới 100 log, mới nhất trước, và con trỏ của trang kế tiếp — không có khi trang chưa đầy.
Không ghi gì.

### Lỗi

- `NotAdminFailure` — người gọi không phải admin.
- `OfflineFailure`, `ServerFailure`.

### Business rules

Không áp dụng — feature monitoring chưa có BR (ADR-018 §6–§8; monitoring spec §3.2).

## FN-MONITORING-002 — Xem chi tiết một log trên server
Status: active · Code: [lib/features/monitoring/domain/usecases/get_server_log_use_case.dart, lib/features/monitoring/domain/entities/log_record_entity.dart]

### Precondition

Người gọi là admin.

### Input

- Log.

### Kết quả

Toàn bộ log: lúc xảy ra, mức, nguồn (app hay server), nhóm, sự kiện, nội dung, loại lỗi, thông báo
lỗi và stack trace, ngữ cảnh, người dùng và thiết bị, phiên bản app và hệ điều hành, và — với cảnh
báo và lỗi — trạng thái, lúc đổi, ai đổi và ghi chú. Không ghi gì.

### Lỗi

- `notFound` — log không còn: đã bị việc dọn theo thời hạn lưu xoá.
- `NotAdminFailure`, `OfflineFailure`, `ServerFailure`.

### Business rules

Không áp dụng — feature monitoring chưa có BR (ADR-018 §6; monitoring spec §3.3).

## FN-MONITORING-003 — Đánh dấu một log đã sửa hoặc mở lại
Status: active · Code: [lib/features/monitoring/domain/usecases/set_log_status_use_case.dart, lib/features/monitoring/domain/models/log_status_model.dart]

### Precondition

Người gọi là admin, và log là một cảnh báo hoặc một lỗi.

### Input

- Log.
- Trạng thái mới: đã sửa, hoặc đang mở.
- Ghi chú, khi có; bỏ khoảng trắng hai đầu, rỗng là không có ghi chú.

### Kết quả

Trạng thái được đổi trên server cùng lúc đổi, người đổi và ghi chú; kết quả là log sau khi đổi.

### Lỗi

- `notFound` — log không còn.
- `NotAdminFailure`, `OfflineFailure`, `ServerFailure`.

### Business rules

Không áp dụng — feature monitoring chưa có BR (ADR-018 §6).

## FN-MONITORING-004 — Xem log chưa gửi của thiết bị
Status: active · Code: [lib/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart, lib/features/monitoring/domain/models/pending_logs_model.dart]

### Precondition

Người gọi là admin.

### Input

- Các mức cần xem: rỗng là mọi mức.

### Kết quả

Một stream các log mới nhất trong bộ đệm của thiết bị ở các mức đã chọn, cùng tổng số log đang chờ
gửi bất kể mức; phát lại sau mỗi lần ghi vào bộ đệm. Không ghi gì.

### Lỗi

- Đọc database thất bại (ADR-016).

### Business rules

Không áp dụng — feature monitoring chưa có BR (ADR-018 §7; monitoring spec §3.1).

## FN-MONITORING-005 — Xem chi tiết một log chưa gửi
Status: active · Code: [lib/features/monitoring/domain/usecases/get_pending_log_use_case.dart]

### Precondition

Người gọi là admin.

### Input

- Log trong bộ đệm.

### Kết quả

Toàn bộ log, với cùng các trường như một log trên server, trừ trạng thái. Không ghi gì.

### Lỗi

- `notFound` — log đã được gửi lên server kể từ lúc danh sách được đọc.
- Đọc database thất bại (ADR-016).

### Business rules

Không áp dụng — feature monitoring chưa có BR (ADR-018 §7; monitoring spec §3.3).
