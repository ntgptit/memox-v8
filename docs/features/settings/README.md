---
feature: settings
code: [lib/features/settings/domain, lib/features/settings/data, lib/features/settings/di, lib/features/settings/presentation]
depends_on: [deck, srs, study]
---
## Phạm vi

Tuỳ chọn ứng dụng (V8.0): mặc định học toàn app, theme và ngôn ngữ trong một dòng `app_settings`. Feature này cũng lưu công tắc, giờ và lần gửi gần nhất của nhắc học hằng ngày trong dòng đó, cho feature `reminders` ([spec gói 11a](../../superpowers/specs/2026-09-26-reminders-backend-design.md) D2).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tab Settings (màn 23, hub) | UC-SETTINGS-001 |
| Study defaults (màn 23a) | UC-SETTINGS-001 |
| Admin (màn 23b, chỉ admin) | Chưa có UC; hành vi theo [spec settings hub](../../superpowers/specs/2026-10-07-settings-hub-design.md) §5.3 |
| Theme (màn 25) | UC-SETTINGS-001 |
| Language (màn 26) | UC-SETTINGS-001 |
| Study options của bộ thẻ (màn 15) | UC-SETTINGS-001 (A1, E4) |
| Sync (màn 27) | Chưa có UC; hành vi theo [spec sync status](../../superpowers/specs/2026-09-28-sync-status-design.md) §5.2 và [handoff 27](../../shared/ui/screen-handoff/27-sync.md) |

Nguồn: trigger của UC-SETTINGS-001 ("Mở tab `Settings` của navigation shell, hoặc deep link `/settings`"). Nhắc học hằng ngày (UC-REMINDER-001) nằm trong branch Settings nhưng thuộc feature `reminders`.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Override theo root deck | Luật ở BR-STUDY-056 (feature `study`) |
| Nhắc học hằng ngày: lịch, quyền, nội dung notification | Feature `reminders`; settings chỉ lưu giá trị của nó |
| Cơ chế sync, outbox, lỗi sync | `lib/core/sync/` ([ADR-013](../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md)); màn 27 chỉ hiển thị và cho thử lại |
