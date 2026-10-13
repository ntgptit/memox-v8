---
id: BR-ACCOUNT-003
title: Màn gắn và màn quản lý tài khoản theo tài khoản của thiết bị
status: active
summary: Thiết bị đã giữ tài khoản thì luồng gắn chuyển sang màn 32; thiết bị còn ẩn danh thì màn 32 chuyển về Settings.
superseded_by:
---
## Rule

Router MUST áp hai luật sau, dựa trên tài khoản mà dữ liệu của thiết bị thuộc về:

1. `/settings/sign-in` ở mode `link` (kể cả bước mã của nó) khi thiết bị đã giữ một tài khoản vĩnh viễn MUST chuyển tới `/settings/account` (màn 32). Mode `reauth` MUST NOT bị chuyển hướng.
2. `/settings/account` khi thiết bị còn ẩn danh (`Ready` ẩn danh, `Validating` chưa có hoặc có tài khoản cuối là ẩn danh, `LocalOnly`, `Bootstrapping`) MUST chuyển tới `/settings`.

"Thiết bị giữ một tài khoản" nghĩa là `Ready` với người dùng không ẩn danh, `Validating` với tài khoản cuối không ẩn danh, hoặc `ReauthRequired`. Trong lúc khởi động (`Booting`) hoặc một chuyển tiếp đang chạy (`Transitioning`, `Recovering`), router MUST NOT dời chỗ.

**Enforced by:** `lib/app/router/account_redirect.dart` (`accountRedirect`), `lib/features/account/presentation/providers/device_account_provider.dart` (`deviceAccountOf`)
**Liên quan:** BR-ACCOUNT-002, BR-ACCOUNT-004
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §4, §9 (B9); chú thích của `accountRedirect` ("plan ruling 4" của P3b)

## Lý do

Một thiết bị đã có tài khoản không cần gắn thêm; một thiết bị ẩn danh không có gì để quản lý. Đứng yên khi đang khởi động hoặc chuyển tiếp để một lần đổi trạng thái giữa chừng không đẩy người dùng đi chỗ khác.

## Ví dụ

Người dùng vừa đăng xuất xong đứng ở màn 32: thiết bị thành ẩn danh, router đưa về Settings (23). Mở lại `/settings/sign-in?mode=link` khi đã có tài khoản thì vào màn 32.

## Edge case

- Account UI spec §4 viết "hai luật"; code có luật thứ hai (màn 32 → Settings) từ plan ruling 4 của P3b, không có trong spec §4.
- `Transitioning`/`Recovering` không nằm trong "thiết bị giữ tài khoản" theo `deviceAccountOf`, nên luật 1 không chuyển hướng trong lúc chuyển tiếp.
