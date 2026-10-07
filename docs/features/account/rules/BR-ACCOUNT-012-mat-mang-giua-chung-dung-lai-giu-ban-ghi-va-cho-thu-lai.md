---
id: BR-ACCOUNT-012
title: Mất mạng giữa chừng dừng lại, giữ bản ghi và cho thử lại
status: active
summary: Một chuyển tiếp gặp lỗi mạng dừng tại bước đó, giữ bản ghi và dữ liệu, rồi chạy tiếp cùng thao tác khi có mạng hoặc khi Retry.
superseded_by:
---
## Rule

Khi một bước của chuyển tài khoản, đăng xuất hoặc xoá gặp lỗi mạng, app MUST dừng tại bước đó, MUST giữ bản ghi chuyển tiếp cùng stage đã lưu, và MUST NOT xoá gì thêm. Lớp chuyển tiếp MUST nói đã dừng và dữ liệu an toàn ("No connection. Your data is safe on this phone."; đăng xuất dừng khi offline: "No connection. Nothing has been removed yet."; lỗi khác: "Something went wrong. Your data is safe on this phone.") kèm nút Retry ở footer. Thao tác MUST chạy tiếp, với cùng `operation_id`, khi mạng trở lại, khi Retry, hoặc khi mở lại app.

Mỗi stage MUST được lưu trước bước kế, mỗi bước MUST idempotent, nên chạy lại là không-làm-gì tới đúng chỗ đã dừng; một bước đã xong MUST NOT gửi lại. Trạng thái "stuck" (một trạng thái mà bảng chuyển tiếp coi là không thể) MUST giữ cổng ghi đóng, hiện "Something went wrong while moving your account. Your data is safe on this phone." và Retry. Lúc đang chạy lớp MUST nói "Nothing is lost if you close the app."

**Enforced by:** `lib/core/auth/account_coordinator.dart`, `lib/core/auth/account_coordinator_switch.dart`, `lib/core/auth/account_coordinator_leave.dart` (stage lưu qua `AccountStore`, tiếp tục qua `_resume` khi reconnect), `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
**Liên quan:** BR-ACCOUNT-011, BR-ACCOUNT-013
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.1, §3.3 #26, #33, #43, #45, §6; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.4

## Lý do

"Offline là điều kiện, không phải trạng thái": mất mạng không được làm hỏng một chuyển tiếp dở dang hay xoá dữ liệu. Vì app có thể bị đóng giữa chừng, mỗi bước phải chạy lại được an toàn.

## Ví dụ

Đang merge, mạng đứt sau khi server đã commit: bản ghi giữ ở stage `targetSignedIn`; khi có mạng lại, cùng `operation_id` gửi lại `account_merge` và nhận MERGED từ biên nhận, không nhân đôi deck.

## Edge case

- Xoá tài khoản đứt mạng giữa lúc gọi: chưa biết server đã nhận chưa nên bản ghi giữ; Retry gửi lại, và nếu server đã xoá thì lần thử lại coi như xong.
- Xoá tài khoản khi đã offline trước khi gọi thì bị từ chối ngay, trước khi có bản ghi nào (BR-ACCOUNT-015).
- Phiên nguồn bị từ chối ngay lúc xoá: bản ghi bỏ, tài khoản chờ đăng nhập lại (BR-ACCOUNT-017).
