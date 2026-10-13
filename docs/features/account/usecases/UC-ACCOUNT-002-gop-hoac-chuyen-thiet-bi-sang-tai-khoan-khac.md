---
id: UC-ACCOUNT-002
title: Gộp hoặc chuyển thiết bị sang tài khoản khác
status: draft
rules: [BR-ACCOUNT-008, BR-ACCOUNT-009, BR-ACCOUNT-010, BR-ACCOUNT-011, BR-ACCOUNT-012, BR-ACCOUNT-013, BR-ACCOUNT-016, BR-ACCOUNT-023, BR-ACCOUNT-024]
code: [lib/core/auth/account_coordinator.dart, lib/core/auth/account_coordinator_switch.dart, lib/core/auth/account_transition.dart, lib/core/database/local_data_reset.dart, lib/features/account/domain/usecases/count_local_library_use_case.dart, lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart, lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart, lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart, lib/features/account/presentation/states/account_step_state.dart, lib/features/account/presentation/screens/account_screen.dart, lib/features/account/presentation/controllers/account_manage_controller.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** (a) Một đăng nhập từ người dùng ẩn danh (email hoặc Google) trùng một tài khoản đã có; (b) "Switch account" ở màn 32
**Preconditions:** (a) Thiết bị có người dùng ẩn danh đã xác nhận, đang ở luồng của UC-ACCOUNT-001; (b) thiết bị giữ một tài khoản đã xác nhận (`Ready`), có mạng để gửi thay đổi (BR-ACCOUNT-018)
**Mục tiêu:** Đưa dữ liệu trên máy sang tài khoản khác mà không mất gì ngoài điều người dùng đã chọn: gộp vào tài khoản đó, hoặc bỏ dữ liệu máy để lấy dữ liệu của tài khoản kia. Sheet gộp và lớp chuyển tiếp của màn 30; màn 32 cho "Switch account".

## Main flow

**Main flow (a, gộp hoặc bỏ):**
1. Email hoặc Google trùng một tài khoản đã có. App kiểm máy có deck sống không (BR-ACCOUNT-008). Có: sheet "{email} already has an account" hiện với "Merge into the account" chọn sẵn và "Discard this phone's data" (BR-ACCOUNT-009).
2. Người dùng bấm "Continue" (gộp) hoặc chọn bỏ rồi bấm "Discard data". App bắt đầu chuyển: cổng ghi đóng và lớp chuyển tiếp che toàn app (BR-ACCOUNT-011).
3. Lớp nói từng bước: "Sending your changes…" (gửi thay đổi chưa gửi và log dưới tài khoản hiện tại), với gộp "Getting your decks ready…" (lấy claim), kèm "Nothing is lost if you close the app."
4. Lớp chuyển sang đăng nhập tài khoản đích: tiêu đề "Sign in", câu "Sign in to the account this phone moves to.", ô email điền sẵn địa chỉ đã gõ (Google dùng lại tài khoản đã chọn, không chọn lại), "Cancel" ở đầu (BR-ACCOUNT-023). Email thì mã được nhập ngay trong lớp.
5. Tài khoản đích đăng nhập xong. Với gộp, "Merging…": server chuyển mọi hàng của người dùng ẩn danh sang tài khoản đích; sau đó, hoặc với bỏ, dữ liệu máy bị xoá (BR-ACCOUNT-013).
6. "Downloading your decks…": dữ liệu của tài khoản đích được kéo về; với gộp, app báo server đã kéo xong. Cổng ghi mở, lớp biến mất, tài khoản mới được xác nhận.

**Main flow (b, Switch account ở màn 32):**
1. Người dùng bấm "Switch account"; hộp thoại "Switch account?" hiện luôn, không đếm thư viện (BR-ACCOUNT-016).
2. Xác nhận "Switch": lớp gửi thay đổi dưới tài khoản hiện tại, rồi đăng nhập tài khoản đích (bước 4 ở trên), xoá dữ liệu máy và kéo dữ liệu của tài khoản đích về (bước 5, 6). Không có người dùng ẩn danh ở giữa.

## Alternative / Error flow

**Alternative flows:**
- **A1 — Máy không có deck sống:** không sheet và không hỏi; app chọn bỏ và vào thẳng bước 2 (BR-ACCOUNT-008). Trash và tag không được tính ở bước này.
- **A2 — Không đếm được thư viện:** sheet vẫn hiện, nhãn gộp là "This phone's decks and cards join it." không kèm số (BR-ACCOUNT-008, BR-ACCOUNT-009).
- **A3 — Huỷ sheet:** không có chuyển nào bắt đầu (BR-ACCOUNT-009). Welcome, nếu đang mở, vẫn chưa trả lời.
- **A4 — Huỷ trong lớp:** "Cancel" hoặc Back, trước khi đích đăng nhập xong: máy về tài khoản cũ nguyên vẹn, cổng mở, đồng bộ chạy lại (BR-ACCOUNT-023).
- **A5 — Claim bị từ chối** (hết 15 phút hoặc đã dùng): không gì đã chuyển; máy về tài khoản cũ với đủ dữ liệu và "Couldn't merge. Your decks are still on this phone." (BR-ACCOUNT-024).
- **A6 — Đóng app giữa chừng:** mở lại, lớp tiếp tục đúng thao tác từ stage đã lưu, không nhân đôi deck (BR-ACCOUNT-012).
- **A7 — Gộp dừng vì hàng bị server từ chối:** "{n} changes on this phone were refused by the server and can't be merged." với Retry và "Continue and lose {n} changes" (giữ chúng trên máy rồi thử lại); Cancel còn ở đầu (BR-ACCOUNT-010). Một chuyển bỏ không dừng ở đây.

**Error flows:**
- **E1 — Mất mạng:** lớp dừng, "No connection. Your data is safe on this phone." với Retry; thao tác tiếp tục khi có mạng hoặc khi Retry (BR-ACCOUNT-012).
- **E2 — Lỗi khác:** "Something went wrong. Your data is safe on this phone." với Retry.
- **E3 — Trạng thái bị kẹt** (không thể xảy ra theo bảng chuyển tiếp): "Something went wrong while moving your account. Your data is safe on this phone." với Retry; cổng ghi vẫn đóng; không có Cancel.
- **E4 — Chuyển bị từ chối khi bắt đầu:** từ sheet gộp, toast có kiểu của lỗi, hoặc "Nothing was lost. The account step didn't finish. Try again." khi tài khoản đã đổi trạng thái trong lúc đó; từ màn 32, toast "No connection. Nothing changed; try again when you're online." hoặc "Couldn't finish that. Nothing changed; try again."

## UI

**UI states:** Sheet gộp: gộp chọn sẵn · bỏ chọn (banner danger và nút "Discard data") · không đếm được. Lớp: đang chạy từng bước · đăng nhập đích (form rồi mã) · lỗi mạng · lỗi khác · bị kẹt · gộp dừng vì hàng bị từ chối. Hộp thoại "Switch account?" ở màn 32. Lớp che app khỏi TalkBack; dòng trạng thái là live region. Không có trạng thái rỗng.

## Local

**Postconditions:** Dữ liệu trên máy là của tài khoản đích: gộp thì hợp của hai bên (tag cùng tên được gộp, `server_version` mới), bỏ thì chỉ dữ liệu của tài khoản đích. `LocalDataReset` xoá deck, card, tag, Trash, outbox, con trỏ đồng bộ; giữ `welcome_seen`, id thiết bị và log (BR-ACCOUNT-013). Bản ghi chuyển tiếp và bí mật (bản sao lưu phiên cũ, claim) bị bỏ ở cuối.

## API

- RPC cho gộp: `account_claim_begin()` (chỉ người dùng ẩn danh), `account_merge(token, operation_id)` (idempotent theo `operation_id`, trả `MERGED` khi gửi lại), `account_merge_ack(operation_id)`.
- Đồng bộ: gửi outbox dưới tài khoản nguồn, kéo toàn bộ dưới tài khoản đích; gửi log của máy trước khi SDK đổi tài khoản.
- GoTrue: `signInWithOtp`/`verifyOTP(email)` hoặc `signInWithIdToken` cho đích; bản sao lưu refresh token của nguồn và claim nằm trong Secure Storage.

## Acceptance criteria

- [ ] **Given** máy chỉ có deck trong Trash, **when** một email trùng một tài khoản đã có, **then** không có sheet và app chọn bỏ, và Trash bị xoá cùng dữ liệu máy (BR-ACCOUNT-008, BR-ACCOUNT-013).
- [ ] **Given** máy có ba deck sống, **when** một email trùng một tài khoản đã có, **then** sheet hiện với "Merge into the account" chọn sẵn và nhãn nêu số deck và thẻ (BR-ACCOUNT-008, BR-ACCOUNT-009).
- [ ] **Given** sheet gộp đang mở, **when** người dùng chọn "Discard this phone's data", **then** banner danger hiện và nút xác nhận thành "Discard data" destructive; Huỷ không bắt đầu chuyển (BR-ACCOUNT-009).
- [ ] **Given** một chuyển đang chạy, **when** người dùng cố ghi hoặc bấm Back, **then** mọi ghi nghiệp vụ bị từ chối và Back không lọt ra app bên dưới (BR-ACCOUNT-011).
- [ ] **Given** một chuyển chưa qua đăng nhập đích, **when** người dùng bấm "Cancel" ở lớp, **then** máy về tài khoản cũ với đủ dữ liệu và cổng ghi mở (BR-ACCOUNT-023).
- [ ] **Given** tài khoản đích đã đăng nhập, **when** lớp đang chạy, **then** "Cancel" không còn và chuyển chỉ đi tiếp (BR-ACCOUNT-023).
- [ ] **Given** server từ chối claim của một merge, **when** tài khoản đích đã đăng nhập, **then** app khôi phục tài khoản nguồn, giữ dữ liệu máy và hiện "Couldn't merge. Your decks are still on this phone." (BR-ACCOUNT-024).
- [ ] **Given** mạng đứt giữa lúc merge, **when** mạng trở lại hoặc người dùng bấm Retry, **then** cùng thao tác tiếp tục, không nhân đôi deck và không xoá dữ liệu máy trước khi merge commit (BR-ACCOUNT-012, BR-ACCOUNT-013).
- [ ] **Given** một gộp dừng vì hàng bị server từ chối, **when** người dùng bấm "Continue and lose {n} changes", **then** các hàng đó được giữ trên máy rồi thử lại (BR-ACCOUNT-010).
- [ ] **Given** thiết bị giữ một tài khoản đã xác nhận, **when** người dùng bấm "Switch account" và xác nhận, **then** hộp thoại hiện bất kể máy có dữ liệu hay không, chuyển là bỏ (không có lựa chọn gộp) và không có người dùng ẩn danh ở giữa (BR-ACCOUNT-016).
