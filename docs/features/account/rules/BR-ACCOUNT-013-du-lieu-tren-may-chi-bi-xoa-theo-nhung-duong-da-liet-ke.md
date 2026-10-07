---
id: BR-ACCOUNT-013
title: Dữ liệu trên máy chỉ bị xoá theo những đường đã được liệt kê
status: active
summary: Dữ liệu nghiệp vụ trên máy chỉ bị `LocalDataReset` xoá qua sáu đường; mất mạng, phiên bị từ chối hay người dùng ẩn danh bị dọn không xoá gì.
superseded_by:
---
## Rule

Dữ liệu nghiệp vụ trên máy (deck, card, tag, lịch ôn, lịch sử, Trash, outbox) MUST chỉ bị xoá (`LocalDataReset`) qua những đường sau:

1. một chuyển tài khoản đã qua đăng nhập đích: merge đã commit trên server, hoặc `discard` (BR-ACCOUNT-016, BR-ACCOUNT-008);
2. đăng xuất xong (BR-ACCOUNT-014);
3. xoá tài khoản xong (BR-ACCOUNT-015);
4. "Continue without this account" đã xác nhận (BR-ACCOUNT-010);
5. server báo tài khoản đã bị xoá (`me()` trả "không còn profile") trên thiết bị đang giữ tài khoản vĩnh viễn: dọn về ẩn danh, không hỏi;
6. SDK đang giữ một tài khoản khác tài khoản mà dữ liệu máy thuộc về, và không còn thay đổi chưa gửi: máy nhận tài khoản của SDK như một `discard` đã qua đăng nhập đích. Còn thay đổi chưa gửi thì máy giữ dữ liệu và chờ đăng nhập lại (BR-ACCOUNT-017).

Mất mạng MUST NOT đăng xuất hay xoá dữ liệu. Phiên của tài khoản vĩnh viễn bị từ chối MUST NOT xoá ngay: dữ liệu được giữ cho tới khi người dùng xác nhận (đường 1 hoặc 4). Người dùng ẩn danh bị dọn trên server (hơn 90 ngày không hoạt động) MUST giữ dữ liệu máy, tạo người dùng ẩn danh mới và đẩy lại toàn bộ thư viện. Một merge chưa commit MUST NOT xoá dữ liệu máy; một merge đã commit MUST NOT quay lại tài khoản nguồn.

`LocalDataReset` MUST xoá deck, card, tag, Trash, outbox, con trỏ và khoá trong `sync_state` (trừ id thiết bị), `sync_rejection`, và đưa các cài đặt đồng bộ theo tài khoản về mặc định. Nó MUST giữ: bản ghi chuyển tiếp, `welcome_seen`, các cột nhắc học chỉ của máy, id thiết bị và cơ sở dữ liệu log.

**Enforced by:** `lib/core/database/local_data_reset.dart`, `lib/core/auth/account_coordinator.dart` (`_lost`, `_driveAnonRecovery`), `lib/core/auth/account_coordinator_switch.dart` (`_advanceTarget`, `_adopt`), `lib/core/auth/account_coordinator_leave.dart` (`_driveSignOut`)
**Liên quan:** BR-ACCOUNT-001, BR-ACCOUNT-008, BR-ACCOUNT-010, BR-ACCOUNT-012, BR-ACCOUNT-014, BR-ACCOUNT-015, BR-ACCOUNT-016, BR-ACCOUNT-017, BR-SETTINGS-008
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.3 #2, #10–#14, #24–#27, #41, §3.4 (bất biến), §4; code như trên

## Lý do

Dữ liệu của người dùng là thứ không thể dựng lại nếu chưa gửi lên server. Mọi đường xoá phải được kê ra để một đường thứ bảy không thể xuất hiện mà không bị chú ý: các bất biến của auth spec §3.4 ("an uncommitted merge never clears A's local data", "offline never signs out", "a refused permanent session never clears local at once").

## Ví dụ

Phiên của tài khoản X bị server từ chối: app giữ dữ liệu, tạm dừng đồng bộ, hiện banner (BR-ACCOUNT-017). Xoá chỉ xảy ra khi người dùng đăng nhập sang tài khoản Y và xác nhận mất, hoặc chọn "Continue without this account".

## Edge case

- Đường 5 và đường 6 là hai đường tự động, không có hộp thoại nào: đường 5 vì tài khoản không còn trên server, đường 6 vì máy phải theo SDK mà dữ liệu cũ đã nằm trên server.
- `LocalDataReset` chạy không qua cổng ghi và tắt trigger bắt thay đổi (`applying_remote`) để các lệnh xoá không vào outbox.
