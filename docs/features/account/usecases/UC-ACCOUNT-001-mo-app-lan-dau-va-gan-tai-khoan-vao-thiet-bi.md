---
id: UC-ACCOUNT-001
title: Mở app lần đầu và gắn tài khoản vào thiết bị
status: draft
rules: [BR-ACCOUNT-001, BR-ACCOUNT-002, BR-ACCOUNT-003, BR-ACCOUNT-004, BR-ACCOUNT-005, BR-ACCOUNT-006, BR-ACCOUNT-007]
code: [lib/app/startup_welcome.dart, lib/app/router/account_redirect.dart, lib/app/router/account_routes.dart, lib/core/auth/account_coordinator_switch.dart, lib/features/account/presentation/screens/welcome_screen.dart, lib/features/account/presentation/screens/sign_in_screen.dart, lib/features/account/presentation/screens/code_screen.dart, lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart, lib/features/account/presentation/widgets/sections/code_form_widget.dart, lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart, lib/features/account/presentation/controllers/sign_in_controller.dart, lib/features/account/presentation/controllers/code_controller.dart, lib/features/account/presentation/providers/welcome_due_provider.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Mở app lần đầu trên thiết bị (Welcome, màn 29); hoặc bấm "Sign in" ở mục Account của Settings (màn 23)
**Preconditions:** Bản build có project Supabase. Muốn gắn tài khoản, thiết bị có người dùng ẩn danh đã được xác nhận và có mạng; muốn bỏ qua thì không cần gì (BR-ACCOUNT-002)
**Mục tiêu:** Mời người dùng gắn email hoặc Google vào **cùng** người dùng ẩn danh của thiết bị để dữ liệu đi theo họ, mà không bắt buộc. Màn 29, 30 (mode `link`) và 31.

## Main flow

**Main flow:**
1. Lần mở đầu tiên, router đưa mọi vị trí tới Welcome (BR-ACCOUNT-001). Welcome nói app dùng được mà không cần tài khoản, kể cả offline, và đăng nhập thêm hai việc: giữ bộ thẻ khi cài lại, học trên nhiều điện thoại. Ba lối đi: "Continue with Google", "Continue with email", "Continue without an account".
2. Người dùng chọn "Continue with email". Welcome được trả lời và màn 30 mở trên Settings (BR-ACCOUNT-001, BR-ACCOUNT-004). Mở từ Settings thì vào đúng màn 30 từ hàng "Sign in".
3. Màn 30 hiện tiêu đề "Sign in", câu "Your decks stay on this phone and join the account." và ô "Email address". Người dùng nhập địa chỉ và bấm "Send code". Địa chỉ được kiểm trước khi gửi (BR-ACCOUNT-005).
4. Mã sáu chữ số được gửi tới địa chỉ; màn 31 mở với địa chỉ nằm riêng một dòng để lỗi gõ dễ thấy.
5. Người dùng nhập sáu chữ số. Mã được kiểm ngay chữ số thứ sáu (BR-ACCOUNT-006); đếm ngược "New code in m:ss" chạy 60 giây trước khi gửi lại được (BR-ACCOUNT-007).
6. Mã đúng: email gắn vào người dùng ẩn danh hiện có (cùng id người dùng, không có dữ liệu nào đổi chủ trên server), app xác nhận tài khoản và hiện "Signed in as {email}". Luồng kết thúc ở màn 32 (BR-ACCOUNT-004).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Continue without an account:** Welcome được trả lời, app đi tới vị trí đã xin (`from`, mặc định `/decks`), người dùng ẩn danh dùng app bình thường (BR-ACCOUNT-001, BR-ACCOUNT-002). Đăng nhập vẫn mở được từ Settings sau.
- **A2 — Google thay cho email:** "Continue with Google" mở bộ chọn tài khoản Google; chọn xong thì Google được gắn vào người dùng hiện tại, không qua màn 31, và luồng kết thúc như bước 6. Huỷ bộ chọn không làm gì và không báo gì. Ở Welcome, Google đăng nhập xong thì đi tới `from`.
- **A3 — Tài khoản đã có:** email hoặc tài khoản Google đã thuộc một tài khoản khác. Việc gộp hoặc bỏ dữ liệu máy thuộc UC-ACCOUNT-002.
- **A4 — Chưa thể gắn:** thiết bị chưa có người dùng ẩn danh đã xác nhận (offline lần đầu, đang kiểm tra). Welcome chỉ còn "Continue without an account" làm nút chính, với dòng "Signing in needs a connection. Try later in Settings."; màn 30 vô hiệu "Send code" và Google với cùng dòng; hàng Settings ghi "Available when you're online". Khi gắn được lại, các nút trở lại (BR-ACCOUNT-002).
- **A5 — Đã có tài khoản:** thiết bị đã giữ tài khoản mà mở lại màn 30 ở mode `link` thì được chuyển tới màn 32 (BR-ACCOUNT-003).
- **A6 — Gửi lại hoặc đổi địa chỉ:** hết 60 giây, "Resend code" gửi mã mới ("A new code is on its way.") và đếm lại. "Use another email" quay về màn 30.

**Error flows:**
- **E1 — Địa chỉ không hợp lệ:** "Enter an email address, like name@example.com." dưới ô; không gửi gì; "Send code" vẫn bấm được (BR-ACCOUNT-005).
- **E2 — Mã sai hoặc hết hạn:** "That code is wrong or has expired. Check the latest email."; ô mã trống lại và nhận mã mới (BR-ACCOUNT-006).
- **E3 — Bị giới hạn tần suất:** "Too many tries. Wait a minute, then try again." (BR-ACCOUNT-006).
- **E4 — Offline:** "No connection. Nothing changed; try again when you're online."
- **E5 — Lỗi khác:** "Couldn't sign in. Nothing changed; try again." Lỗi của Google hiện thành toast.
- **E6 — Cờ Welcome không ghi được:** chỉ làm Welcome hiện lại ở lần mở sau (BR-ACCOUNT-001).

## UI

**UI states:** Welcome: sẵn sàng (ba lối) · offline (một lối chính và dòng ghi chú). Màn 30: bình thường · đang gửi mã (nút quay) · đang chọn Google (nút quay) · địa chỉ không hợp lệ · chưa thể gắn (dòng offline ở chân trang). Màn 31: chờ gửi lại · đang kiểm (spinner ở dòng trạng thái) · mã sai · gửi lại được · đang gửi lại. Bàn phím mở trên màn 30 thì chân trang chỉ giữ "Send code" để ô nhập còn trong tầm nhìn. Không có trạng thái rỗng: không màn nào của UC liệt kê dữ liệu.

## Local

**Postconditions:** `app_settings.welcome_seen = 1` (cột chỉ của máy, ghi không qua cổng ghi nghiệp vụ). Người dùng ẩn danh trở thành tài khoản vĩnh viễn với cùng id; dữ liệu trên máy không đổi (BR-ACCOUNT-013 không áp dụng: không có gì bị xoá). Đồng bộ chạy lại sau khi `me()` xác nhận tài khoản.

## API

- GoTrue: `updateUser(email)` rồi `verifyOTP(emailChange)` cho email; `linkIdentityWithIdToken` cho Google (sau bộ chọn gốc của `google_sign_in`). Mã và token Google không được ghi xuống đâu cả.
- RPC `me()`: xác nhận tài khoản và role (`lib/core/auth/`).
- Lỗi `email_exists`, `identity_already_exists` thành `IdentityTakenFailure` (A3); `otp_expired` thành mã sai; 429 và `over_*_rate_limit` thành giới hạn tần suất.

## Acceptance criteria

- [ ] **Given** một thiết bị chưa trả lời Welcome, **when** app mở bằng deep link tới `/study`, **then** Welcome hiện trước và "Continue without an account" đưa người dùng tới `/study` (BR-ACCOUNT-001, BR-ACCOUNT-004).
- [ ] **Given** thiết bị đã trả lời Welcome, **when** app mở lại, đặt lại cài đặt hoặc đăng xuất, **then** Welcome không hiện lại (BR-ACCOUNT-001).
- [ ] **Given** thiết bị chưa có người dùng ẩn danh đã xác nhận, **when** Welcome hiện, **then** chỉ "Continue without an account" dùng được, là nút chính, với dòng "Signing in needs a connection. Try later in Settings." (BR-ACCOUNT-002).
- [ ] **Given** người dùng đang ở màn 30 mode `link`, **when** nhập `an@@example.com` và bấm "Send code", **then** lỗi hiện dưới ô, không mã nào được gửi và nút vẫn bấm được (BR-ACCOUNT-005).
- [ ] **Given** màn 31 đang mở cho `an@example.com`, **when** người dùng gõ chữ số thứ sáu, **then** mã được kiểm ngay không cần nút, ô mã chỉ-đọc và dòng trạng thái quay trong lúc kiểm (BR-ACCOUNT-006).
- [ ] **Given** một mã sai, **when** việc kiểm trả lời, **then** ô mã được xoá và hiện "That code is wrong or has expired. Check the latest email." (BR-ACCOUNT-006).
- [ ] **Given** một mã vừa được gửi, **when** chưa đủ 60 giây, **then** dòng trạng thái là chú thích "New code in m:ss" và không có nút gửi lại; hết 60 giây thì "Resend code" hiện (BR-ACCOUNT-007).
- [ ] **Given** mã đúng, **when** tài khoản được xác nhận, **then** toast "Signed in as {email}" hiện và luồng kết thúc ở màn 32 (BR-ACCOUNT-004).
- [ ] **Given** thiết bị đã giữ một tài khoản vĩnh viễn, **when** mở `/settings/sign-in?mode=link`, **then** router chuyển tới `/settings/account` (BR-ACCOUNT-003).
- [ ] **Given** một `from` là `https://example.com`, **when** Welcome hoặc đăng nhập kết thúc, **then** `from` bị bỏ và app dùng vị trí mặc định (BR-ACCOUNT-004).
