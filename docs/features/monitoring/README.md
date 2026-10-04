---
feature: monitoring
code: [lib/features/monitoring/domain, lib/features/monitoring/data, lib/features/monitoring/di, lib/features/monitoring/presentation]
depends_on: []
---
## Phạm vi

Cửa sổ của admin trên log của app (FE-B8, [ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §6 đến §8, [spec](../../superpowers/specs/2026-09-29-monitoring-screen-design.md)). Feature này đọc log trên server qua `log_query` và `log_get`, đổi trạng thái open/fixed qua `log_set_status`, và đọc bộ đệm log chưa gửi của thiết bị (`LogDatabase`). Chỉ tài khoản có `app_metadata.role = admin` thấy lối vào. Server là nơi kiểm quyền (`FORBIDDEN`).

Đường ống ghi log (`AppLogger`, `LogShipper`, `log_push`) nằm ở `lib/core/logging/`, không thuộc feature này.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Ghi log, buffer, gửi log lên server | `lib/core/logging/` (B1, ADR-018 §1 đến §5) |
| Cấp hoặc thu quyền admin | Chủ dự án đặt `app_metadata.role` trên Supabase; app chỉ đọc |
| Xoá log, cảnh báo đẩy | Chưa có trong ADR-018 |
