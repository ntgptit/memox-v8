---
id: BR-ACCOUNT-005
title: Email hợp lệ và cách so sánh email
status: active
summary: Email hợp lệ khi sau trim khớp `^[^@\s]+@[^@\s]+\.[^@\s]+$`, chỉ kiểm ở form đăng nhập; hai email so sánh bằng trim và chữ thường.
superseded_by:
---
## Rule

Một địa chỉ email MUST được coi là hợp lệ khi, sau khi cắt khoảng trắng hai đầu (`trim`), nó khớp `^[^@\s]+@[^@\s]+\.[^@\s]+$`: một `@`, miền có ít nhất một dấu chấm, không có khoảng trắng. Đây chỉ là kiểm tra "có vẻ là địa chỉ"; phần còn lại do server (GoTrue) quyết định. Địa chỉ không hợp lệ MUST bị từ chối trước khi gửi gì, với lý do dưới ô nhập ("Enter an email address, like name@example.com."); nút "Send code" MUST NOT bị vô hiệu vì lý do này.

Địa chỉ MUST được gửi đúng như đã gõ sau `trim`: app MUST NOT đổi chữ hoa thành chữ thường khi gửi. Khi cần biết hai địa chỉ có là một tài khoản hay không (đăng nhập lại: cùng email thì không hỏi mất thay đổi chưa gửi, BR-ACCOUNT-010), app MUST so sánh sau `trim` và chuyển chữ thường; một địa chỉ vắng (Google không trả email) MUST NOT khớp địa chỉ nào.

**Enforced by:** hiện chỉ ở những chỗ sau, không có nơi tập trung. Định dạng: `lib/features/account/presentation/controllers/sign_in_controller.dart` (`sendCode`, dùng `isEmailAddress` và biểu thức ở `lib/features/account/presentation/states/sign_in_state.dart`), một lần `trim` nữa ở `sign_in_form_widget.dart`. Không kiểm: `CodeController` (`code_controller.dart`) và `AccountCoordinator.requestCode`/`verifyCode` (`lib/core/auth/account_coordinator_switch.dart`) nhận mọi chuỗi. So sánh: `lib/core/auth/account_coordinator_leave.dart` (`_sameEmail`). Phần còn lại: server.
**Liên quan:** BR-ACCOUNT-006, BR-ACCOUNT-010
**Nguồn:** code như trên; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.2 ("The email is checked on send; its error goes under the field")

## Lý do

Nguồn không ghi lý do cho biểu thức. Chú thích của `isEmailAddress` nói đây là địa chỉ "có thể tin được" và server quyết định phần còn lại.

## Ví dụ

`  an@example.com ` hợp lệ và được gửi là `an@example.com`. `an@example`, `an @example.com`, `@example.com` và `an@@example.com` không hợp lệ. `An@Example.com` được gửi nguyên chữ hoa; ở đăng nhập lại nó được coi là cùng email với `an@example.com`.

## Edge case

- Bước nhập mã nhận email từ tham số `email` của route và không kiểm lại: một route thiếu tham số cho email rỗng, và mã vẫn được gửi đi xác nhận cho chuỗi rỗng; kết quả do server quyết định.
- Mức chuẩn hoá chữ hoa/thường phía GoTrue nằm ngoài nguồn tài liệu này.
- Đăng nhập tài khoản đích và đăng nhập lại gửi mã với `shouldCreateUser: true`: một địa chỉ gõ nhầm nhưng đúng định dạng có thể tạo một tài khoản mới (rỗng) thay vì báo lỗi.
- Tập trung việc kiểm tra và chuẩn hoá vào domain của account (một hàm cho định dạng và một cho so sánh) là việc có thể làm sau; tài liệu này ghi hiện trạng, không đổi nó.
