---
feature: account
code: [lib/features/account/domain, lib/features/account/data, lib/features/account/di, lib/features/account/presentation]
depends_on: []
---
## Phạm vi

Giao diện tài khoản (FE-B9, FE-B10; [auth spec](../../superpowers/specs/2026-09-30-auth-design.md), [account UI spec](../../superpowers/specs/2026-09-30-account-ui-design.md)). Đăng nhập là tuỳ chọn: app chạy trên phiên ẩn danh, và feature này cho người dùng gắn email hoặc Google vào thiết bị, gộp thư viện khi tài khoản đã có dữ liệu, đổi tài khoản, đăng xuất và xoá tài khoản. Feature đọc trạng thái và gọi lệnh qua `accountCoordinatorProvider` và `authStateProvider` của `lib/core/auth/`; cờ Welcome (`app_settings.welcome_seen`) và số liệu thư viện đọc từ Drift.

Luật chuyển hướng của router nằm ở `lib/app/router/account_redirect.dart`.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Phiên, token, gộp và chuyển tài khoản ở tầng dữ liệu | `lib/core/auth/` (auth spec) |
| RPC tài khoản trên server (`me`, `account_*`) | `supabase/migrations/`, [supabase/README.md](../../../supabase/README.md#rules) |
| Gán quyền admin (`role_list`, `role_set`) | Chủ dự án làm trên Supabase; app chưa có màn hình |
