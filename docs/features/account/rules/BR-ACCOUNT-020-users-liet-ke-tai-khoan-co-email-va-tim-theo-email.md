---
id: BR-ACCOUNT-020
title: Users liệt kê tài khoản có email và tìm theo email
status: active
summary: Màn Users chỉ liệt kê tài khoản không ẩn danh có email, sắp theo email, 50 dòng một trang, tìm theo email sau 400 ms.
superseded_by:
---
## Rule

Màn Users (màn 33) MUST liệt kê chỉ các tài khoản không ẩn danh có email, sắp theo email, tối đa 50 dòng một trang; `next` là email cuối của trang khi còn trang sau. Tìm kiếm MUST theo email, khớp một phần và không phân biệt hoa thường; một truy vấn rỗng MUST liệt kê tất cả.

Ô tìm kiếm MUST chỉ hỏi server 400 ms sau lần gõ cuối; văn bản MUST được cắt khoảng trắng hai đầu, và một thay đổi chỉ khoảng trắng MUST NOT hỏi lại. Một lần hỏi từ trang đầu (tìm, kéo làm mới, thử lại) MUST thay mọi câu trả lời của lần hỏi trước, nên một câu trả lời chậm không ghi đè câu mới. Trang kế MUST tải khi mười dòng cuối vào tầm nhìn, đến cuối hiện "No more users"; một trang lỗi hiện banner danger với Retry. Một trang bị từ chối vì không phải admin MUST chuyển cả màn sang trạng thái "not an admin" (BR-ACCOUNT-019).

**Enforced by:** server (`public.role_list`, `supabase/migrations/20261010000000_accounts.sql`); app: `lib/features/account/presentation/controllers/users_controller.dart`, `lib/features/account/domain/usecases/search_users_use_case.dart` (cắt khoảng trắng), `lib/features/account/presentation/widgets/sections/users_list_widget.dart`
**Liên quan:** BR-ACCOUNT-019, BR-ACCOUNT-021, BR-ACCOUNT-022
**Nguồn:** [users spec](../../../superpowers/specs/2026-09-30-users-admin-design.md) §2, §3, §6; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §2.3; detail file [33](../../../shared/ui/screen-handoff/33-users.md)

## Lý do

Người dùng ẩn danh không có email để tìm và không thể là admin, nên không có trong danh sách. Màn 28 là khuôn mẫu: phân trang theo cuối cuộn, không có nút "Load more" (users spec §6).

## Ví dụ

Gõ `an@` và dừng 400 ms: app hỏi `role_list` với `p_query = "an@"` và hiện các tài khoản có email chứa `an@`. Xoá ô tìm: hiện lại tất cả.

## Edge case

- Không có số tổng: tiêu đề "ACCOUNTS" không kèm số vì `role_list` không trả tổng.
- Rỗng không có truy vấn: "No accounts yet"; rỗng có truy vấn: "No users match “{query}”".
- Offline: "offline" trước, Retry; lỗi khác: "Couldn't load users" với Retry.
