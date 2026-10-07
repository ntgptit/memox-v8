---
id: BR-ACCOUNT-014
title: Đăng xuất gửi thay đổi trước rồi mới xoá dữ liệu máy
status: active
summary: Đăng xuất gửi thay đổi và log lên server trước, rồi xoá dữ liệu máy và bắt đầu người dùng ẩn danh mới; offline thì phải nhận mất thay đổi mới đi tiếp.
superseded_by:
---
## Rule

Đăng xuất (màn 32 "Sign out") MUST theo thứ tự: gửi các thay đổi chưa gửi lên server và gửi log của máy; đăng xuất khỏi SDK; xoá dữ liệu máy (BR-ACCOUNT-013); bắt đầu một người dùng ẩn danh mới. Dữ liệu của tài khoản cũ MUST NOT còn trên máy sau khi xong.

Hộp thoại xác nhận MUST theo trạng thái lúc mở: online, hoặc không còn gì chưa gửi, là "Sign out?" ("Your changes are sent first, then this phone's data is removed. Sign in again to get it back.") với xác nhận tông warning; offline còn n thay đổi chưa gửi là "Sign out and lose changes?" ("{n} changes aren't sent yet and will be lost.") với xác nhận destructive, và lệnh chạy với `discardUnsent: true` (BR-ACCOUNT-010). Mạng được đọc một lần khi hộp thoại mở.

Một đăng xuất không gửi được (offline, hoặc còn hàng bị server từ chối) mà chưa nhận mất MUST dừng, MUST NOT xoá gì, và lớp chuyển tiếp MUST cho Retry, "Sign out now and lose {n} changes", và Cancel ở đầu lớp. Cancel chỉ có khi đã dừng và chưa xoá gì; nó MUST trả về tài khoản như cũ, mở cổng ghi và kiểm tra lại phiên.

**Enforced by:** `lib/core/auth/account_coordinator_leave.dart` (`signOut`, `cancelSignOut`, `_driveSignOut`), `lib/features/account/presentation/screens/account_screen.dart` (`_signOut`), `lib/features/account/presentation/controllers/account_manage_controller.dart` (`changesLostBySignOut`)
**Liên quan:** BR-ACCOUNT-010, BR-ACCOUNT-011, BR-ACCOUNT-012, BR-ACCOUNT-013
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §1 (O6), §3.3 #39–#41, #39a; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.6, §9 (B4), §9.1; detail file [32](../../../shared/ui/screen-handoff/32-account.md)

## Lý do

Chủ dự án chốt O6: đăng xuất đẩy phần chờ, xoá dữ liệu nghiệp vụ trên máy, rồi trả về một người dùng ẩn danh mới. Đăng nhập lại sẽ kéo dữ liệu về, nên đẩy trước là điều kiện để không mất gì. Critique 2026-10-02 (F2/F3) thêm Cancel cho đăng xuất dừng khi offline và cho xác nhận online tông warning vì dữ liệu an toàn trên server.

## Ví dụ

Online, còn 5 thay đổi chưa gửi: "Sign out?" → 5 thay đổi được gửi → máy sạch → người dùng ẩn danh mới. Offline, còn 5: "Sign out and lose changes?" → người dùng xác nhận → đăng xuất không gửi, 5 thay đổi mất.

## Edge case

- Gửi log của máy chỉ là nỗ lực: lỗi gửi log không chặn đăng xuất.
- "Sign out now and lose {n} changes" của lớp dùng lại bản ghi của đăng xuất đã dừng và chuyển nó sang chấp nhận mất; nó không tạo bản ghi thứ hai.
- Sau khi xong thiết bị là ẩn danh, nên router đưa màn 32 về Settings (BR-ACCOUNT-003).
