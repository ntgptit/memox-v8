---
id: ADR-007
title: Khoá chính UUID sinh phía client
status: active
superseded_by:
---
## Quyết định

Toàn bộ khoá chính là TEXT chứa UUID sinh phía client (spec V8 §3). Tạo dữ liệu
offline cần ID trước khi có server, và đổi kiểu khoá chính về sau là migration
đắt nhất có thể.

ID sinh bằng `newId()` (`lib/core/id/new_id.dart`) là **UUID v7** (RFC 9562):
48 bit đầu là thời điểm sinh theo mili-giây, 12 bit `rand_a` là bộ đếm tăng
dần trong cùng mili-giây, phần còn lại ngẫu nhiên. Nhờ vậy các hàng ghi trong
một batch (import, sao chép starter) cùng `created_at` vẫn giữ đúng thứ tự
nguồn khi sắp theo `id` (DEV-216); mọi tie-break `id ASC`/`id DESC` hiện có
trở thành thứ tự ghi. ID v4 đã sinh trước đó vẫn hợp lệ: không có migration,
và không chỗ nào được suy ra thời điểm tạo từ id — `created_at` vẫn là cột
duy nhất mang nghĩa đó.
