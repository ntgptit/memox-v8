---
id: BR-ACCOUNT-019
title: Chỉ admin thấy và mở được màn admin, server quyết định quyền
status: active
summary: Mục Admin của Settings và các route Monitoring, Users chỉ mở cho tài khoản admin đã được `me()` xác nhận; app chỉ ẩn hiện, server từ chối bằng `FORBIDDEN`.
superseded_by:
---
## Rule

Role của tài khoản MUST đến từ `public.profiles.role` qua `me()`, không từ JWT. Mục "ADMIN" của Settings (màn 23, gồm "Monitoring" rồi "Users") MUST chỉ hiện cho một tài khoản admin đã được xác nhận (`Ready`), và MUST NOT hiện trong bản build không có project Supabase. Các route `/settings/monitoring`, `/settings/monitoring/:id` (kể cả `?local=1`) và `/settings/users` MUST mở sau một cổng admin: với tài khoản khác, deep link MUST hiện "Only an admin can see this" và MUST NOT đọc gì, kể cả bộ đệm log trên máy (nó không có kiểm tra phía server). Khi tài khoản còn đang được xác nhận (chưa biết có là admin), cổng MUST chờ với khung xương, không từ chối.

Việc ẩn hiện chỉ là quyền nhìn thấy; quyền thật MUST do server kiểm: `log_query`, `log_get`, `log_set_status`, `role_list` và `role_set` đều từ chối người không phải admin bằng `FORBIDDEN`, và app MUST coi `FORBIDDEN`, hoặc thiếu phiên, là "không phải admin". Thay đổi role có hiệu lực ngay trên server; app thấy nó ở lần `me()` kế tiếp (mở lại app hoặc kiểm tra lại phiên).

**Enforced by:** server (`private.is_admin()` trong từng RPC, `supabase/migrations/20261010000000_accounts.sql` và `20261007000000_log_admin_reads.sql`); app: `lib/core/auth/di/auth_providers.dart` (`isAdmin`), `lib/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart`, `lib/features/settings/presentation/screens/settings_screen.dart` (mục Admin), `lib/app/router/admin_routes.dart`
**Liên quan:** BR-ACCOUNT-020, BR-ACCOUNT-022
**Nguồn:** [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §7; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §1 (O8, O9), §2.3; [users spec](../../../superpowers/specs/2026-09-30-users-admin-design.md) §1 (U2, U5), §4; [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §3.1; detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md)

## Lý do

O8 (chủ dự án, 2026-09-29/30): role sống trong dữ liệu (`profiles.role`), app đọc qua `me()`, không có role trong JWT. Có hiệu lực tức thì và đổi được trong app (`role_set`). Cổng ở app giữ một deep link khỏi đọc bộ đệm log của máy, thứ không có server đứng sau.

## Ví dụ

Người dùng thường mở `/settings/users` bằng deep link: màn hiện thanh tiêu đề "Users" và "Only an admin can see this", không có ô tìm kiếm, không gọi `role_list`. Admin mới được cấp: mục ADMIN hiện sau khi app xác nhận lại tài khoản.

## Edge case

- Monitoring spec §3.1 và §4.4 mô tả `app_metadata.role` đọc ở feature monitoring; ADR-018 §7 và code hiện tại đọc `profiles.role` qua `me()`, provider `isAdmin` nằm ở `lib/core/auth/di`. Spec cũ không còn đúng ở điểm này.
- Cổng nhận tiêu đề: Monitoring dùng "Monitoring", Users dùng "Users".
- Khi cổng từ chối một trang đang mở (server trả `FORBIDDEN` giữa chừng), màn đó chuyển sang trạng thái "not an admin" và không còn hàng nào (BR-ACCOUNT-020).
