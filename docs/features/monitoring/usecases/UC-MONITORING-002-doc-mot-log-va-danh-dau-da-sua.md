---
id: UC-MONITORING-002
title: Đọc một log và đánh dấu đã sửa
status: draft
rules: [BR-ACCOUNT-019, BR-MONITORING-006, BR-MONITORING-007, BR-MONITORING-008, BR-MONITORING-009, BR-MONITORING-010]
code: [lib/features/monitoring/domain/entities/log_record_entity.dart, lib/features/monitoring/domain/entities/log_summary_entity.dart, lib/features/monitoring/domain/models/log_status_model.dart, lib/features/monitoring/domain/failures/monitoring_failure.dart, lib/features/monitoring/domain/usecases/get_server_log_use_case.dart, lib/features/monitoring/domain/usecases/get_pending_log_use_case.dart, lib/features/monitoring/domain/usecases/set_log_status_use_case.dart, lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart, lib/features/monitoring/presentation/controllers/monitoring_detail_controller.dart, lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart, lib/features/monitoring/presentation/states/monitoring_detail_state.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_detail_body_widget.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_detail_header_widget.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_detail_summary_widget.dart, lib/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart, lib/features/monitoring/presentation/widgets/overlays/monitoring_status_sheet_widget.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Admin
**Trigger:** Chạm một dòng ở danh sách (UC-MONITORING-001), hoặc mở `/settings/monitoring/:id` (`?local=1` cho một dòng của bộ đệm máy)
**Preconditions:** Tài khoản đã được xác nhận là admin (BR-ACCOUNT-019). Dòng của server cần mạng; dòng của bộ đệm thì không
**Mục tiêu:** Admin đọc một log đầy đủ (thông điệp, lỗi, stack trace, context, chi tiết), sao chép nó, và với warning hay error của server thì đánh dấu đã sửa hoặc mở lại kèm ghi chú. Màn 28, phần chi tiết.

## Main flow

**Main flow:**
1. Trang chi tiết mở, tiêu đề là `event`; app gọi `log_get` lấy cả hàng (BR-MONITORING-010). Đầu trang: biểu tượng và tên mức, giờ đầy đủ (ngày và `HH:mm:ss`, giờ máy) và huy hiệu "Open" hoặc "Fixed" cho warning và error (BR-MONITORING-009).
2. Rồi những thứ phục vụ triage, mỗi thứ chỉ khi log có: "Message", "Error" (loại lỗi rồi message), "Stack trace" và "Context" (JSON canh lề). Cuối cùng "Details": Fixed by, Fixed at (chỉ log đang fixed), Note, Category, Source, Device, App, Platform, User; một giá trị thiếu thì bỏ hàng. Chữ chọn được; mỗi id có nút sao chép riêng.
3. Nút sao chép trên thanh trên đưa cả log, dạng JSON, vào clipboard và hiện "Copied".
4. Với warning hoặc error của server, footer có một nút: "Mark fixed" khi đang open, "Reopen" khi đang fixed (BR-MONITORING-006). Admin bấm; sheet "Mark fixed" (hoặc "Reopen") có ô "Note (optional)" và Cancel · "Save".
5. Admin bấm "Save". Nút quay; server lưu và trả cả hàng; trang hiện trạng thái mới, toast "Marked fixed" hoặc "Reopened", và dòng ở danh sách được cập nhật tại chỗ hoặc rời danh sách nếu bộ lọc Status không còn khớp (BR-MONITORING-007).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Log của bộ đệm máy** (`?local=1`): đọc từ cơ sở dữ liệu log của máy, không cần mạng, không có Fixed by, không có User, và không có footer triage (BR-MONITORING-008, BR-MONITORING-006).
- **A2 — Log debug hoặc info của server:** mở được, không có trạng thái và không có footer triage (BR-MONITORING-006).
- **A3 — Huỷ sheet:** Cancel đóng sheet và không đổi gì.
- **A4 — Ghi chú để trống:** coi như không có ghi chú; ghi chú được cắt khoảng trắng hai đầu (BR-MONITORING-006).
- **A5 — Đóng trang trước khi server trả lời:** câu trả lời vẫn tới danh sách (BR-MONITORING-007).

**Error flows:**
- **E1 — Đổi trạng thái thất bại:** mọi thứ giữ như trước; toast "Couldn't change that. Nothing changed." với Retry cho đúng thay đổi và ghi chú đó; toast rời đi cùng trang (BR-MONITORING-007).
- **E2 — Log không còn** (đã bị dọn theo thời gian giữ, hoặc đã gửi khỏi bộ đệm từ lúc danh sách vẽ): "This log is gone" ("It may have been cleaned up.") (BR-MONITORING-007, BR-MONITORING-008).
- **E3 — Offline:** "Can't reach the server" ("Nothing was lost. Try again when you're online.") với Retry (chỉ cho log của server).
- **E4 — Lỗi khác khi tải:** "Couldn't load this log" với Retry.
- **E5 — Không phải admin:** "Only an admin can see this" và không đọc gì, kể cả bộ đệm (BR-ACCOUNT-019).
- **E6 — Đang đổi trạng thái:** nút quay và không nhận lần nhấn thứ hai (BR-MONITORING-007).

## UI

**UI states:** loading (khung xương) · loaded: open error, fixed có ghi chú, một dòng của bộ đệm, một dòng debug · gone · offline · lỗi · không phải admin. Footer triage có "Mark fixed" hoặc "Reopen" hoặc không có. Stack trace một frame mỗi hàng với `#n` ở màu chính; context có thể tới 256 kB và chỉ được dựng một lần cho mỗi log.

## Local

**Postconditions:** Trên server: `status`, `status_changed_at`, `status_changed_by` và `status_note` của log được ghi (BR-MONITORING-006). Trên máy: không có gì được ghi; bộ lọc và danh sách ở bộ nhớ được cập nhật.

## API

- `log_get(log_id)` trả cả hàng (`to_jsonb`); `NOT_FOUND` khi log không còn.
- `log_set_status(log_id, new_status, note)` chỉ cho `warning` và `error`, trả cả hàng sau khi đổi; `NOT_FOUND` cho log khác hoặc đã mất, `VALIDATION_FAILED` cho trạng thái lạ.
- Cả hai chỉ cho admin; `FORBIDDEN` là "not an admin".

## Acceptance criteria

- [ ] **Given** một log error đang open của server, **when** admin mở nó, **then** trang hiện mức, giờ đầy đủ, "Open", message, error, stack trace, context và Details, và footer có "Mark fixed" (BR-MONITORING-010, BR-MONITORING-006).
- [ ] **Given** một log của bộ đệm máy, **when** admin mở nó, **then** trang không có footer triage và không có hàng User, và hoạt động khi offline (BR-MONITORING-008).
- [ ] **Given** admin bấm "Mark fixed" và nhập ghi chú, **when** server lưu, **then** trang hiện "Fixed" cùng Fixed by, Fixed at và ghi chú, toast "Marked fixed" hiện và nút thành "Reopen" (BR-MONITORING-006, BR-MONITORING-007).
- [ ] **Given** danh sách ở bộ lọc mặc định (chỉ open), **when** admin đánh dấu một log fixed rồi quay lại, **then** dòng đó rời danh sách (BR-MONITORING-007).
- [ ] **Given** danh sách có cả open lẫn fixed, **when** admin đánh dấu fixed, **then** dòng ở lại và huy hiệu đổi thành "Fixed" (BR-MONITORING-007).
- [ ] **Given** server từ chối thay đổi, **when** toast hiện, **then** log vẫn ở trạng thái cũ và Retry gửi lại đúng trạng thái và ghi chú đó (BR-MONITORING-007).
- [ ] **Given** log đã bị dọn, **when** admin bấm "Save", **then** trang chuyển sang "This log is gone" (BR-MONITORING-007).
- [ ] **Given** một thay đổi đang chạy, **when** admin bấm nút lần nữa, **then** không có lời gọi thứ hai (BR-MONITORING-007).
- [ ] **Given** admin bấm biểu tượng sao chép, **when** clipboard được ghi, **then** nó chứa cả log dạng JSON và "Copied" hiện (BR-MONITORING-010).
- [ ] **Given** một người không phải admin mở `/settings/monitoring/:id?local=1` bằng deep link, **when** trang mở, **then** "Only an admin can see this" hiện và bộ đệm không bị đọc (BR-ACCOUNT-019).
