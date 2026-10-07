---
id: BR-ACCOUNT-015
title: Xoá tài khoản cần mạng và nêu rõ cái gì bị xoá
status: active
summary: Xoá tài khoản chỉ online, nêu rõ tài khoản và dữ liệu máy bị xoá không hoàn tác, và bị từ chối với admin cuối cùng.
superseded_by:
---
## Rule

Xoá tài khoản MUST cần kết nối. Offline, hộp thoại MUST hiện "Deleting your account needs a connection." và nút xác nhận MUST bị vô hiệu; lệnh `deleteAccount` offline MUST bị từ chối trước khi đổi bất cứ gì. Hộp thoại "Delete your account?" MUST nêu: tài khoản cùng deck, thẻ và tiến độ bị xoá khỏi server, dữ liệu trên máy bị xoá, không hoàn tác. Xác nhận MUST là một nút destructive "Delete", không bắt gõ lại gì.

Server MUST từ chối xoá admin cuối cùng (`LAST_ADMIN`). App MUST giữ nguyên tài khoản và dữ liệu, mở lại cổng ghi, và hiện hộp thoại "An admin must remain" ("Give another person the admin role first, then delete the account.") với một nút "OK", ở navigator của router. Từ chối khác MUST là thông báo "Couldn't delete the account. Nothing changed." Sau khi server đã xoá, thiết bị MUST được dọn như đăng xuất (BR-ACCOUNT-013) và bắt đầu một người dùng ẩn danh mới.

**Enforced by:** server (`public.account_delete()` từ chối `LAST_ADMIN`, `supabase/migrations/20261010000000_accounts.sql`); app: `lib/core/auth/account_coordinator_leave.dart` (`deleteAccount`, `_driveSignOut`, `_refuseDelete`), `lib/features/account/presentation/screens/account_screen.dart` (`_delete`), `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart` (notice)
**Liên quan:** BR-ACCOUNT-012, BR-ACCOUNT-013
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §1 (O7), §3.3 #42–#44; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.4, §5.6, §9 (B6, B7)

## Lý do

Google Play đòi xoá tài khoản trong app một khi app tạo tài khoản (auth spec §1). Ruling B6 của brainstorm P3b: chạm hàng rồi xác nhận trong hộp thoại là hai thao tác có chủ ý nên không cần gõ xác nhận. Nguồn không ghi lý do riêng cho việc từ chối admin cuối cùng ngoài ràng buộc `LAST_ADMIN` của server.

## Ví dụ

Người dùng chạm "Delete account" khi offline: hộp thoại mở với ghi chú offline và nút "Delete" mờ. Admin duy nhất xoá tài khoản khi online: hộp thoại "An admin must remain".

## Edge case

- Đứt mạng giữa lúc gọi `account_delete()`: chưa rõ server đã nhận; bản ghi giữ và Retry gửi lại (BR-ACCOUNT-012).
- Nếu server báo phiên không còn hợp lệ lúc xoá, bản ghi bị bỏ, thông báo "Couldn't delete the account. Nothing changed." hiện, và tài khoản chờ đăng nhập lại (BR-ACCOUNT-017).
