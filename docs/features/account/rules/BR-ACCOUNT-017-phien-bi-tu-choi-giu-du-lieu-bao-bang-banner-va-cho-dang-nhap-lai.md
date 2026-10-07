---
id: BR-ACCOUNT-017
title: Phiên bị từ chối giữ dữ liệu, báo bằng banner và chờ đăng nhập lại
status: active
summary: Khi phiên của tài khoản vĩnh viễn bị từ chối, app giữ dữ liệu, tạm dừng đồng bộ và nhắc đăng nhập lại ở Settings, màn 32 và Study home, không chuyển hướng.
superseded_by:
---
## Rule

Khi phiên của một tài khoản vĩnh viễn bị server từ chối (`ReauthRequired`), app MUST giữ dữ liệu máy, MUST tạm dừng đồng bộ, MUST vẫn cho ghi cục bộ (vào outbox của tài khoản đó), và MUST NOT chuyển hướng (BR-ACCOUNT-002). App MUST nhắc bằng "Your sign-in expired. Your decks are still on this phone." kèm "Sign in":

- ở Settings (23): `MxInlineBanner` tông warning dẫn đầu mục Account;
- ở màn 32: cùng banner ở đầu trang, ba lệnh bị vô hiệu (BR-ACCOUNT-018);
- ở Study home (13): `MxFloatingNotice` ở slot notice, chiếm slot của notice đồng bộ vì phiên hết hiệu lực là lý do đồng bộ dừng.

"Sign in" MUST mở màn 30 mode `reauth`: tiêu đề "Sign in again", hàng nhãn "SIGNED OUT · {email}" (email giữ nguyên chữ hoa), ô email điền sẵn email của tài khoản cuối. Đăng nhập lại đúng tài khoản đó MUST kiểm tra lại phiên và nối lại đồng bộ, trả về nơi đã mở (BR-ACCOUNT-004). Đăng nhập lại sang tài khoản khác MUST là một chuyển `discard` đã qua đăng nhập đích, sau khi xác nhận mất thay đổi chưa gửi nếu có (BR-ACCOUNT-010, BR-ACCOUNT-013). "Continue without this account" MUST dọn thiết bị về ẩn danh sau một hộp thoại xác nhận (BR-ACCOUNT-010).

**Enforced by:** `lib/core/auth/account_coordinator.dart` (`_lost`), `lib/core/auth/account_coordinator_leave.dart` (`continueWithoutAccount`, `_afterReauth`), `lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart`, `lib/features/account/presentation/widgets/sections/account_reauth_banner_widget.dart`, `lib/features/account/presentation/widgets/sections/account_reauth_notice_widget.dart`, `lib/features/account/presentation/screens/sign_in_screen.dart`, `lib/features/study/presentation/screens/study_home_screen.dart` (slot `reauthNotice`)
**Liên quan:** BR-ACCOUNT-002, BR-ACCOUNT-004, BR-ACCOUNT-010, BR-ACCOUNT-013, BR-ACCOUNT-018
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.3 #14, #36–#38, §7; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §2 (R2), §5.5, §5.7, §9 (B3, B5, B8, B9); [sign-in redesign](../../../superpowers/specs/2026-10-05-sign-in-flow-redesign-design.md) §3.2; detail file [30](../../../shared/ui/screen-handoff/30-sign-in.md)

## Lý do

Một phiên bị từ chối thường do người dùng thu hồi hoặc token hết hạn, chứ không phải tài khoản biến mất; nên dữ liệu được giữ và người dùng được mời đăng nhập lại thay vì bị đẩy đi. Ruling R2 của brainstorm P3: màn sở hữu vấn đề (Settings, 32) hiện banner, màn không sở hữu (Study home) hiện notice nổi.

## Ví dụ

Phiên bị thu hồi trong lúc app tắt. Mở lại app: Study home hiện notice "Your sign-in expired…" với "Sign in"; người dùng đăng nhập lại cùng email, quay về Study home, đồng bộ chạy lại và không mất thay đổi nào.

## Edge case

- Khi mở app mà SDK giữ một tài khoản khác tài khoản dữ liệu máy thuộc về và còn thay đổi chưa gửi, app cũng vào `ReauthRequired` để việc mất chúng đi qua BR-ACCOUNT-010 (BR-ACCOUNT-013, đường 6).
- Không có session nhưng máy có dữ liệu của một tài khoản vĩnh viễn: coi như phiên bị từ chối, không phải khởi động mới.
- Một mạng đứt không phải lý do vào trạng thái này (BR-ACCOUNT-013).
- Sau "Continue without this account" mở từ đăng nhập lại, luồng đi tới `from` của nó.
