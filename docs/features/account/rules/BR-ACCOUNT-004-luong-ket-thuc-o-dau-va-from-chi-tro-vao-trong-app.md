---
id: BR-ACCOUNT-004
title: Luồng kết thúc ở đâu và from chỉ trỏ vào trong app
status: active
summary: Luồng gắn kết thúc ở màn 32, đăng nhập lại quay về nơi nó được mở; tham số `from` chỉ nhận vị trí trong app.
superseded_by:
---
## Rule

Luồng gắn tài khoản (`mode=link`) MUST kết thúc ở `/settings/account` (màn 32) khi đăng nhập thành công. Đăng nhập lại (`mode=reauth`) MUST quay về nơi nó được mở qua tham số `from` (Settings 23, Account 32 hoặc Study home 13); không có `from` hợp lệ thì về `/settings`. Lối ra Google và "Continue without an account" của Welcome MUST đi tiếp tới `from` của Welcome, mặc định `/decks`; lối ra email mở màn 30 (`link`) với Settings bên dưới.

Tham số `from` MUST chỉ nhận vị trí trong app: bắt đầu bằng `/`, không bắt đầu bằng `//` hay `/\`, không có scheme hay authority. Giá trị khác MUST bị bỏ và dùng mặc định của luồng. `from` chỉ là đường quay lại, không bao giờ là đường ra khỏi app.

**Enforced by:** `lib/app/router/app_routes.dart` (`inAppOr`), `lib/app/router/account_routes.dart` (`_SignInFlow`, `welcomeRoute`)
**Liên quan:** BR-ACCOUNT-001, BR-ACCOUNT-003
**Nguồn:** [account UI spec](../../../superpowers/specs/2026-09-30-account-ui-design.md) §2 (R5), §9 (B9); detail file [30](../../../shared/ui/screen-handoff/30-sign-in.md)

## Lý do

Đăng nhập lại là việc dang dở của một màn khác nên phải trả người dùng về đó. Một `from` lấy từ link không được dẫn người dùng ra ngoài app.

## Ví dụ

Banner đăng nhập lại ở Study home mở `/settings/sign-in?mode=reauth&from=/study`; đăng nhập xong, app về `/study`. `from=https://example.com` hoặc `from=//example.com` bị bỏ.

## Edge case

- Đăng xuất, xoá tài khoản và "Continue without this account" không dùng điểm kết thúc riêng: thiết bị thành ẩn danh và luật 2 của BR-ACCOUNT-003 đưa màn 32 về Settings. Riêng "Continue without this account" mở từ đăng nhập lại đi tới `from` của luồng đó (detail file 30 viết "lands on 23", code đi tới `from`, tức Study home nếu mở từ đó).
