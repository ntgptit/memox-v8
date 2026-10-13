---
id: UC-MONITORING-001
title: Duyệt và lọc log của server và của máy
status: draft
rules: [BR-ACCOUNT-019, BR-MONITORING-001, BR-MONITORING-002, BR-MONITORING-003, BR-MONITORING-004, BR-MONITORING-005, BR-MONITORING-008, BR-MONITORING-009, BR-MONITORING-010]
code: [lib/features/monitoring/domain/models/log_filter_model.dart, lib/features/monitoring/domain/models/log_page_model.dart, lib/features/monitoring/domain/models/log_window_model.dart, lib/features/monitoring/domain/usecases/query_server_logs_use_case.dart, lib/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart, lib/features/monitoring/data/datasources/monitoring_remote_data_source.dart, lib/features/monitoring/data/mappers/log_mapper.dart, lib/features/monitoring/data/mappers/monitoring_error_mapper.dart, lib/features/monitoring/data/repositories/monitoring_repository_impl.dart, lib/features/monitoring/presentation/screens/monitoring_screen.dart, lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart, lib/features/monitoring/presentation/controllers/pending_logs_controller.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_server_tab_widget.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_filter_bar_widget.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_pending_tab_widget.dart, lib/features/monitoring/presentation/widgets/overlays/monitoring_filter_sheets_widget.dart, lib/features/monitoring/presentation/widgets/overlays/monitoring_device_user_sheet_widget.dart, lib/features/monitoring/presentation/widgets/items/log_row_widget.dart, lib/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Admin
**Trigger:** Chạm "Monitoring" ("Logs of the app and the server") trong mục ADMIN của Settings (màn 23), hoặc mở `/settings/monitoring`
**Preconditions:** Tài khoản đã được xác nhận là admin (BR-ACCOUNT-019). Tab Server cần mạng; tab "Not sent" không cần
**Mục tiêu:** Admin thấy các vấn đề đang mở của app và của server, lọc và tìm trong log, và xem log chưa được gửi của chính thiết bị. Màn 28, phần danh sách.

## Main flow

**Main flow:**
1. Monitoring mở trên tab "Server" với hai tab "Server" và "Not sent ({n})" (n là mọi dòng của bộ đệm máy), ô "Search event or message" và năm chip lọc: Level, Status, Category, Time, Device / user. Bộ lọc mặc định là warning và error ở trạng thái open, mới nhất trước (BR-MONITORING-001).
2. Trang đầu tải (khung xương sáu hàng). Mỗi hàng có biểu tượng mức, `event`, dòng phụ (dòng đầu của message, nếu không thì của error message, nếu không thì loại lỗi), giờ, và huy hiệu "Open" hoặc "Fixed" cho warning và error (BR-MONITORING-010, BR-MONITORING-009). Tiêu đề đếm là "{n} logs", hoặc "{n}+ logs" khi còn trang sau.
3. Admin cuộn. Khi mười dòng cuối vào tầm nhìn, 100 dòng kế tải; hết thì "No more logs" (BR-MONITORING-005).
4. Admin đổi bộ lọc: chip mở một sheet (Level, Status, Category: một công tắc cho mỗi giá trị; Time: một trong "Last hour", "Last 24 hours", "Last 7 days", "Last 30 days", "All time"; Device / user: hai ô, id thiết bị và id người dùng) với "Reset" và "Apply". Chip có lựa chọn hiện nó ("Level · Warning, Error"). Mỗi thay đổi tải lại từ trang đầu (BR-MONITORING-003).
5. Admin gõ vào ô tìm kiếm: 400 ms sau lần gõ cuối app hỏi, khớp `event` và `message` nguyên văn (BR-MONITORING-004).
6. Admin chạm một dòng và đi tới chi tiết (UC-MONITORING-002); Back về lại danh sách với các trang đã tải và vị trí cuộn (BR-MONITORING-003).
7. Tab "Not sent" hiện bộ đệm của máy: ghi chú "These logs wait on this device. They are sent when MemoX is online.", một chip Level (mặc định warning và error), tiêu đề "{n} at these levels" và các dòng (BR-MONITORING-008).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Chọn debug, info hoặc không mức nào:** bộ lọc Status bị xoá để không giấu dòng không có trạng thái (BR-MONITORING-002).
- **A2 — Rỗng ở mặc định:** "No open problems" ("Warnings and errors will show here.").
- **A3 — Rỗng ở bộ lọc khác:** "Nothing matches" với "Clear filters", đưa bộ lọc và ô tìm kiếm về mặc định.
- **A4 — Kéo xuống để làm mới:** tải lại từ trang đầu với cùng bộ lọc; một tìm kiếm đang chờ được hỏi ngay (BR-MONITORING-003).
- **A5 — Bộ đệm rỗng:** "Nothing waiting" ("Every log on this device has been sent."); bộ đệm có dòng nhưng không ở mức đã chọn: "No logs at these levels" ("Try another level.").
- **A6 — Một trang kế lỗi:** banner danger "Couldn't load more logs." với Retry; các dòng đã tải ở lại (BR-MONITORING-005).

**Error flows:**
- **E1 — Không phải admin:** deep link tới `/settings/monitoring` bởi tài khoản khác hiện "Only an admin can see this" và không đọc gì, kể cả bộ đệm; khi server từ chối giữa chừng, ô tìm kiếm và chip biến mất cùng danh sách (BR-ACCOUNT-019, BR-MONITORING-003).
- **E2 — Offline:** "Can't reach the server" ("Monitoring reads the logs online. The ones this device hasn't sent are under Not sent.") với Retry và một nút "Not sent"; ô tìm kiếm và chip vẫn còn (BR-MONITORING-003).
- **E3 — Lỗi khác:** "Couldn't load logs" ("Nothing was lost. Try again in a moment.") với Retry.
- **E4 — Lỗi đọc bộ đệm:** "Couldn't load logs" với Retry ở tab "Not sent".
- **E5 — Đang xác nhận tài khoản:** cổng chờ với khung xương thay vì từ chối (BR-ACCOUNT-019).

## UI

**UI states:** Tab Server: loading (khung xương) · loaded · rỗng ở mặc định · rỗng ở bộ lọc khác · offline · lỗi · không phải admin · đang tải trang kế / lỗi trang kế / hết trang. Tab "Not sent": loading · loaded · bộ đệm rỗng · không có dòng ở mức đã chọn · lỗi. Sheet lọc: Level, Status, Category (công tắc) · Time (một lựa chọn) · Device / user (hai ô; một id người dùng phải là uuid, nếu không "That isn't a valid user ID."). Một dòng ở trạng thái mà chip Status đang giữ thì không hiện huy hiệu. TalkBack đọc dòng log là "{level}, {event}, {time}, {status}". Cuộn ngang cho hàng chip; chữ lớn làm hàng cao hơn, không cắt.

## Local

**Postconditions:** Không ghi gì. Tab "Not sent" đọc cơ sở dữ liệu log riêng (`memox_logs`) và được theo dõi, nên tự cập nhật khi bộ đệm đổi. Bộ lọc của tab Server nằm trong bộ nhớ và không được lưu.

## API

- `log_query(filter)` trả `{items}`: các hàng gọn, chỉ admin; bộ lọc `levels`, `statuses`, `categories`, `search`, `from`, `deviceIds`, `userId`, `before` (con trỏ `occurredAt` và `id`), `limit` (kẹp 1 đến 100). Một danh sách rỗng bị bỏ khỏi bộ lọc (BR-MONITORING-002).
- `FORBIDDEN`, hoặc thiếu phiên, là "not an admin"; một lời gọi không tới được server là offline.

## Acceptance criteria

- [ ] **Given** một admin, **when** mở Monitoring, **then** tab Server hỏi `log_query` với mức warning và error, trạng thái open, và hiện các dòng mới nhất trước (BR-MONITORING-001).
- [ ] **Given** bộ lọc mặc định và không có log nào, **when** trang đầu về rỗng, **then** "No open problems" hiện; với bộ lọc khác thì "Nothing matches" và "Clear filters" đưa mọi thứ về mặc định (BR-MONITORING-001).
- [ ] **Given** bộ lọc mặc định, **when** admin thêm "Debug" vào Level, **then** bộ lọc Status bị xoá và danh sách hiện cả dòng debug (BR-MONITORING-002).
- [ ] **Given** một lần hỏi đang chạy, **when** admin đổi bộ lọc, **then** câu trả lời của lần hỏi cũ bị bỏ và danh sách là của bộ lọc mới (BR-MONITORING-003).
- [ ] **Given** admin gõ `100%` vào ô tìm kiếm, **when** 400 ms trôi qua, **then** app hỏi một lần và server khớp chữ `100%` nguyên văn, không phân biệt hoa thường (BR-MONITORING-004).
- [ ] **Given** trang đầu có đủ 100 dòng, **when** mười dòng cuối vào tầm nhìn, **then** trang kế tải với con trỏ của dòng cuối; một trang ít hơn 100 là trang cuối và hiện "No more logs" (BR-MONITORING-005).
- [ ] **Given** một trang kế lỗi, **when** admin cuộn tiếp, **then** app không tự hỏi lại; Retry hỏi lại (BR-MONITORING-005).
- [ ] **Given** thiết bị offline và bộ đệm có 14 dòng, **when** admin mở tab "Not sent", **then** các dòng hiện từ bộ đệm không cần mạng và tab ghi "Not sent (14)" (BR-MONITORING-008).
- [ ] **Given** một log ghi lúc 07:15 UTC trong ngày hôm nay ở máy UTC+7, **when** nó hiện ở danh sách, **then** giờ là `14:15`; ngày hôm sau là ngày ngắn (BR-MONITORING-009).
- [ ] **Given** một danh sách, **when** nó tải, **then** các hàng không mang `context` hay `stack_trace` và message dài bị cắt ở 300 ký tự (BR-MONITORING-010).
- [ ] **Given** một người không phải admin, **when** mở `/settings/monitoring` bằng deep link, **then** "Only an admin can see this" hiện và không có lời gọi server hay đọc bộ đệm nào (BR-ACCOUNT-019).
