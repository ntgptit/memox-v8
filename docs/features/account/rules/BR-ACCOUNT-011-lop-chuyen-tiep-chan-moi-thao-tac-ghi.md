---
id: BR-ACCOUNT-011
title: Lớp chuyển tiếp chặn mọi thao tác ghi
status: active
summary: Khi chuyển tài khoản, đăng xuất, xoá hoặc dọn về ẩn danh đang chạy, cổng ghi đóng và một lớp phủ toàn app chặn giao diện.
superseded_by:
---
## Rule

Khi một chuyển tài khoản (Switch), đăng xuất (SignOut), xoá tài khoản (Delete) hoặc dọn về ẩn danh (ClearToAnon) đang chạy hay đang được phục hồi sau khi mở lại app, app MUST đóng cổng ghi: mọi ghi nghiệp vụ bị từ chối, đồng bộ tạm dừng, và outbox của tài khoản này không bao giờ được đẩy dưới tài khoản kia. Cổng MUST đóng trước khi một lần phục hồi chờ đồng bộ đang chạy. Cổng chỉ mở khi chuyển tiếp xong hoặc được huỷ đúng luật (BR-ACCOUNT-023).

Một lớp phủ ở gốc app (không phải route, có `Navigator` riêng) MUST che toàn app trong thời gian đó, MUST giấu app khỏi TalkBack, và MUST giữ nút Back trong lớp: ở gốc lớp Back làm việc của Cancel khi đang có Cancel, ngược lại Back bị nuốt, MUST NOT lọt ra app bên dưới. Dòng trạng thái của lớp MUST là live region. Phục hồi người dùng ẩn danh (AnonRecovery) MUST NOT đóng cổng và MUST NOT hiện lớp.

**Enforced by:** `lib/core/database/mutation_gate.dart` (cổng ghi, `AccountCoordinator` đóng/mở), `lib/core/auth/account_coordinator.dart`, `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart`, `lib/features/account/presentation/widgets/sections/account_transition_layer_widget.dart`
**Liên quan:** BR-ACCOUNT-012, BR-ACCOUNT-023
**Nguồn:** [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §3.1 (R3), §3.2; [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §1 (U4), §5.4

## Lý do

Chủ dự án chốt U4: lớp là overlay ở gốc app chứ không phải route, để không route nào bên dưới nhận được một thao tác ghi giữa lúc dữ liệu đang đổi chủ. Cổng ghi (R3) là thứ bảo đảm "không có dữ liệu chéo tài khoản".

## Ví dụ

Đang "Downloading your decks…" người dùng bấm Back: lớp không đóng và app bên dưới không nhận Back. Ở bước chọn tài khoản đích Back làm việc của Cancel.

## Edge case

- Phục hồi người dùng ẩn danh đã bị dọn trên server cho phép ghi: dữ liệu máy không thay đổi chủ trong bước đó.
- Một lớp đã dừng vì lỗi vẫn giữ cổng đóng cho tới khi Retry xong hoặc người dùng huỷ (BR-ACCOUNT-012).
