# Settings — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| app_settings.cardLimit | cùng bound với tùy chọn của deck (BR-STUDY-003, BR-SETTINGS-002) | như tùy chọn của deck — không có message riêng | rule |
| app_settings.themeMode | thuộc `system` \| `light` \| `dark` (BR-SETTINGS-005) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |
| app_settings.language | thuộc `system` \| `en` \| `vi` (BR-SETTINGS-006) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.
