---
id: BR-ACCOUNT-008
title: Chỉ hỏi gộp hay bỏ khi máy có deck sống; Trash không tính là dữ liệu cần giữ
status: active
summary: Khi đăng nhập trùng một tài khoản đã có, app chỉ hỏi gộp hay bỏ khi máy có deck ngoài Trash; không có thì tự chọn bỏ, không hỏi.
superseded_by:
---
## Rule

Khi một đăng nhập từ người dùng ẩn danh (email hoặc Google) trùng một tài khoản đã có (`IdentityTaken`), app MUST chỉ hỏi "gộp hay bỏ dữ liệu điện thoại này" khi máy có ít nhất một deck **sống**: deck không nằm trong Trash (`delete_batch_id IS NULL`). Khi máy không có deck sống, app MUST chọn `discard` và bắt đầu chuyển ngay (`beginSwitch(discard, targetHint: email)`), không hiện sheet và không xác nhận gì thêm.

Dữ liệu chỉ nằm trong Trash MUST NOT được tính là dữ liệu cần giữ ở bước quyết định này. Số deck và số thẻ dùng cho quyết định và cho nhãn của lựa chọn gộp MUST là số **sống**: deck có `delete_batch_id IS NULL` và thẻ sống thuộc deck sống. Quyết định chỉ dựa trên số deck sống (`decks == 0`); số thẻ chỉ để hiển thị.

Khi không đếm được thư viện (lỗi đọc), app MUST vẫn hỏi, không kèm số liệu.

**Enforced by:** `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart` (`startLinkSwitch`), `lib/features/account/domain/models/local_library_model.dart` (`isEmpty`), `lib/core/database/queries/account_device_queries.drift` (`liveLibraryCounts`)
**Liên quan:** BR-ACCOUNT-009, BR-ACCOUNT-013, BR-ACCOUNT-016, BR-TRASH-001
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §2 (R6: "Empty (no live deck) → no sheet, straight to `beginSwitch(discard)`"), §5.2 và §9; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.3 #17 ("empty → skip"); code như trên

## Lý do

Ruling R6 của brainstorm P3 (2026-09-30, chủ dự án có thể lật lại): số đếm lấy từ đọc riêng của feature account, và máy rỗng thì không có gì để gộp hay để mất, nên không cần hỏi. Spec không bàn Trash; việc đếm chỉ deck sống là cách đọc của `liveLibraryCounts`.

## Ví dụ

Máy mới cài, chưa tạo deck nào, đăng nhập bằng email đã có tài khoản: app chuyển thẳng sang tài khoản đó và kéo dữ liệu của nó về, không hỏi gì. Máy có ba deck sống: hiện sheet với "Your 3 decks and 42 cards join it."

## Edge case

- Chuyển (discard) chạy `LocalDataReset`, xoá cả `delete_batches` (Trash) và `tags` cùng `card`, `deck` và outbox. Vì Trash không được đếm, một máy chỉ còn dữ liệu trong Trash (hoặc chỉ còn tag) mất chúng mà không được hỏi. Đây là hiện trạng được ghi lại theo yêu cầu của đợt rà soát nghiệp vụ, không phải một quyết định đã được rà lại; chủ dự án có thể muốn xem lại.
- Luật này chỉ áp cho đường `IdentityTaken` của người dùng ẩn danh. "Switch account" từ màn 32 không đếm thư viện và luôn hỏi bằng hộp thoại riêng (BR-ACCOUNT-016).
