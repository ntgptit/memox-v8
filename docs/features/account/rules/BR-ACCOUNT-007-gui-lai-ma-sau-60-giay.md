---
id: BR-ACCOUNT-007
title: Gửi lại mã sau 60 giây
status: active
summary: "Resend code" chỉ dùng được sau 60 giây kể từ lần gửi trước; trong lúc chờ là một dòng chú thích, không phải nút.
superseded_by:
---
## Rule

Sau mỗi lần mã được gửi, và khi bước nhập mã mở ra, "Resend code" MUST chờ 60 giây. Trong lúc chờ, dòng trạng thái MUST là chú thích "New code in m:ss", không phải nút bị vô hiệu. Hết chờ MUST hiện nút "Resend code". Gửi lại thành công MUST báo "A new code is on its way." và bắt đầu lại 60 giây; gửi lại thất bại MUST giữ nút (hết chờ) và nói lý do. Gửi lại MUST NOT chạy trong lúc đang kiểm mã hoặc đang gửi.

Mỗi cặp (địa chỉ, mục đích: gắn, đích, đăng nhập lại) MUST có đếm ngược riêng, để bước mã của lớp chuyển tiếp không dùng chung đếm ngược với màn 31.

**Enforced by:** `lib/features/account/presentation/controllers/code_controller.dart` (`resendWait`, `resend`), `lib/features/account/presentation/widgets/sections/code_form_widget.dart`
**Liên quan:** BR-ACCOUNT-006, BR-ACCOUNT-010
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.2; [sign-in redesign](../../../superpowers/specs/2026-10-05-sign-in-flow-redesign-design.md) §4.2; detail file [31](../../../shared/ui/screen-handoff/31-code.md)

## Lý do

Nhịp 60 giây giữ cho người dùng không bấm gửi liên tục và bù cho việc giới hạn tần suất không mang thời gian chờ (BR-ACCOUNT-006). Redesign 2026-10-05 đổi nút bị vô hiệu thành chú thích vì nút bị vô hiệu đọc ở tỉ lệ tương phản 1.83:1.

## Ví dụ

Mã gửi lúc 0:00; đến 0:59 dòng ghi "New code in 0:01"; từ 1:00 là nút "Resend code".

## Edge case

- Đăng nhập lại sang một tài khoản khác khi còn thay đổi chưa gửi: nhấn "Resend code" trước tiên hỏi mất thay đổi (BR-ACCOUNT-010); Huỷ thì không gửi gì.
