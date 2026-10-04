---
id: ADR-013
title: Server là dữ liệu chính thức, app offline-first và tự đồng bộ
status: accepted
superseded_by:
---
## Bối cảnh

[ADR-001](ADR-001-quyet-dinh-nen-tang.md) chốt V8 là local-only: không có
mạng, không có tài khoản, một profile cục bộ, và Drift là source of truth. Ngày
2026-09-27 chủ dự án đổi hướng sản phẩm. MemoX là app online có backend chính
thức, nhưng vẫn dùng được khi mất mạng và tự đồng bộ khi có mạng lại. Backend
`memox-api-services/` đang được dựng
([ADR-012](ADR-012-goi-api-bang-retrofit.md) chốt cách app gọi API). Nếu thiết
kế sync để sau khi V8 ổn định thì schema Drift phải migration lại nhiều lần.
Thiết kế chi tiết nằm ở
[`superpowers/specs/2026-09-27-server-sync-design.md`](../../superpowers/specs/2026-09-27-server-sync-design.md).

## Quyết định

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | Nguồn dữ liệu | PostgreSQL của `memox-api-services` là **nguồn chính thức** của dữ liệu người dùng, dùng chung cho mọi thiết bị. Drift trên mỗi máy là **kho vận hành bền vững**: app luôn đọc và ghi local, kể cả khi đang có mạng. Drift không phải cache có thể xoá |
| 2 | Ghi | Ghi local trước: dữ liệu và một dòng `sync_outbox` được ghi trong **cùng một transaction Drift**, UI phản hồi ngay, rồi `SyncCoordinator` (tầng `data/`) đẩy lên server khi có mạng. Use case và presentation không biết gì về mạng |
| 3 | Danh tính | Làm sớm, **login làm sau**. Server lấy owner qua `CurrentUserProvider`, hiện trả về một user dev cố định, sau này thay bằng JWT. Mọi bảng trên server có `user_id`; server không bao giờ tin owner do client gửi. Mỗi máy có một `device_id` 2026-09-30: login đã thiết kế ở `docs/superpowers/specs/2026-09-30-auth-design.md` (SB-A1); P1 server và P2 core auth xong. |
| 4 | Giao thức | Push theo lô, có idempotency key (id của dòng outbox). Pull theo cursor `server_version`, là một chuỗi số tăng dần theo từng user |
| 5 | Conflict: nội dung | deck, card, tags, card_tags và setting theo tài khoản: cả hàng bị ghi đè, thao tác mà server nhận **sau** thắng; không dựa vào đồng hồ của máy |
| 6 | Conflict: cây deck | Server kiểm các bất biến của cây khi áp dụng thao tác (không có chu trình, `root_id` và `content_type` nhất quán). Thao tác vi phạm bị từ chối, và client nhận lại trạng thái của server |
| 7 | Lịch sử học | `review_log` chỉ thêm vào, không bao giờ conflict |
| 8 | Lịch ôn | `card_schedule` là dữ liệu phái sinh. **Chỉ app tính**: sau mỗi lần pull, app chạy lại thuật toán trên các review đã gộp (tất định theo `reviewed_at` UTC và `id`) rồi push kết quả lên, để máy mới cài app không phải chạy lại toàn bộ lịch sử. Server không cài đặt `eight_box` hay `sm2` |
| 9 | Xoá | Server lưu tombstone (`deleted_at`). Purge local vẫn xoá hàng như cũ, nhưng kèm một thao tác `delete` trong outbox |
| 10 | Không sync | `study_session`, `study_queue_items`, `study_guess_options` và setting theo máy (nhắc nhở). Phiên đang học dở gắn với máy đang học; các review đã xong vẫn sync qua `review_log` |

> [ADR-014](ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md) từng sửa các dòng #1, #2,
> #4, #5 và #8; [ADR-015](ADR-015-supabase-lam-backend.md) (2026-09-28) bỏ ADR-014,
> nên các dòng đó có hiệu lực trở lại như văn bản gốc. Server là Supabase: đọc
> "PostgreSQL của `memox-api-services`" là Postgres của Supabase, và
> `CurrentUserProvider` là `auth.uid()`.

## Hệ quả

- ADR này thay các dòng *Data posture* ("local-only, không network") và
  *Authentication* ("chưa có auth, một local profile") của ADR-001, cùng
  câu "Drift là source of truth". Các dòng còn lại của ADR-001 giữ nguyên, kể
  cả việc chỉ có một loại user.
- `PRODUCT.md` mô tả MemoX là app dùng được đầy đủ khi không có mạng, và đồng
  bộ với backend khi có mạng.
- Schema Drift sẽ cần thêm `sync_outbox`, `sync_state` và cột `server_version`
  trên các bảng được sync, trong một migration làm ở lát cắt tích hợp đầu tiên.
- Lộ trình: (1) ADR và spec này; (2) server: bảng `deck`, API sync,
  `CurrentUserProvider`; (3) app: migration sync và coordinator cho `deck`;
  (4) mở rộng sang card, tag, `review_log` và việc chạy lại lịch ôn; (5) login.
- Phương án bị loại:
  - **server tự tính lịch ôn:** phải có hai bản cài đặt thuật toán SRS, một
    bằng Dart, một bằng Java, và chúng sẽ lệch nhau;
  - **gọi API trước rồi mới ghi local:** mất mạng thì mọi thao tác CRUD hỏng;
  - **đồng bộ cả phiên học đang dở:** phải xử lý hai máy cùng học một phiên.
