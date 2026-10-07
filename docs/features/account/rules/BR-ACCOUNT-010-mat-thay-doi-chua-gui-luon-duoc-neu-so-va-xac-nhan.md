---
id: BR-ACCOUNT-010
title: Mất thay đổi chưa gửi luôn được nêu số và xác nhận
status: active
summary: Mọi bước làm mất thay đổi chưa gửi lên server phải nói rõ bao nhiêu thay đổi và cần một xác nhận tường minh; cùng email thì không hỏi.
superseded_by:
---
## Rule

Mọi bước làm mất thay đổi chưa được gửi lên server MUST nêu số thay đổi n và MUST cần một xác nhận tường minh trước khi chạy:

1. **Đăng nhập lại sang tài khoản khác** (màn 30 `reauth`, bước mã 31, hoặc Google): hộp thoại "Lose {n} changes?" ("{n} changes on this phone aren't sent and will be lost."), xác nhận "Lose"; sau đó lệnh chạy lại với `confirmedLoss: true`. Cùng email với tài khoản bị từ chối (BR-ACCOUNT-005) MUST NOT hỏi. Không còn thay đổi chưa gửi MUST NOT hỏi. Huỷ MUST NOT gửi gì và MUST quên tài khoản Google đã chọn, để lần bấm sau hiện lại bộ chọn.
2. **"Continue without this account"**: hộp thoại xác nhận; khi còn thay đổi chưa gửi, một banner danger nêu số đó ("{n} changes on this phone aren't sent and will be lost.").
3. **Đăng xuất khi offline** còn thay đổi chưa gửi (BR-ACCOUNT-014): hộp thoại "Sign out and lose changes?" và nút "Sign out now and lose {n} changes" ở lớp chuyển tiếp.
4. **Merge dừng vì hàng server từ chối** (`UnsentChangesFailure` ở bước gửi nguồn): lớp chuyển tiếp nói "{n} changes on this phone were refused by the server and can't be merged." và "Continue and lose {n} changes" giữ chúng trên máy rồi thử lại.

Đếm MUST là số thay đổi trong outbox cộng hàng bị server từ chối (`pendingCount`).

**Enforced by:** `lib/core/auth/account_coordinator_leave.dart` (`_checkReplace`, ném `UnsentChangesFailure`), `lib/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart` (`confirmUnsentLoss`), `lib/features/account/presentation/screens/sign_in_screen.dart` (`_leave`), `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
**Liên quan:** BR-ACCOUNT-005, BR-ACCOUNT-014, BR-ACCOUNT-013
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.2, §5.4, §9 (B4, B8) và §9.1; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.3 #19, #37–#39; detail file [30](../../../shared/ui/screen-handoff/30-sign-in.md)

## Lý do

Những thay đổi này chỉ tồn tại trên máy: mất chúng là mất dữ liệu người dùng, và người dùng không thấy chúng. Nên mỗi đường dẫn tới mất dữ liệu phải nói rõ số lượng và không bao giờ im lặng.

## Ví dụ

Phiên của `an@example.com` hết hiệu lực khi còn 3 thay đổi chưa gửi. Người dùng đăng nhập lại bằng `binh@example.com`: hộp thoại "Lose 3 changes?". Đăng nhập lại bằng `An@Example.com` thì không hỏi gì.

## Edge case

- Gắn tài khoản (`link`) và đăng nhập đích trong lớp chuyển tiếp không hỏi theo mục 1: nguồn đã được gửi trước khi đích đăng nhập.
- "Switch account" (màn 32) offline với thay đổi chưa gửi dừng ở bước gửi với Retry, không có đường "mất rồi đi tiếp"; nó chờ mạng.
- Một Google credential không có email không khớp email nào (BR-ACCOUNT-005), nên hỏi khi còn thay đổi chưa gửi.
