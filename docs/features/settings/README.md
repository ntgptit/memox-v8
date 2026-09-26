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
| Tab Settings (màn 23) | UC-SETTINGS-001 |
| Theme (màn 25) | UC-SETTINGS-001 |
| Language (màn 26) | UC-SETTINGS-001 |

Nguồn: trigger của UC-SETTINGS-001 ("Mở tab `Settings` của navigation shell, hoặc deep link `/settings`"). Nhắc học hằng ngày (UC-REMINDER-001) nằm trong branch Settings nhưng thuộc feature `reminders`.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Override theo root deck | Luật ở BR-STUDY-056 (feature `study`) |
| Nhắc học hằng ngày: lịch, quyền, nội dung notification | Feature `reminders`; settings chỉ lưu giá trị của nó |
