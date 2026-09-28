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
khởi động. Web và mọi nền tảng khác giữ adapter "không hỗ trợ". FE-B5, nơi đầu tiên gọi
Enable và Disable, MUST gọi chúng qua `reminderOperationGateProvider` như Reconcile.

### Kiểm chứng trên thiết bị (2026-09-28)

Emulator Android 16 (API 36, `google_apis_playstore`, x86_64), APK debug. Thẻ đến hạn
được tạo bằng cách sửa `card_schedule` qua `adb shell run-as` (chỉ bản debug), vì thẻ
mới không làm nhắc bắn (A4); giờ nhắc đặt trên màn 24.

1. `flutter build apk --debug` xanh với manifest và gradle của G5.
2. Gạt công tắc ở màn 24 mới hiện hộp xin quyền của hệ thống (BR-REMINDER-011). Sau khi
   cấp, `dumpsys alarm` có đúng một báo thức `RTC_WAKEUP` inexact cho giờ đã chọn
   (BR-REMINDER-009).
3. Đến giờ, notification id 7001 trên kênh `daily_reminder` hiện "5 cards are due in
   English → Vietnamese · Everyday." và lượt của ngày mai được đặt (main 4). Nhắc vẫn
   bắn khi process của app đã bị kill.
4. Chạm notification mở Study Home, cả khi app ở nền lẫn khi process đã chết (cold
   launch), và không mở phiên nào (main 5).
5. Vuốt bỏ notification: dòng `app_settings` không đổi, lượt ngày mai vẫn chờ (A6).
6. Reboot mà không mở app: báo thức được đăng ký lại qua `RebootBroadcastReceiver` và
   notification hiện đúng giờ. Trên emulator, `BOOT_COMPLETED` tới app sau 1–3 phút
   vì hàng đợi broadcast lúc khởi động.
7. E1: từ chối hai lần thì Android không hỏi nữa (`USER_FIXED`); "Try again" nhận
   `denied` ngay và màn giữ `permDenied`. FE-B6 thêm lối mở cài đặt notification.

Hai điều cần biết khi kiểm lại:

- Reconcile chạy sau khi app dựng xong; bản debug mất khoảng 15 giây. Đóng app sớm hơn
  thì lịch cũ còn nguyên.
- Trên Windows, khi pub cache và repo nằm ở hai ổ đĩa khác nhau, Kotlin incremental
  compile của plugin lỗi "Could not close incremental caches". Build bằng
  `flutter build apk --debug -Pkotlin.incremental=false`.

Tên app trên Android là "MemoX", khớp với câu chữ của màn 24 ("Android Settings › Apps ›
MemoX").

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| `Settings → Daily reminder` | UC-REMINDER-001 |

Nguồn: trigger của UC-REMINDER-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Nhắc theo thẻ mới, nhiều lượt nhắc trong ngày, nhắc theo từng deck | Ngoài phạm vi (trước migrate: `use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
