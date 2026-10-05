# Settings — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Màn hình và điều hướng

| Màn | Route | Mở từ | Handoff |
|---|---|---|---|
| 23 · Settings | `/settings` (tab Settings) | Bottom bar | [23-settings.md](../../shared/ui/screen-handoff/23-settings.md) |
| 25 · Theme | `/settings/theme`, trên root navigator, không có bottom bar | Hàng Theme của màn 23 | [25-theme.md](../../shared/ui/screen-handoff/25-theme.md) |
| 26 · Language | `/settings/language`, trên root navigator, không có bottom bar | Hàng Language của màn 23 | [26-language.md](../../shared/ui/screen-handoff/26-language.md) |
| 24 · Daily reminder | `/settings/reminder`, trên root navigator, không có bottom bar | Hàng Daily reminder của màn 23 ("Off" hoặc "On · HH:mm") | [24-daily-reminder.md](../../shared/ui/screen-handoff/24-daily-reminder.md); feature `reminders` ([ui.md](../reminders/ui.md)) |
| 15 · Study options | `/decks/deck/:deckId/options`, trên root navigator, không có bottom bar | Hàng Study options trong action sheet của deck; icon trên app bar màn 14 | [15-study-options.md](../../shared/ui/screen-handoff/15-study-options.md) |

Reset app options đưa cả nhắc học về tắt lúc 20:00 (BR-SETTINGS-008) và câu chữ nêu điều
đó; reset xong thì `app/` hoà giải lịch nhắc ([spec FE-B5](../../superpowers/specs/2026-09-28-daily-reminder-ui-design.md) D7).

Theme và ngôn ngữ áp cho cả app: `main()` đọc dòng `app_settings` một lần trước frame
đầu (chờ tối đa 2 giây), rồi `MemoxApp` theo stream. Nguồn:
[spec FE-A3](../../superpowers/specs/2026-09-26-settings-ui-design.md) §5.4.

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| app_settings.cardLimit | cùng bound với tùy chọn của deck (BR-STUDY-003, BR-SETTINGS-002) | "Enter a number from 1 to 200" dưới stepper, khi số gõ vào nằm ngoài khoảng; không ghi gì (UC E1) | rule + UI |
| app_settings.themeMode | thuộc `system` \| `light` \| `dark` (BR-SETTINGS-005) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |
| app_settings.language | thuộc `system` \| `en` \| `vi` (BR-SETTINGS-006) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |

Toàn bộ enforce ở tầng nghiệp vụ của app. Server chỉ kiểm lại tính toàn vẹn (CHECK, khoá ngoại, bất biến cây, [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md) #2) — client validation là trải nghiệm, không phải bảo mật.
