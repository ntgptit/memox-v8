---
id: ADR-018
title: Log tập trung và monitoring cho admin
status: accepted
superseded_by:
---
## Bối cảnh

Ngày 2026-09-29, sau đợt rà hạ tầng (commit `227698d0`), chủ dự án quyết định dựng
đường ống log ngay bây giờ. Mục tiêu là sau này có màn hình monitoring cho admin: mọi
log của app, cả UI lẫn backend, được ghi vào database trên server, và chỉ admin xem
được. Trong giai đoạn phát triển, người dùng app duy nhất là admin.

Trước ADR này, V8 có:

- log rải rác bằng `dart:developer`;
- [BR-CORE-002](../rules/BR-CORE-002-khong-log-noi-dung.md) cấm log nội dung thẻ;
- [ADR-002](ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md) coi nội dung thẻ là
  dữ liệu cá nhân và cấm log token;
- [ADR-016](ADR-016-mo-hinh-xu-ly-loi.md) quyết định 6 chỉ cho log `runtimeType` và
  `resultCode`.

## Quyết định

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Log được chứa gì | Mọi thứ, kể cả nội dung thẻ, câu lệnh SQL, tham số và token. Chủ dự án quyết định 2026-09-29: app học từ vựng không có dữ liệu nhạy cảm, và nội dung thẻ lẫn lịch sử học vốn đã đồng bộ lên Supabase (SB-S2, SB-S4). Hệ quả chủ dự án đã chấp nhận: ai đọc được bảng log trên server thì đọc được phiên đăng nhập của người dùng |
| 2 | Nơi log sống lâu dài | Bảng `public.app_log` trên Supabase, là nguồn sự thật. Log của client và log của server dùng chung schema, phân biệt bằng cột `source` |
| 3 | Đường đi của log trên client | `AppLogger` → các sink. Sink console (`dart:developer`) cho dev. Sink bộ đệm ghi vào một database Drift **riêng** (`memox_logs`); `LogShipper` đẩy bộ đệm lên bằng RPC `log_push` theo lô và xoá bản ghi đã đẩy. Tách database để ghi log không sinh log (không vòng lặp với tracing Drift), không tranh khoá với giao dịch học, không dính trigger sync. Sink console chỉ bật ở bản debug; bản build không có project Supabase không có bộ đệm; chỉ đẩy log khi app ở foreground; `warning`/`error` kèm lỗi lặp lại trong 5 giây được đếm thay vì ghi (spec §3) |
| 4 | Offline | Log chờ trong bộ đệm cho tới khi có mạng; `id` là UUID sinh ở client, nên đẩy lại không tạo bản ghi trùng |
| 5 | Thời gian giữ | `pg_cron` chạy mỗi ngày: `debug` và `info` quá 7 ngày thì xoá; `warning` và `error` quá 180 ngày (khoảng 6 tháng) thì xoá. Tuổi tính từ lúc server nhận (`received_at`), không theo đồng hồ của máy. Bộ đệm trên máy áp cùng mốc cho bản ghi chưa đẩy được |
| 6 | Theo dõi xử lý | `warning` và `error` có trạng thái `open`/`fixed`, kèm thời điểm, người đổi và ghi chú. Admin đổi trạng thái qua RPC |
| 7 | Admin | Vai trò `admin` trong `public.profiles.role` (từ migration `20261010000000`, [auth spec 2026-09-30](../../superpowers/specs/2026-09-30-auth-design.md); `app_metadata` không còn được server đọc). Chủ dự án đặt admin đầu tiên bằng SQL, các admin sau được cấp trong app (`role_set`). RPC đọc log (`log_query` cho danh sách gọn, `log_get` cho một bản ghi đầy đủ) và RPC đổi trạng thái (`log_set_status`) kiểm tra vai trò này; bảng không có policy và client không có quyền trên bảng, đúng mẫu của [ADR-015](ADR-015-supabase-lam-backend.md) |
| 8 | Xem log | Mục Monitoring trong Settings, chỉ hiện với admin. Tab chính đọc danh sách từ Supabase bằng `log_query` (hàng gọn, không có `context` và `stack_trace`), mở một dòng thì gọi `log_get`; tab "Chưa gửi" đọc bộ đệm trên máy, để xem được cả lúc offline |
| 9 | Log của server | Hàm `private.log_server(...)` ghi thẳng vào `app_log` với `source = 'server'`. RPC gọi nó ở những chỗ từ chối hoặc lỗi |

## Hệ quả

- [BR-CORE-002](../rules/BR-CORE-002-khong-log-noi-dung.md) chuyển sang `deprecated`
  (`superseded_by: ADR-018`), và ra khỏi `rules` của UC-PROGRESS-001, UC-REMINDER-001,
  UC-TRANSFER-002. Vế "MUST NOT log" của BR-TRASH-012 và BR-TRANSFER-006 bỏ theo; rule
  guard `memox.privacy.no_card_content_in_logs` tắt.
- [ADR-002](ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md): các ô "không log nội
  dung" và "không xuất hiện trong log" (token) hết hiệu lực với log. Phần lưu trữ của
  ADR-002 (không mã hoá DB, token trong `flutter_secure_storage`, media trong thư mục
  riêng, export chỉ khi người dùng yêu cầu) giữ nguyên.
- [ADR-016](ADR-016-mo-hinh-xu-ly-loi.md) quyết định 6 được thay: `ProviderObserver` log
  đầy đủ lỗi, kể cả `cause`. Quyết định 3 (không hiện `cause` cho người dùng,
  [BR-CORE-005](../rules/BR-CORE-005-thong-bao-loi-khong-lo-chi-tiet-ky-thuat.md)) giữ
  nguyên: đó là chuyện hiển thị, không phải chuyện log.
- Không ảnh hưởng: [BR-REMINDER-005](../../features/reminders/rules/BR-REMINDER-005-noi-dung-notification-rieng-tu.md)
  (nội dung trên màn khoá), [BR-STUDY-030](../../features/study/rules/BR-STUDY-030-khong-luu-noi-dung-go-o-fill.md)
  (luật lưu trữ, không phải luật log).
- Log mạng: mọi request của Supabase client (trừ `log_push`) được ghi với category `network` (spec [`2026-09-29-network-logging-design.md`](../../superpowers/specs/2026-09-29-network-logging-design.md)).
- Khi app có người dùng thật ngoài admin, phải xem lại quyết định 1.

Chi tiết thiết kế: spec
[`2026-09-29-app-logging-design.md`](../../superpowers/specs/2026-09-29-app-logging-design.md).
