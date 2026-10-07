---
id: UC-ACCOUNT-004
title: Đăng xuất hoặc xoá tài khoản
status: draft
rules: [BR-ACCOUNT-003, BR-ACCOUNT-010, BR-ACCOUNT-011, BR-ACCOUNT-012, BR-ACCOUNT-013, BR-ACCOUNT-014, BR-ACCOUNT-015, BR-ACCOUNT-018]
code: [lib/core/auth/account_coordinator.dart, lib/core/auth/account_coordinator_leave.dart, lib/app/router/account_routes.dart, lib/features/account/presentation/screens/account_screen.dart, lib/features/account/presentation/controllers/account_manage_controller.dart, lib/features/account/presentation/providers/unsent_count_provider.dart, lib/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart, lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart, lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm "Sign out" hoặc "Delete account" ở màn 32 (vào từ hàng tài khoản ở Settings, màn 23)
**Preconditions:** Thiết bị giữ một tài khoản đã được xác nhận (`Ready`); các lệnh vô hiệu trước đó (BR-ACCOUNT-018). Xoá cần mạng (BR-ACCOUNT-015)
**Mục tiêu:** Cho người dùng rời tài khoản trên thiết bị, hoặc xoá hẳn tài khoản (Google Play đòi xoá trong app), mà không mất thay đổi nào ngoài điều họ chấp nhận. Màn 32 và lớp chuyển tiếp.

## Main flow

**Main flow (đăng xuất):**
1. Màn 32 hiện ba mục: ACCOUNT (email và "Signed in with Google", "with email" hoặc "with Google and email"), THIS PHONE ("Switch account", "Sign out") và DELETE ("Delete account", hàng trung tính).
2. Người dùng chạm "Sign out". Online, hoặc không còn gì chưa gửi: hộp thoại "Sign out?" nói thay đổi được gửi trước, rồi dữ liệu máy bị xoá, và đăng nhập lại sẽ lấy lại (BR-ACCOUNT-014).
3. Xác nhận "Sign out": lớp chuyển tiếp che app (BR-ACCOUNT-011); "Sending your changes…", rồi "Signing out…".
4. Máy được dọn, một người dùng ẩn danh mới bắt đầu và lớp biến mất. Thiết bị ẩn danh nên màn 32 chuyển về Settings (BR-ACCOUNT-003).

**Main flow (xoá tài khoản):**
1. Người dùng chạm "Delete account". Hộp thoại "Delete your account?" nói tài khoản cùng deck, thẻ và tiến độ bị xoá khỏi server và dữ liệu máy bị xoá, không hoàn tác (BR-ACCOUNT-015).
2. Xác nhận "Delete": lớp hiện "Deleting your account…"; server xoá; thiết bị bị dọn như đăng xuất và bắt đầu một người dùng ẩn danh mới; app về Settings.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Đăng xuất khi offline và còn thay đổi chưa gửi:** hộp thoại "Sign out and lose changes?" ("{n} changes aren't sent yet and will be lost.") với xác nhận destructive; xác nhận thì đăng xuất không gửi, n thay đổi mất (BR-ACCOUNT-014, BR-ACCOUNT-010).
- **A2 — Đăng xuất dừng:** gửi không xong (offline, hoặc còn hàng bị server từ chối) mà chưa nhận mất thì lớp dừng, chưa xoá gì (khi offline: "No connection. Nothing has been removed yet."; khi còn hàng bị từ chối: "Something went wrong. Your data is safe on this phone."), với Retry, "Sign out now and lose {n} changes" và "Cancel" ở đầu. Cancel trả về tài khoản như cũ (BR-ACCOUNT-014).
- **A3 — Xoá khi offline:** hộp thoại mở với "Deleting your account needs a connection." và nút "Delete" bị vô hiệu; không có gì đổi (BR-ACCOUNT-015).
- **A4 — Admin cuối cùng xoá:** server từ chối; hộp thoại "An admin must remain" ("Give another person the admin role first, then delete the account.") với "OK"; tài khoản và dữ liệu còn nguyên (BR-ACCOUNT-015).
- **A5 — Đóng app giữa chừng:** mở lại, lớp tiếp tục từ stage đã lưu (BR-ACCOUNT-012).
- **A6 — Huỷ ở hộp thoại:** Cancel, Back hoặc chạm nền không chạy lệnh nào (BR-ACCOUNT-018).

**Error flows:**
- **E1 — Mất mạng giữa chừng:** lớp dừng với "No connection. Your data is safe on this phone." (hoặc "…Nothing has been removed yet." cho đăng xuất) và Retry; xoá mà mạng đứt giữa lúc gọi thì Retry gửi lại, và nếu server đã xoá thì coi như xong (BR-ACCOUNT-012).
- **E2 — Lệnh bị từ chối trước khi đổi gì:** toast "No connection. Nothing changed; try again when you're online." hoặc "Couldn't finish that. Nothing changed; try again." (BR-ACCOUNT-018).
- **E3 — Xoá bị từ chối vì lý do khác:** toast "Couldn't delete the account. Nothing changed."
- **E4 — Phiên hết hiệu lực lúc xoá:** bản ghi bị bỏ, toast như E3, và tài khoản chờ đăng nhập lại (UC-ACCOUNT-003).
- **E5 — Một lệnh khác đang hỏi hoặc chạy:** chạm bị bỏ, không hộp thoại thứ hai (BR-ACCOUNT-018).

## UI

**UI states:** Màn 32: sẵn sàng · đang kiểm tra (`Validating`: ghi chú "Managing your account needs a connection…", lệnh bị vô hiệu) · phiên bị từ chối (banner, lệnh bị vô hiệu; UC-ACCOUNT-003). Hộp thoại: sign out online · sign out mất thay đổi · delete online · delete offline (xác nhận bị vô hiệu) · admin cuối cùng. Lớp: đang chạy · lỗi mạng · lỗi khác · đăng xuất dừng (có "Sign out now and lose {n} changes"). Mỗi hộp thoại theo dạng của hộp thoại Reset ở Settings; xác nhận đăng xuất online tông warning, xác nhận xoá và đăng xuất mất thay đổi destructive.

## Local

**Postconditions:** Dữ liệu nghiệp vụ trên máy bị xoá, `welcome_seen`, id thiết bị và log được giữ; `lastKnownAccount` bị xoá; một người dùng ẩn danh mới bắt đầu khi có mạng (BR-ACCOUNT-013). Sau khi xoá, tài khoản không còn trên server.

## API

- Đăng xuất: gửi outbox (`sync_push`) và log (`log_push`), rồi `signOut(local)` của GoTrue; không gọi RPC tài khoản nào.
- Xoá: `account_delete()` (từ chối `LAST_ADMIN`; xoá người dùng và mọi hàng của nó theo cascade), rồi như đăng xuất; một lần thử lại sau khi server đã xoá nhận `UNAUTHORIZED` và coi là xong.

## Acceptance criteria

- [ ] **Given** thiết bị online với thay đổi chưa gửi, **when** người dùng xác nhận "Sign out?", **then** thay đổi và log được gửi trước, rồi dữ liệu máy bị xoá và một người dùng ẩn danh mới bắt đầu (BR-ACCOUNT-014, BR-ACCOUNT-013).
- [ ] **Given** thiết bị offline với n thay đổi chưa gửi, **when** người dùng chạm "Sign out", **then** hộp thoại "Sign out and lose changes?" nêu n và xác nhận là destructive; không gửi gì (BR-ACCOUNT-014, BR-ACCOUNT-010).
- [ ] **Given** một đăng xuất dừng vì không gửi được, **when** người dùng bấm "Cancel" ở đầu lớp, **then** tài khoản như cũ, cổng ghi mở và phiên được kiểm lại; chưa có gì bị xoá (BR-ACCOUNT-014).
- [ ] **Given** thiết bị offline, **when** người dùng mở hộp thoại xoá tài khoản, **then** "Deleting your account needs a connection." hiện và "Delete" bị vô hiệu (BR-ACCOUNT-015).
- [ ] **Given** tài khoản là admin cuối cùng, **when** người dùng xác nhận xoá, **then** hộp thoại "An admin must remain" hiện, tài khoản và dữ liệu máy không đổi và cổng ghi mở lại (BR-ACCOUNT-015).
- [ ] **Given** server đã xoá tài khoản, **when** mạng đứt trước khi app nhận câu trả lời, **then** Retry gửi lại và hoàn tất việc dọn thiết bị mà không lỗi (BR-ACCOUNT-012, BR-ACCOUNT-015).
- [ ] **Given** màn 32 chưa ở `Ready`, **when** người dùng nhìn ba lệnh, **then** chúng bị vô hiệu; và khi một lệnh đang hỏi, một lần chạm nữa không mở hộp thoại thứ hai (BR-ACCOUNT-018).
- [ ] **Given** một đăng xuất hoặc xoá đang chạy, **when** người dùng bấm Back, **then** Back không lọt ra màn bên dưới và mọi ghi nghiệp vụ bị từ chối (BR-ACCOUNT-011).
- [ ] **Given** đăng xuất vừa xong, **when** thiết bị thành ẩn danh, **then** màn 32 chuyển về Settings (BR-ACCOUNT-003).
