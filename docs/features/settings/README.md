---
feature: settings
code: [lib/features/settings/domain, lib/features/settings/data, lib/features/settings/di]
depends_on: [deck, srs, study]
---
## Phạm vi

Tuỳ chọn ứng dụng (V8.0): mặc định học toàn app, theme và ngôn ngữ trong một dòng `app_settings`.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tab Settings | UC-SETTINGS-001 |

Nguồn: trigger của UC-SETTINGS-001 ("Mở tab `Settings` của navigation shell, hoặc deep link `/settings`"). Nhắc học hằng ngày (UC-REMINDER-001) nằm trong branch Settings nhưng thuộc feature `reminders`.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Override theo root deck | Luật ở BR-STUDY-056 (feature `study`) |
| Nhắc học hằng ngày | Feature `reminders` |
