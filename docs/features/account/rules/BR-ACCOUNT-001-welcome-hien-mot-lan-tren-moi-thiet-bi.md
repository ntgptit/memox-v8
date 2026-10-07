---
id: BR-ACCOUNT-001
title: Welcome hiện một lần trên mỗi thiết bị
status: active
summary: Màn Welcome (29) hiện đúng một lần trên mỗi thiết bị của bản build có thể đăng nhập; cờ `welcome_seen` chỉ của máy, mọi lối ra đều trả lời Welcome.
superseded_by:
---
## Rule

App MUST hiện Welcome (màn 29) đúng một lần trên mỗi thiết bị, kể cả thiết bị đã dùng app trước khi có tài khoản: `welcome_seen` MUST ở `0` khi nâng cấp, không backfill. Cho tới khi Welcome được trả lời, router MUST đưa mọi vị trí tới `/welcome?from=<vị trí đã xin>`, giữ vị trí đó để deep link không mất. Mỗi lối ra của Welcome (Google đăng nhập xong hoặc đã bắt đầu chuyển, "Continue with email", "Continue without an account") MUST trả lời Welcome: router thôi chuyển hướng ngay, rồi cờ được ghi; ghi lỗi chỉ làm Welcome hiện lại ở lần mở sau.

`app_settings.welcome_seen` MUST là cột chỉ của máy, không đồng bộ. `Reset to defaults` của Settings (BR-SETTINGS-008) và `LocalDataReset` (đăng xuất, chuyển tài khoản) MUST NOT xoá nó. Welcome MUST chỉ hiện trên bản build có thể đăng nhập (có project Supabase, tức có `AccountCoordinator`). Cờ được đọc trước khung hình đầu để không nháy màn; đọc lỗi hoặc quá chậm thì không hiện Welcome và lần mở sau hỏi lại.

**Enforced by:** `lib/app/router/account_redirect.dart` (luật chuyển hướng), `lib/app/startup_welcome.dart` (đọc cờ trước khung hình đầu), `lib/features/account/presentation/providers/welcome_due_provider.dart` (trả lời Welcome), cột `welcome_seen` của `app_settings`
**Liên quan:** BR-SETTINGS-008, BR-ACCOUNT-002, BR-ACCOUNT-004
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §1 (U1), §4, §5.1; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §4, §7

## Lý do

Chủ dự án chốt U1 (2026-09-30): lời mời đăng nhập hiện cho **mọi** thiết bị đúng một lần, thiết bị đã dùng app trước bản cập nhật cũng vậy. Cờ nằm trong một cột chỉ của máy để reset cài đặt và đăng xuất không làm Welcome hiện lại.

## Ví dụ

Mở app lần đầu bằng deep link `/study`: router đưa tới `/welcome?from=%2Fstudy`; sau "Continue without an account" app vào `/study`. Không có `from` hợp lệ thì vào `/decks`.

## Edge case

- `from` nằm ngoài app (có scheme, host, `//`) bị bỏ, dùng `/decks` (BR-ACCOUNT-004).
- Google đăng nhập vào một tài khoản đã có: Welcome chỉ được trả lời khi chuyển thực sự bắt đầu (người dùng chọn trong sheet gộp); huỷ sheet thì Welcome còn nguyên.
- Spec viết "mỗi lối ra đặt cờ trước rồi mới đi tiếp"; code tắt cờ trong bộ nhớ trước (router thôi chuyển hướng), ghi vào Drift sau, không chặn lối đi.
