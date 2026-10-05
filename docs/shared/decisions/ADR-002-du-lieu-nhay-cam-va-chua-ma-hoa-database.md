---
id: ADR-002
title: Dữ liệu nhạy cảm và chưa mã hoá database
status: active
superseded_by:
---
## Quyết định

| Data | Why sensitive | Protection |
|---|---|---|
| Nội dung deck và flashcard người dùng tạo | Dữ liệu cá nhân ~~Chỉ trên thiết bị ở MVP~~: thay bằng [ADR-013](ADR-013-dong-bo-voi-server-offline-first.md) và [ADR-015](ADR-015-supabase-lam-backend.md), nội dung đồng bộ lên Supabase, mỗi user chỉ đọc được dữ liệu của mình. ~~Không log nội dung ở bất kỳ level nào~~: thay bằng [ADR-018](ADR-018-log-tap-trung-va-monitoring.md) (2026-09-29), nội dung được log vào bảng chỉ admin đọc |
| Ghi chú | Dữ liệu cá nhân | Như trên |
| Lịch sử học (`review_log`) | Suy ra được thói quen và thời gian sử dụng | ~~Không gửi ra ngoài ở MVP~~: thay bằng [ADR-017](ADR-017-lich-srs-dong-bo-nhu-mot-dong.md), `review_log` đồng bộ lên Supabase như dữ liệu của user. Không đưa vào analytics |
| File import | Có thể chứa nội dung ngoài phạm vi app | Xử lý trong bộ nhớ ứng dụng; không để lại bản sao ở thư mục dùng chung |
| Hình ảnh, audio | Media cá nhân | Lưu trong **thư mục riêng của ứng dụng**, không phải bộ nhớ dùng chung |
| Dữ liệu backup / export | Chứa toàn bộ những thứ trên | **Chỉ tạo khi người dùng chủ động yêu cầu** — không tự động, không chạy nền |
| Email, access token, refresh token | Định danh và quyền truy cập | Có từ khi đăng nhập ([ADR-015](ADR-015-supabase-lam-backend.md)). Bí mật của luồng tài khoản nằm trong `flutter_secure_storage` (`lib/core/auth/secure_secret_store.dart`), **không** lưu trong Drift, không xuất hiện trong log, xoá khi logout. Phần "không xuất hiện trong log" thay bằng [ADR-018](ADR-018-log-tap-trung-va-monitoring.md) (2026-09-29) |

**Chưa mã hoá database ở MVP** — dữ liệu học từ vựng không đủ nhạy cảm để trả giá
bằng độ phức tạp của SQLCipher. Nhưng việc mở kết nối database nằm sau một chỗ
duy nhất, để bổ sung mã hoá sau là sửa một hàm. Cần xem lại quyết định
này nếu app hỗ trợ ghi chú cá nhân tự do hoặc tài liệu công việc.

## Lý do và hệ quả

Ở MVP không có dữ liệu rời khỏi thiết bị, nên rủi ro chủ yếu là **log** — và đó
là chỗ dễ vi phạm nhất, vì log nội dung là phản xạ tự nhiên khi debug. Vì thế nó
là quy tắc (BR-CORE-002), không phải sự cẩn thận.

Cập nhật 2026-09-29: BR-CORE-002 hết hiệu lực. Log giờ chứa mọi thứ và nằm trong
bảng `app_log` chỉ admin đọc được ([ADR-018](ADR-018-log-tap-trung-va-monitoring.md)).
Phần lưu trữ của ADR này giữ nguyên.

Cập nhật 2026-10-05 (chủ dự án chốt): dữ liệu của user rời thiết bị một cách có chủ
đích. Nội dung, Trash, tag, lịch và `review_log` đồng bộ lên Supabase
([ADR-013](ADR-013-dong-bo-voi-server-offline-first.md),
[ADR-015](ADR-015-supabase-lam-backend.md), [ADR-017](ADR-017-lich-srs-dong-bo-nhu-mot-dong.md));
client chỉ gọi được RPC, và mỗi RPC chỉ chạm hàng của `auth.uid()` (bảng bật RLS, không có policy). Database trên máy vẫn
chưa mã hoá.

Các rule riêng tư: BR-CORE-001, BR-CORE-003, BR-CORE-004 (BR-CORE-002 hết hiệu lực, xem ADR-018).
