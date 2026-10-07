---
id: BR-ACCOUNT-016
title: Đổi tài khoản từ màn 32 luôn là bỏ dữ liệu máy và luôn hỏi
status: active
summary: "Switch account" từ một tài khoản vĩnh viễn luôn là `discard` sau một hộp thoại xác nhận, không đếm thư viện và không có người dùng ẩn danh ở giữa.
superseded_by:
---
## Rule

"Switch account" ở màn 32 MUST luôn là `beginSwitch(discard)`: chỉ người dùng ẩn danh mới được gộp, nên một tài khoản vĩnh viễn không có lựa chọn merge. App MUST hiện hộp thoại "Switch account?" ("This phone's data is replaced by the other account's after your changes are sent.", ghi chú "Your changes are sent first.", xác nhận "Switch") cho **mọi** lần đổi, bất kể máy có dữ liệu hay không; việc này MUST NOT đọc hay đếm thư viện (khác BR-ACCOUNT-008).

Thay đổi chưa gửi MUST được gửi dưới tài khoản nguồn trước (và log của nó), rồi tài khoản đích đăng nhập ngay trong lớp chuyển tiếp (BR-ACCOUNT-011), rồi dữ liệu máy bị xoá và dữ liệu của tài khoản đích được kéo về. Giữa chừng MUST NOT có người dùng ẩn danh nào.

**Enforced by:** `lib/features/account/presentation/screens/account_screen.dart` (`_switch`), `lib/features/account/presentation/controllers/account_manage_controller.dart` (`switchAccount`), `lib/core/auth/account_coordinator_switch.dart` (`beginSwitch`, từ chối merge khi nguồn không ẩn danh)
**Liên quan:** BR-ACCOUNT-008, BR-ACCOUNT-009, BR-ACCOUNT-011, BR-ACCOUNT-013, BR-ACCOUNT-023
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §2 (R1), §5.6, §9 (B10); [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.3 #34–#35; detail file [32](../../../shared/ui/screen-handoff/32-account.md)

## Lý do

Ruling R1 của brainstorm P3 (chủ dự án có thể lật lại): không có `mode=switch` của màn 30; "Switch account" xác nhận rồi `beginSwitch(discard)` và đăng nhập đích diễn ra trong lớp chuyển tiếp, như một merge buộc phải làm. Thay đổi đã được gửi nên bỏ dữ liệu máy không làm mất gì của tài khoản nguồn.

## Ví dụ

Đang đăng nhập `an@example.com`, người dùng chạm "Switch account", xác nhận, nhập `binh@example.com` và mã: máy chỉ còn dữ liệu của `binh@example.com`, và dữ liệu của `an@example.com` vẫn trên server.

## Edge case

- Offline với thay đổi chưa gửi: bước gửi dừng ở lớp với Retry, chờ mạng; không có đường "mất rồi đi tiếp" cho một đổi tài khoản không phải merge (BR-ACCOUNT-010).
- Hàng bị server từ chối không chặn một chuyển `discard`: chúng đi cùng dữ liệu máy khi xoá.
- Switch từ đăng nhập lại (đăng nhập sang tài khoản khác khi phiên cũ bị từ chối) là chuyển `discard` đã qua đăng nhập đích (BR-ACCOUNT-017).
