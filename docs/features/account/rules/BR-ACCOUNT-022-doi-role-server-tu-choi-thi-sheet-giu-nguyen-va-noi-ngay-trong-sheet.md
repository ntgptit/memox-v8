---
id: BR-ACCOUNT-022
title: Đổi role bị từ chối thì sheet ở lại và nói ngay trong sheet
status: active
summary: Sheet role lưu qua `role_set`; server từ chối admin cuối, tài khoản ẩn danh, hoặc không phải admin, và mỗi từ chối có cách nói riêng.
superseded_by:
---
## Rule

Sheet role (title là email) MUST có hai lựa chọn "User" và "Admin", lựa chọn hiện tại được chọn sẵn; "Save" MUST chỉ bật khi lựa chọn khác role hiện tại, và quay trong lúc chạy. Trong lúc lưu sheet MUST bị giữ (Back, chạm nền và kéo chờ) để câu trả lời luôn có sheet để nói.

Server MUST từ chối: người gọi không phải admin (`FORBIDDEN`), role không hợp lệ (`INVALID_ROLE`), tài khoản không còn (`NOT_FOUND`), nâng một tài khoản ẩn danh lên admin (`ANONYMOUS_USER`), và hạ admin cuối cùng (`LAST_ADMIN`; server kiểm trong khoá advisory để hai lần hạ đồng thời không xoá hết admin). Kết quả MUST được nói như sau:

| Kết quả | Hiển thị |
|---|---|
| lưu được | sheet đóng, badge đổi tại chỗ, toast "{email} is now an admin" hoặc "… a user" |
| admin cuối cùng | sheet ở lại, banner warning trong sheet: "An admin must remain. Make someone else an admin first." |
| tài khoản ẩn danh | sheet ở lại, banner "This account isn't signed in with an email or Google." |
| tài khoản không còn | sheet đóng, toast "That account no longer exists.", danh sách tải lại |
| không phải admin | sheet đóng, màn chuyển sang "not an admin" |
| offline hoặc lỗi khác | sheet ở lại, banner "No connection. Nothing changed." hoặc "Couldn't change the role. Nothing changed."; chọn lại sẽ xoá banner |

Một lần lưu thành công MUST thắng một lần tải trang đầu đang chạy (trang đó được hỏi lại), và một "not an admin" MUST thắng mọi trang đang chạy.

**Enforced by:** server (`public.role_set`, `supabase/migrations/20261010000000_accounts.sql`); app: `lib/features/account/presentation/widgets/overlays/user_role_sheet_widget.dart`, `lib/features/account/presentation/controllers/users_controller.dart` (`setRole`), `lib/features/account/data/mappers/user_role_mapper.dart`
**Liên quan:** BR-ACCOUNT-019, BR-ACCOUNT-020, BR-ACCOUNT-021
**Nguồn:** [users spec](../../../superpowers/specs/2026-09-30-users-admin-design.md) §2, §3; [auth spec](../../../superpowers/specs/2026-09-30-auth-design.md) §2.3; detail file [33](../../../shared/ui/screen-handoff/33-users.md)

## Lý do

Một toast sẽ nằm sau sheet nên mọi lý do giữ sheet mở được nói trong sheet (final review I2 của P4). "Not an admin" nghĩa là quyền đã mất giữa chừng: không còn gì để giữ.

## Ví dụ

Admin duy nhất mở sheet của một admin khác (đã bị hạ chỉ còn một admin còn lại), chọn "User" và Save: server trả `LAST_ADMIN`, banner hiện trong sheet và role không đổi.

## Edge case

- Users spec §3 viết ba kết quả (ẩn danh, offline, lỗi khác) là toast; code và detail file 33 nói trong sheet bằng banner. Ở đây theo code.
- Chỉ ẩn danh bị cấm nâng lên admin; hạ một tài khoản user thành user là không đổi gì và "Save" vốn đã bị tắt.
