---
id: UC-ACCOUNT-003
title: Đăng nhập lại khi phiên hết hiệu lực
status: draft
rules: [BR-ACCOUNT-002, BR-ACCOUNT-004, BR-ACCOUNT-005, BR-ACCOUNT-006, BR-ACCOUNT-007, BR-ACCOUNT-010, BR-ACCOUNT-013, BR-ACCOUNT-017, BR-ACCOUNT-018]
code: [lib/core/auth/account_coordinator.dart, lib/core/auth/account_coordinator_switch.dart, lib/core/auth/account_coordinator_leave.dart, lib/app/router/account_routes.dart, lib/features/account/presentation/screens/sign_in_screen.dart, lib/features/account/presentation/screens/code_screen.dart, lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart, lib/features/account/presentation/widgets/sections/code_form_widget.dart, lib/features/account/presentation/widgets/sections/account_reauth_banner_widget.dart, lib/features/account/presentation/widgets/sections/account_reauth_notice_widget.dart, lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart, lib/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart, lib/features/account/presentation/controllers/account_manage_controller.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm "Sign in" ở banner "Your sign-in expired. Your decks are still on this phone." trên Settings (màn 23) hoặc màn 32, hoặc ở notice nổi trên Study home (màn 13)
**Preconditions:** Thiết bị giữ một tài khoản vĩnh viễn mà phiên đã bị server từ chối (`ReauthRequired`); dữ liệu máy còn nguyên và đồng bộ đang tạm dừng (BR-ACCOUNT-017)
**Mục tiêu:** Đăng nhập lại để đồng bộ nối lại mà không mất gì; hoặc, theo ý người dùng, đăng nhập sang tài khoản khác hay bỏ tài khoản này. Màn 30 mode `reauth`, màn 31, và các banner.

## Main flow

**Main flow:**
1. Phiên bị từ chối (đã hết hiệu lực, bị thu hồi). App không chuyển hướng (BR-ACCOUNT-002); nó nhắc bằng banner ở mục Account của Settings và đầu màn 32, hoặc notice ở Study home, và các lệnh ở màn 32 bị vô hiệu (BR-ACCOUNT-017, BR-ACCOUNT-018).
2. Người dùng chạm "Sign in". Màn 30 mở ở `reauth` với `from` là nơi đã mở (BR-ACCOUNT-004): hàng "SIGNED OUT · {email}", tiêu đề "Sign in again", câu "This phone was signed out, so syncing paused. Your decks are still here.", ô email điền sẵn email của tài khoản cuối, "Continue without this account" bên dưới ô; chân trang có "Send code" và "Continue with Google".
3. Người dùng bấm "Send code" với địa chỉ điền sẵn (hoặc chọn Google). Địa chỉ được kiểm (BR-ACCOUNT-005); mã gửi đi và màn 31 mở (BR-ACCOUNT-006, BR-ACCOUNT-007).
4. Mã đúng, cùng tài khoản: app kiểm tra lại phiên, nối lại đồng bộ, hiện "Signed in as {email}" và quay về nơi đã mở. Không mất thay đổi nào.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Sang tài khoản khác:** địa chỉ (hoặc tài khoản Google) khác tài khoản cuối. Còn thay đổi chưa gửi thì hộp thoại "Lose {n} changes?" ("{n} changes on this phone aren't sent and will be lost.") hiện trước khi gửi mã hoặc chọn Google; "Lose" cho lệnh chạy tiếp (BR-ACCOUNT-010). Sau khi đích đăng nhập, dữ liệu máy bị xoá và dữ liệu của tài khoản đó được kéo về, như một chuyển bỏ đã qua đăng nhập đích (BR-ACCOUNT-013, UC-ACCOUNT-002). Cùng email (khác hoa thường, thừa khoảng trắng) không hỏi gì.
- **A2 — Huỷ hộp thoại mất thay đổi:** không gửi gì; tài khoản Google đã chọn bị quên, lần bấm sau hiện lại bộ chọn (BR-ACCOUNT-010).
- **A3 — Gửi lại mã sang tài khoản khác ở màn 31:** cũng hỏi "Lose {n} changes?" trước khi gửi (BR-ACCOUNT-010, BR-ACCOUNT-007).
- **A4 — Continue without this account:** hộp thoại "Continue without this account?" ("This phone's decks from {email} are removed. Sign in to {email} later to get them back.") với banner danger nêu số thay đổi chưa gửi nếu có. Xác nhận "Continue" dọn thiết bị về một người dùng ẩn danh mới qua lớp chuyển tiếp rồi luồng đi tới `from` (BR-ACCOUNT-010, BR-ACCOUNT-013).
- **A5 — Mở app mà SDK giữ một tài khoản khác dữ liệu máy:** còn thay đổi chưa gửi thì app vào `ReauthRequired` để việc mất chúng đi qua A1; không còn thì máy tự nhận tài khoản của SDK, không hỏi (BR-ACCOUNT-013).
- **A6 — Quay lại:** Back từ màn 30 hoặc 31 để lại `ReauthRequired` như cũ; banner còn đó.

**Error flows:**
- **E1 — Địa chỉ không hợp lệ, mã sai, giới hạn tần suất, offline, lỗi khác:** như UC-ACCOUNT-001 (BR-ACCOUNT-005, BR-ACCOUNT-006).
- **E2 — Màn 30 không dùng được:** khi không còn ở `ReauthRequired` (đã nối lại ở nơi khác), form bị vô hiệu.
- **E3 — Một lệnh bị từ chối trước khi đổi gì:** "Continue without this account" mà bị từ chối hiện toast "No connection. Nothing changed; try again when you're online." hoặc "Couldn't finish that. Nothing changed; try again."

## UI

**UI states:** Banner (màn 23 và 32, `MxInlineBanner` warning) · notice nổi (màn 13, chiếm slot notice của đồng bộ) · màn 30 reauth: bình thường, đang gửi, đang chọn Google, hộp thoại mất thay đổi, hộp thoại continue without (có hoặc không banner danger) · màn 31 như UC-ACCOUNT-001. Không có trạng thái rỗng.

## Local

**Postconditions:** Cùng tài khoản: dữ liệu và outbox nguyên, đồng bộ chạy lại. Tài khoản khác hoặc continue without: dữ liệu máy bị xoá, thay đổi chưa gửi mất như đã xác nhận (BR-ACCOUNT-013). `welcome_seen` không đổi.

## API

- GoTrue: `signInWithOtp`/`verifyOTP(email)` hoặc `signInWithIdToken`; RPC `me()` kiểm tra lại phiên; với tài khoản khác thì kéo toàn bộ dữ liệu của đích.
- `continueWithoutAccount` dọn qua `LocalDataReset` mà không gọi server; tài khoản trên server giữ nguyên.

## Acceptance criteria

- [ ] **Given** phiên của một tài khoản vĩnh viễn bị từ chối, **when** app mở, **then** không có chuyển hướng, dữ liệu máy còn nguyên, và Settings, màn 32 và Study home nhắc đăng nhập lại (BR-ACCOUNT-017, BR-ACCOUNT-002).
- [ ] **Given** màn 32 ở `ReauthRequired`, **when** người dùng nhìn các hàng lệnh, **then** "Switch account", "Sign out" và "Delete account" bị vô hiệu và banner đăng nhập lại hiện ở đầu (BR-ACCOUNT-018, BR-ACCOUNT-017).
- [ ] **Given** màn 30 ở mode `reauth` với email của tài khoản cuối, **when** nó hiện, **then** ô email điền sẵn, hàng "SIGNED OUT · {email}" giữ nguyên chữ hoa và "Continue without this account" nằm dưới ô (BR-ACCOUNT-017).
- [ ] **Given** đăng nhập lại đúng tài khoản cũ, **when** mã đúng, **then** đồng bộ nối lại, "Signed in as {email}" hiện và app quay về nơi đã mở (BR-ACCOUNT-017, BR-ACCOUNT-004).
- [ ] **Given** còn 3 thay đổi chưa gửi, **when** người dùng bấm "Send code" với email của một tài khoản khác, **then** "Lose 3 changes?" hiện trước khi mã được gửi; Huỷ không gửi gì (BR-ACCOUNT-010).
- [ ] **Given** còn thay đổi chưa gửi, **when** người dùng nhập cùng email nhưng khác hoa thường hoặc có khoảng trắng thừa, **then** không có hộp thoại mất thay đổi (BR-ACCOUNT-005, BR-ACCOUNT-010).
- [ ] **Given** còn 3 thay đổi chưa gửi, **when** người dùng mở "Continue without this account", **then** hộp thoại nêu 3 thay đổi sẽ mất và chỉ sau xác nhận thiết bị mới về ẩn danh (BR-ACCOUNT-010, BR-ACCOUNT-013).
- [ ] **Given** một đăng nhập lại đang mở với `from=//example.com`, **when** nó kết thúc, **then** app về `/settings` (BR-ACCOUNT-004).
