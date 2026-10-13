---
id: BR-ACCOUNT-006
title: Mã xác nhận sáu chữ số, kiểm ngay khi đủ sáu
status: active
summary: Mã gồm đúng sáu chữ số, kiểm ngay ở chữ số thứ sáu không cần nút; mã sai và mã hết hạn là một trạng thái và xoá ô mã.
superseded_by:
---
## Rule

Bước nhập mã MUST chỉ nhận chữ số, tối đa sáu: dán "123 456" MUST thành "123456". Mã MUST được kiểm ngay khi đủ sáu chữ số, không có nút xác nhận. Trong lúc kiểm, ô mã MUST chỉ-đọc (không bị vô hiệu), dòng trạng thái dưới ô hiện spinner, và một lần kiểm thứ hai MUST NOT bắt đầu.

Mã sai và mã hết hạn MUST là một trạng thái duy nhất ("That code is wrong or has expired. Check the latest email."), vì GoTrue trả cùng một mã lỗi (`otp_expired`) cho cả hai. Sau một mã sai ô mã MUST được xoá. Bị giới hạn tần suất MUST nói chờ một phút ("Too many tries. Wait a minute, then try again."), không mang thời gian chờ cụ thể.

**Enforced by:** `lib/features/account/presentation/widgets/sections/code_form_widget.dart`, `lib/features/account/presentation/controllers/code_controller.dart`, `lib/core/auth/supabase_auth_errors.dart` (`otp_expired` → `InvalidCodeFailure`, 429 → `RateLimitedFailure`), `MxTextField` biến thể `code`
**Liên quan:** BR-ACCOUNT-005, BR-ACCOUNT-007
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §2 (R3), §5.2; [sign-in redesign](../../../superpowers/specs/2026-10-05-sign-in-flow-redesign-design.md) §4; detail file [31](../../../shared/ui/screen-handoff/31-code.md)

## Lý do

Ruling R3 của brainstorm P3 (chủ dự án có thể lật lại): Supabase trả `otp_expired` cho cả mã sai lẫn hết hạn và P2 chỉ có một `InvalidCodeFailure`, nên giao diện không tách được hai trường hợp. Giới hạn tần suất không mang thời gian chờ; đếm ngược 60 giây của "Resend code" (BR-ACCOUNT-007) đã làm nhịp cho người dùng.

## Ví dụ

Nhập lần lượt `4`, `2`, `1`, `9`, `0`, `5`: ở chữ số thứ sáu app kiểm. Mã sai thì ô mã trống lại và dưới ô hiện lỗi; ô vẫn nhận mã mới.

## Edge case

- Mã đúng thì gắn tài khoản (hoặc đăng nhập tài khoản đích trong lớp chuyển tiếp, hoặc đăng nhập lại); luồng kết thúc theo BR-ACCOUNT-004.
- Một lần gửi mã đang chạy không chặn kiểm: coordinator chạy từng bước một nên lần kiểm chờ lần gửi xong.
