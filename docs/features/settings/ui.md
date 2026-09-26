# Settings — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Màn hình và điều hướng

| Màn | Route | Mở từ | Handoff |
|---|---|---|---|
| 23 · Settings | `/settings` (tab Settings) | Bottom bar | [23-settings.md](../../shared/ui/screen-handoff/23-settings.md) |
| 25 · Theme | `/settings/theme`, trên root navigator, không có bottom bar | Hàng Theme của màn 23 | [25-theme.md](../../shared/ui/screen-handoff/25-theme.md) |
| 26 · Language | `/settings/language`, trên root navigator, không có bottom bar | Hàng Language của màn 23 | [26-language.md](../../shared/ui/screen-handoff/26-language.md) |

Theme và ngôn ngữ áp cho cả app: `main()` đọc dòng `app_settings` một lần trước frame
đầu (chờ tối đa 2 giây), rồi `MemoxApp` theo stream. Nguồn:
[spec FE-A3](../../superpowers/specs/2026-09-26-settings-ui-design.md) §5.4.

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| app_settings.cardLimit | cùng bound với tùy chọn của deck (BR-STUDY-003, BR-SETTINGS-002) | "Enter a number from 1 to 200" dưới stepper, khi số gõ vào nằm ngoài khoảng; không ghi gì (UC E1) | rule + UI |
| app_settings.themeMode | thuộc `system` \| `light` \| `dark` (BR-SETTINGS-005) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |
| app_settings.language | thuộc `system` \| `en` \| `vi` (BR-SETTINGS-006) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.
