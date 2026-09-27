---
feature: reminders
code: [lib/features/reminders/domain, lib/features/reminders/data, lib/features/reminders/di, lib/features/reminders/presentation]
depends_on: [deck, settings, study]
---
## Phạm vi

**Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2). Phần logic xong ở BE-B5a
([spec](../../superpowers/specs/2026-09-26-reminders-backend-design.md)); adapter Android là BE-B5b; màn 24 thuộc FE-B5.

Nhắc học hằng ngày (UC-REMINDER-001). Công tắc, giờ nhắc và lần gửi gần nhất nằm trong
dòng `app_settings`, do feature `settings` ghi. Feature này giữ port tới nền tảng
(`ReminderPlatformRepository`), workload đọc lúc fire, digest và thứ tự của nó, giờ nhắc
kế tiếp theo giờ địa phương, và sáu use case.

Phần Android (BE-B5b, gói G5 của [spec hoàn tất backend local](../../superpowers/specs/2026-09-27-local-backend-completion-design.md) §8):
`AndroidReminderPlatformRepositoryImpl` hiện thực port trên `android_alarm_manager_plus`
(một báo thức inexact, sống qua reboot) và `flutter_local_notifications` (một thông báo
id cố định, chạm mở Study Home). Hai plugin chỉ được gọi qua `ReminderPluginsDataSource`
(guard `memox_v8.architecture.reminder_plugins_have_one_door`). `ReminderOperationGate`
cho Enable, Disable và Reconcile chạy lần lượt; Deliver chạy trong isolate nền
(`reminder_background_bindings.dart`) và đọc settings lúc fire. App chạy Reconcile khi
khởi động. Web và mọi nền tảng khác giữ adapter "không hỗ trợ".

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| `Settings → Daily reminder` | UC-REMINDER-001 |

Nguồn: trigger của UC-REMINDER-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Nhắc theo thẻ mới, nhiều lượt nhắc trong ngày, nhắc theo từng deck | Ngoài phạm vi (trước migrate: `use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
