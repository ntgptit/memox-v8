---
id: UC-ACCOUNT-005
title: Admin cấp quyền admin hoặc user cho tài khoản
status: draft
rules: [BR-ACCOUNT-019, BR-ACCOUNT-020, BR-ACCOUNT-021, BR-ACCOUNT-022]
code: [lib/app/router/admin_routes.dart, lib/core/auth/di/auth_providers.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart, lib/features/account/domain/usecases/search_users_use_case.dart, lib/features/account/domain/usecases/set_user_role_use_case.dart, lib/features/account/domain/repositories/user_role_repository.dart, lib/features/account/data/datasources/user_role_remote_data_source.dart, lib/features/account/data/mappers/user_role_mapper.dart, lib/features/account/data/repositories/user_role_repository_impl.dart, lib/features/account/presentation/controllers/users_controller.dart, lib/features/account/presentation/states/users_state.dart, lib/features/account/presentation/screens/users_screen.dart, lib/features/account/presentation/widgets/sections/users_list_widget.dart, lib/features/account/presentation/widgets/items/user_row_widget.dart, lib/features/account/presentation/widgets/items/users_entry_row_widget.dart, lib/features/account/presentation/widgets/overlays/user_role_sheet_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Admin
**Trigger:** Chạm "Users" ("Who can manage the app") trong mục ADMIN của Settings (màn 23), hoặc mở `/settings/users`
**Preconditions:** Tài khoản đã được xác nhận là admin (BR-ACCOUNT-019). Người dùng khác chỉ thấy "Only an admin can see this"
**Mục tiêu:** Admin tìm một tài khoản đã đăng nhập bằng email và đặt nó là admin hoặc user. Màn 33.

## Main flow

**Main flow:**
1. Màn "Users" mở với khung xương trong lúc trang đầu tải, rồi danh sách dưới tiêu đề "ACCOUNTS": mỗi hàng có biểu tượng người, email, "Joined {date}" và huy hiệu "Admin" hoặc "User" (BR-ACCOUNT-020). Hàng của chính admin ghi "Joined {date} · You" và không mở được (BR-ACCOUNT-021).
2. Admin gõ vào "Search by email". 400 ms sau lần gõ cuối app hỏi server; xoá ô thì hiện lại tất cả (BR-ACCOUNT-020).
3. Admin chạm một hàng. Sheet mở với email làm tiêu đề, hai lựa chọn "User" ("Studies and syncs their own decks") và "Admin" ("Sees logs and manages roles"), lựa chọn hiện tại được chọn sẵn; "Save" tắt tới khi chọn khác (BR-ACCOUNT-022).
4. Admin chọn role khác và bấm "Save": nút quay, sheet được giữ. Server lưu; sheet đóng, huy hiệu đổi tại chỗ và toast "{email} is now an admin" hoặc "{email} is now a user".
5. Role đã đổi có hiệu lực ngay trên server; với tài khoản kia, mục ADMIN hiện hoặc ẩn khi app của họ xác nhận lại tài khoản (BR-ACCOUNT-019).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Cuộn tới cuối:** mười dòng cuối vào tầm nhìn thì trang kế tải; hết thì "No more users" (BR-ACCOUNT-020).
- **A2 — Không có kết quả:** "No users match “{query}”" khi có truy vấn, "No accounts yet" khi không.
- **A3 — Kéo xuống để làm mới:** tải lại từ trang đầu, giữ hàng cho tới khi trang mới về.
- **A4 — Bấm hàng của chính mình:** không có gì; admin phải nhờ một admin khác hạ quyền (BR-ACCOUNT-021).
- **A5 — Huỷ sheet:** Cancel đóng sheet, không đổi gì. Trong lúc đang lưu, Back, chạm nền và kéo chờ (BR-ACCOUNT-022).

**Error flows:**
- **E1 — Admin cuối cùng bị hạ:** sheet ở lại với banner "An admin must remain. Make someone else an admin first." (BR-ACCOUNT-022).
- **E2 — Tài khoản ẩn danh được nâng lên admin:** sheet ở lại với banner "This account isn't signed in with an email or Google."
- **E3 — Tài khoản không còn:** sheet đóng, toast "That account no longer exists." và danh sách tải lại.
- **E4 — Mất quyền admin giữa chừng, hoặc không phải admin:** sheet đóng và cả màn thành "Only an admin can see this"; một trang đang tải bị bỏ (BR-ACCOUNT-019, BR-ACCOUNT-022).
- **E5 — Offline hoặc lỗi khác khi lưu:** sheet ở lại với banner "No connection. Nothing changed." hoặc "Couldn't change the role. Nothing changed."; chọn lại xoá banner.
- **E6 — Lỗi khi tải:** offline (cloud-off, Retry) hoặc "Couldn't load users" với Retry; một trang kế lỗi hiện banner danger "Couldn't load more users." với Retry.

## UI

**UI states:** loading (khung xương) · loaded · rỗng ("No users match…" hoặc "No accounts yet") · lỗi (offline, lỗi khác) · không phải admin (khoá, không có ô tìm kiếm) · trang kế đang tải, lỗi, hết. Sheet: role hiện tại · đã chọn khác (Save bật) · đang lưu · bị từ chối (banner warning). Settings (màn 23): mục ADMIN có "Monitoring" rồi "Users", chỉ hiện cho admin.

## Local

**Postconditions:** Không có gì ghi vào Drift: màn này chỉ đọc và ghi qua RPC. Danh sách trong bộ nhớ được cập nhật tại chỗ sau khi lưu.

## API

- `role_list(p_query, p_after)` trả `{items: [{id, email, role, createdAt, lastSignInAt}], next}`; tài khoản không ẩn danh có email, sắp theo email, 50 dòng một trang.
- `role_set(p_user, p_role)` trả `{id, role}`; từ chối `FORBIDDEN`, `INVALID_ROLE`, `NOT_FOUND`, `ANONYMOUS_USER`, `LAST_ADMIN`.
- Lỗi được đưa về `NotAdminFailure` (cả khi không có phiên), `LastAdminFailure`, `AnonymousUserFailure`, `OfflineFailure`, `ServerFailure` ở biên repository.

## Acceptance criteria

- [ ] **Given** một người dùng không phải admin, **when** mở `/settings/users`, **then** màn hiện "Only an admin can see this" dưới thanh tiêu đề "Users", không có ô tìm kiếm và `role_list` không được gọi (BR-ACCOUNT-019).
- [ ] **Given** tài khoản còn đang được xác nhận, **when** màn Users mở, **then** cổng chờ với khung xương, không từ chối (BR-ACCOUNT-019).
- [ ] **Given** admin gõ vào ô tìm kiếm, **when** 400 ms trôi qua sau lần gõ cuối, **then** app hỏi `role_list` một lần với truy vấn đã cắt khoảng trắng, và một thay đổi chỉ khoảng trắng không hỏi lại (BR-ACCOUNT-020).
- [ ] **Given** hai lần tìm liên tiếp, **when** câu trả lời của lần đầu về sau lần hai, **then** nó bị bỏ và danh sách là của lần hai (BR-ACCOUNT-020).
- [ ] **Given** hàng của chính admin, **when** admin chạm nó, **then** không có sheet nào mở và hàng không bị làm mờ (BR-ACCOUNT-021).
- [ ] **Given** sheet role đang mở với role hiện tại được chọn, **when** admin chưa chọn khác, **then** "Save" bị vô hiệu (BR-ACCOUNT-022).
- [ ] **Given** admin chọn "Admin" cho một tài khoản user, **when** bấm "Save" và server lưu, **then** sheet đóng, huy hiệu đổi tại chỗ và toast "{email} is now an admin" hiện (BR-ACCOUNT-022).
- [ ] **Given** chỉ còn một admin, **when** admin hạ nó xuống user, **then** sheet ở lại với "An admin must remain. Make someone else an admin first." và role không đổi (BR-ACCOUNT-022).
- [ ] **Given** một lần lưu đang chạy, **when** admin bấm Back hoặc chạm nền, **then** sheet không đóng cho tới khi có câu trả lời (BR-ACCOUNT-022).
- [ ] **Given** server trả `FORBIDDEN` cho một trang đang tải, **when** câu trả lời về, **then** cả màn thành "not an admin" và không còn hàng nào (BR-ACCOUNT-019, BR-ACCOUNT-020).
