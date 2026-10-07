---
id: BR-ACCOUNT-023
title: Huỷ chuyển tài khoản chỉ được trước khi tài khoản đích đăng nhập
status: active
summary: Cancel của lớp chuyển tiếp trả máy về tài khoản nguồn nguyên vẹn, nhưng chỉ cho tới lúc tài khoản đích đăng nhập xong.
superseded_by:
---
## Rule

Khi một chuyển tài khoản (gộp hoặc đổi) đang chạy hay chờ đăng nhập đích, lớp chuyển tiếp MUST có "Cancel" ở đầu trang cho tới khi tài khoản đích đăng nhập xong. Huỷ MUST trả máy về tài khoản nguồn như trước khi bắt đầu: bỏ các bí mật và bản ghi của chuyển tiếp, mở lại cổng ghi, kiểm tra lại phiên của nguồn, và quên tài khoản Google đã chọn. Từ lúc tài khoản đích đã đăng nhập, Cancel MUST NOT còn: chuyển tiếp chỉ đi tiếp. Khi phiên của nguồn đã mất, nguồn MUST được coi là bị từ chối (BR-ACCOUNT-017).

**Enforced by:** `lib/core/auth/account_coordinator_switch.dart` (`cancelSwitch`), `lib/features/account/presentation/states/account_step_state.dart` (`canCancelSwitch`), `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
**Liên quan:** BR-ACCOUNT-011, BR-ACCOUNT-013, BR-ACCOUNT-016, BR-ACCOUNT-024
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.3 #22, §3.4; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.4; detail file [30](../../../shared/ui/screen-handoff/30-sign-in.md)

## Lý do

Trước khi đích đăng nhập, mọi thứ trên máy và trên server còn nguyên, nên huỷ không mất gì. Sau đó SDK đã đổi chủ và một merge có thể đã commit; "một merge đã commit không bao giờ quay lại nguồn" (auth spec §3.4).

## Ví dụ

Người dùng chọn "Switch account" rồi đổi ý ở màn nhập email đích: chạm "Cancel" ở đầu lớp, máy quay về tài khoản cũ và đồng bộ chạy lại. Đã nhập mã của tài khoản đích xong thì không còn Cancel.

## Edge case

- Một lần nhấn Back ở gốc lớp làm việc của Cancel khi Cancel hiện (BR-ACCOUNT-011).
- Đăng xuất dừng khi offline có Cancel riêng và chỉ khi chưa xoá gì (BR-ACCOUNT-014).
- Một merge dừng vì hàng bị server từ chối: Cancel vẫn ở đầu cho tới khi đích đăng nhập; "Continue and lose {n} changes" là đường đi tiếp (BR-ACCOUNT-010).
