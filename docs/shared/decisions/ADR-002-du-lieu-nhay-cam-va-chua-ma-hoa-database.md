---
id: ADR-002
title: Dữ liệu nhạy cảm và chưa mã hoá database
status: active
superseded_by:
---
## Quyết định

| Data | Why sensitive | Protection |
|---|---|---|
| Nội dung deck và flashcard người dùng tạo | Dữ liệu cá nhân | Chỉ trên thiết bị ở MVP. **Không log nội dung ở bất kỳ level nào** |
| Ghi chú | Dữ liệu cá nhân | Như trên |
| Lịch sử học (`review_log`) | Suy ra được thói quen và thời gian sử dụng | Không gửi ra ngoài ở MVP; không đưa vào analytics |
| File import | Có thể chứa nội dung ngoài phạm vi app | Xử lý trong bộ nhớ ứng dụng; không để lại bản sao ở thư mục dùng chung |
| Hình ảnh, audio | Media cá nhân | Lưu trong **thư mục riêng của ứng dụng**, không phải bộ nhớ dùng chung |
| Dữ liệu backup / export | Chứa toàn bộ những thứ trên | **Chỉ tạo khi người dùng chủ động yêu cầu** — không tự động, không chạy nền |
| Email, access token, refresh token | Định danh và quyền truy cập | Chưa tồn tại ở MVP. Khi có backend: `flutter_secure_storage`, **không** lưu trong Drift, không xuất hiện trong log, xoá khi logout |

**Chưa mã hoá database ở MVP** — dữ liệu học từ vựng không đủ nhạy cảm để trả giá
bằng độ phức tạp của SQLCipher. Nhưng việc mở kết nối database nằm sau một chỗ
duy nhất, để bổ sung mã hoá sau là sửa một hàm. Cần xem lại quyết định
này nếu app hỗ trợ ghi chú cá nhân tự do hoặc tài liệu công việc.

## Lý do và hệ quả

Ở MVP không có dữ liệu rời khỏi thiết bị, nên rủi ro chủ yếu là **log** — và đó
là chỗ dễ vi phạm nhất, vì log nội dung là phản xạ tự nhiên khi debug. Vì thế nó
là quy tắc (BR-CORE-002), không phải sự cẩn thận.

Các rule riêng tư: BR-CORE-001, BR-CORE-002, BR-CORE-003, BR-CORE-004.
