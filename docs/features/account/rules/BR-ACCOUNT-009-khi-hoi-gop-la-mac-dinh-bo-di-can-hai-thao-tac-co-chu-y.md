---
id: BR-ACCOUNT-009
title: Khi hỏi, gộp là mặc định; bỏ dữ liệu cần hai thao tác có chủ ý
status: active
summary: Sheet gộp chọn sẵn "Merge into the account"; chọn "Discard this phone's data" hiện cảnh báo và đổi nút xác nhận sang destructive.
superseded_by:
---
## Rule

Khi hỏi (BR-ACCOUNT-008), sheet "{email} already has an account" (Google: "This Google account is already in use") MUST có đúng hai lựa chọn: "Merge into the account", chọn sẵn, và "Discard this phone's data". Nhãn gộp MUST nêu số deck và số thẻ sống ("Your {n} decks and {m} cards join it."); khi không đếm được MUST là "This phone's decks and cards join it.".

Chọn "Discard this phone's data" MUST hiện cảnh báo tông danger ("This phone's decks and progress go for good.") và MUST đổi nút xác nhận sang "Discard data" tông destructive, nên bỏ dữ liệu đòi hai thao tác có chủ ý (chọn, rồi xác nhận). Huỷ hoặc đóng sheet MUST NOT bắt đầu chuyển. Xác nhận MUST gọi `beginSwitch(choice, targetHint: email)`; chỉ người dùng ẩn danh mới được chọn gộp.

**Enforced by:** `lib/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart` (`MergeChoiceSheetWidget`), `lib/core/auth/account_coordinator_switch.dart` (`beginSwitch` từ chối merge khi nguồn không ẩn danh)
**Liên quan:** BR-ACCOUNT-008, BR-ACCOUNT-016
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §5.3; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §1 (O4); detail file [30](../../../shared/ui/screen-handoff/30-sign-in.md)

## Lý do

Chủ dự án chốt O4: "hỏi, mặc định gộp". Gộp không mất gì nên là mặc định; bỏ dữ liệu là hành động không hoàn tác nên cần một bước xác nhận sau khi chọn.

## Ví dụ

Người dùng mở sheet, chạm "Discard this phone's data": banner danger hiện, nút đổi thành "Discard data" màu destructive. Chạm lại "Merge into the account" thì banner mất và nút thành "Continue".

## Edge case

- Nhãn xác nhận đủ ngắn để cặp Cancel và xác nhận nằm một dòng, chia 1:1 như mọi hộp thoại và sheet (`MxSheetActions`, DEV-169, DEV-179).
- Sau khi chọn gộp, dữ liệu máy chỉ bị xoá khi merge đã commit trên server (BR-ACCOUNT-013).
