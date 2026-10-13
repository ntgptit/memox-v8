---
id: BR-ACCOUNT-018
title: Lệnh ở màn 32 cần tài khoản đã xác nhận và chạy một lần một lệnh
status: active
summary: Đổi tài khoản, đăng xuất và xoá chỉ dùng được khi tài khoản đã được xác nhận; mỗi lúc chỉ một lệnh hỏi hoặc chạy.
superseded_by:
---
## Rule

Ba lệnh của màn 32 ("Switch account", "Sign out", "Delete account") MUST chỉ dùng được khi tài khoản đã được server xác nhận (`Ready`). Khi tài khoản đang được kiểm tra lại (`Validating`), màn MUST hiện "Managing your account needs a connection. Your decks are safe on this phone." và ba lệnh bị vô hiệu; khi phiên bị từ chối (`ReauthRequired`), màn MUST hiện banner đăng nhập lại (BR-ACCOUNT-017) và ba lệnh bị vô hiệu. Màn MUST luôn hiện email của tài khoản cuối đã biết.

Mỗi lúc MUST chỉ một lệnh hỏi hoặc chạy: một lần chạm khi một lệnh đang hỏi hay đang chạy MUST bị bỏ, để không mở hộp thoại thứ hai. Mỗi lệnh MUST hỏi trước (hộp thoại theo dạng của hộp thoại Reset ở Settings): Cancel, Back hoặc chạm nền là không. Một lệnh bị từ chối trước khi đổi gì MUST nói "No connection. Nothing changed; try again when you're online." hoặc "Couldn't finish that. Nothing changed; try again."

**Enforced by:** `lib/features/account/presentation/screens/account_screen.dart`, `lib/features/account/presentation/controllers/account_manage_controller.dart`, `lib/core/auth/account_coordinator_leave.dart` (`_readyUser` ném khi không phải `Ready`)
**Liên quan:** BR-ACCOUNT-014, BR-ACCOUNT-015, BR-ACCOUNT-016, BR-ACCOUNT-017
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §9 (B3), §9.1; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.3 #39; detail file [32](../../../shared/ui/screen-handoff/32-account.md) (P3b minor M3)

## Lý do

Auth spec #39 chỉ cho đăng xuất từ `READY`; ruling B3 của P3b giữ P2 không đổi và để màn 32 chờ thay vì để coordinator phải chấp nhận thêm trạng thái. Hộp thoại thứ hai chồng lên hộp thoại thứ nhất là lỗi giao diện (P3b minor M3).

## Ví dụ

Mở màn 32 ngay khi app khởi động, lúc `me()` chưa trả lời: email hiện, ba hàng lệnh mờ, ghi chú "Managing your account needs a connection…". Khi `me()` trả lời, các hàng sáng lên.

## Edge case

- Hộp thoại đọc mạng một lần khi mở (đăng xuất, xoá) làm gợi ý; coordinator kiểm lại khi chạy, và lớp chuyển tiếp vẫn che một kết nối mất giữa chừng.
- Hàng "ACCOUNT" (email, "Signed in with Google" / "with email" / "with Google and email") không chạm được; phương pháp đọc từ danh tính của phiên SDK và không có khi phiên bị từ chối.
