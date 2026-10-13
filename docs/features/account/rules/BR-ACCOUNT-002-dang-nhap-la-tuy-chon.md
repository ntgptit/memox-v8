---
id: BR-ACCOUNT-002
title: Đăng nhập là tuỳ chọn
status: active
summary: App dùng đầy đủ trên phiên ẩn danh; không màn hình nào bị chặn hay chuyển hướng để buộc đăng nhập ngoài Welcome lần đầu.
superseded_by:
---
## Rule

Đăng nhập MUST là tuỳ chọn: app MUST dùng đầy đủ trên phiên ẩn danh, và MUST NOT có route nào bị chặn hay chuyển hướng cưỡng bức để buộc đăng nhập. Luật chuyển hướng tài khoản của router chỉ gồm Welcome lần đầu (BR-ACCOUNT-001) và hai luật theo trạng thái thiết bị (BR-ACCOUNT-003). Phiên đăng nhập hết hiệu lực (`ReauthRequired`) MUST chỉ hiện banner hoặc notice (BR-ACCOUNT-017), không chuyển hướng. Mất mạng MUST NOT đăng xuất hay xoá dữ liệu (BR-ACCOUNT-013).

**Enforced by:** `lib/app/router/account_redirect.dart`, `lib/core/auth/account_coordinator.dart` (offline là điều kiện, không phải trạng thái)
**Liên quan:** BR-ACCOUNT-001, BR-ACCOUNT-003, BR-ACCOUNT-013, BR-ACCOUNT-017
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §1 (O2), §3.1, §7; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §4

## Lý do

Chủ dự án chốt O2 (2026-09-29/30): đăng nhập tuỳ chọn, lần mở đầu chỉ mời. App là offline-first (ADR-013), nên không được có điều kiện nào buộc người dùng có tài khoản mới học được.

## Ví dụ

Người dùng bấm "Continue without an account" ở Welcome rồi không bao giờ đăng nhập: mọi tính năng chạy như trước, trên người dùng ẩn danh mà app tạo khi có mạng.

## Edge case

- Gắn tài khoản chỉ dùng được khi thiết bị có người dùng ẩn danh đã được xác nhận (`Ready`, ẩn danh). Chưa có thì nút Sign in, Google và email bị vô hiệu kèm "Signing in needs a connection. Try later in Settings.", và Welcome chỉ còn "Continue without an account" làm nút chính (`canLinkProvider`).
- Bản build không có project Supabase không có `AccountCoordinator`: mục Account của Settings và Welcome không hiện.
