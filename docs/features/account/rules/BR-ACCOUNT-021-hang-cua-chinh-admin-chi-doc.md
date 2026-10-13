---
id: BR-ACCOUNT-021
title: Hàng của chính admin chỉ đọc
status: active
summary: Trên màn Users, hàng của tài khoản đang đăng nhập có nhãn "You" và không mở sheet đổi role; người khác phải hạ quyền bạn.
superseded_by:
---
## Rule

Trên màn Users, hàng của tài khoản đang đăng nhập MUST có nhãn "You" ("Joined {date} · You") và MUST NOT mở sheet đổi role. Hàng đó MUST NOT bị làm mờ: nó là nội dung, không phải điều khiển bị vô hiệu, nên giữ nguyên độ tương phản và chỉ không nhận chạm. Một admin muốn bị hạ quyền MUST nhờ một admin khác.

**Enforced by:** `lib/features/account/presentation/widgets/items/user_row_widget.dart` (`isSelf`), `lib/features/account/presentation/screens/users_screen.dart` (`selfId` từ `currentAccountProvider`)
**Liên quan:** BR-ACCOUNT-020, BR-ACCOUNT-022
**Nguồn:** [users spec](../../../superpowers/specs/2026-09-30-users-admin-design.md) §1 (U1), §3, §6; detail file [33](../../../shared/ui/screen-handoff/33-users.md)

## Lý do

Chủ dự án chốt U1 (2026-09-30): không ai tự khoá mình khỏi màn mình đang đứng. Server không cấm tự hạ quyền khi còn admin khác; đây là ràng buộc của giao diện.

## Ví dụ

Admin An mở Users: hàng của An ghi "Joined Sep 30, 2026 · You", chạm không có gì; hàng của Bình mở sheet.

## Edge case

- Role của một tài khoản chỉ đổi qua sheet của người khác; một admin duy nhất không thể tự hạ mình và cũng không bị `LAST_ADMIN` của server chặn vì app không gửi lệnh đó.
