# Reminders — UI

Màn hình, điều hướng và validation của nhắc học hằng ngày. Hành vi riêng nằm trong
[UC-REMINDER-001](usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md).

## Màn hình và điều hướng

| Màn | Route | Mở từ | Handoff |
|---|---|---|---|
| 24 · Daily reminder | `/settings/reminder`, trên root navigator, không có bottom bar | Hàng Daily reminder của màn 23 | [24-daily-reminder.md](../../shared/ui/screen-handoff/24-daily-reminder.md) |
| Notification | chạm mở `/study` (Study Home), không mở phiên nào (BR-REMINDER-008) | Notification nhắc học | — |

Màn 24 đọc nhắc học đã lưu qua stream của `WatchReminderUseCase`; bật, tắt và đổi giờ đi
qua `ReminderOperationGate`, từng thao tác một
([spec FE-B5](../../superpowers/specs/2026-09-28-daily-reminder-ui-design.md) D3, D4).
Quyền notification chỉ được xin khi người dùng bật (BR-REMINDER-011).

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| app_settings.reminder_minute_of_day | 0–1439, phút trong ngày địa phương (BR-REMINDER-002) | Dialog chọn giờ: giờ 0–23, phút 0–59; số gõ ngoài khoảng đánh dấu stepper và khoá Save, không ghi gì | rule + db + UI |
| app_settings.reminder_enabled | chỉ lưu bật khi đã có quyền và đã đặt lịch (BR-REMINDER-011, spec reminders D13) | Banner của E1 hoặc E3; toggle vẫn tắt | rule + UI |
