---
id: BR-ACCOUNT-024
title: Merge bị server từ chối thì quay về tài khoản nguồn nguyên vẹn
status: active
summary: Khi server từ chối claim của merge, app khôi phục tài khoản nguồn với dữ liệu máy nguyên vẹn và nói "Couldn't merge"; không có gì bị xoá.
superseded_by:
---
## Rule

Khi `account_merge` từ chối claim (`CLAIM_INVALID`: token hết hạn sau 15 phút hoặc đã được dùng, và không có biên nhận cho `operation_id`), không có gì đã được chuyển trên server. App MUST khôi phục phiên của tài khoản nguồn từ bản sao lưu trong Secure Storage, bỏ các bí mật và bản ghi của chuyển tiếp, mở lại cổng ghi, kiểm tra lại phiên, và hiện thông báo "Couldn't merge. Your decks are still on this phone." Dữ liệu máy MUST NOT bị xoá.

Khi không khôi phục được phiên nguồn (không còn bản sao lưu, hoặc phiên đó cũng bị từ chối), app MUST đăng xuất cục bộ khỏi tài khoản đích để nó không bao giờ thấy dữ liệu của nguồn, rồi tạo một người dùng ẩn danh mới nhận dữ liệu máy và đẩy lại toàn bộ thư viện, cũng với thông báo trên. Khi mất mạng lúc khôi phục, app MUST giữ bản ghi và thử lại cùng thao tác khi có mạng (BR-ACCOUNT-012).

**Enforced by:** server (`public.account_merge` tiêu thụ token nguyên tử và trả `CLAIM_INVALID`, `supabase/migrations/20261010000000_accounts.sql`); app: `lib/core/auth/account_coordinator_switch.dart` (`_advanceTarget`, `_mergeRefused`), `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart` (thông báo)
**Liên quan:** BR-ACCOUNT-012, BR-ACCOUNT-013, BR-ACCOUNT-023
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §2.3, §3.3 #23–#25, §3.4; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.4

## Lý do

Bất biến của auth spec §3.4: "an uncommitted merge never clears A's local data". Dữ liệu máy chỉ bị xoá sau khi merge đã commit.

## Ví dụ

Người dùng chọn gộp, rồi để máy chờ hơn 15 phút trước khi nhập mã của tài khoản đích. Claim hết hạn; sau mã, app báo "Couldn't merge. Your decks are still on this phone." và người dùng vẫn đang ở tài khoản ẩn danh cũ với đủ dữ liệu.

## Edge case

- Một merge đã commit mà câu trả lời bị mất: gửi lại cùng `operation_id` nhận `MERGED` từ biên nhận (không phải `CLAIM_INVALID`), bản sao lưu của nguồn bị bỏ và chuyển tiếp đi tiếp; không có thông báo lỗi.
- Biên nhận ở lại tới khi app báo đã kéo xong (`account_merge_ack`), kể cả khi thiết bị quay lại sau nhiều tháng.
