---
feature: monitoring
code: [lib/features/monitoring/domain, lib/features/monitoring/data, lib/features/monitoring/di, lib/features/monitoring/presentation]
depends_on: []
---
## Phạm vi

Cửa sổ của admin trên log của app (FE-B8, [ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §6 đến §8, [spec](../../superpowers/specs/2026-09-29-monitoring-screen-design.md)). Feature này đọc log trên server qua `log_query` và `log_get`, đổi trạng thái open/fixed qua `log_set_status`, và đọc bộ đệm log chưa gửi của thiết bị (`LogDatabase`). Chỉ tài khoản có role `admin` (đọc qua `me()`, `lib/core/auth/`) thấy lối vào. Server là nơi kiểm quyền (`FORBIDDEN`).

Đường ống ghi log (`AppLogger`, `LogShipper`, `log_push`) nằm ở `lib/core/logging/`, không thuộc feature này.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Monitoring, danh sách và chi tiết (màn 28) | Chưa có UC; hành vi theo ADR-018 §6 đến §8 và spec §3 |
| Mục Admin trong tab Settings (màn 23) | Lối vào; widget `MonitoringEntryRowWidget` do router chèn vào màn 23 |

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Ghi log, buffer, gửi log lên server | `lib/core/logging/` (B1, ADR-018 §1 đến §5) |
| Cấp hoặc thu quyền admin | Feature account (màn 33) |
| Xoá log, cảnh báo đẩy | Chưa có trong ADR-018 |
