---
id: BR-MONITORING-010
title: Danh sách chỉ tải hàng gọn, chi tiết tải cả hàng
status: active
summary: Danh sách không tải `context` và `stack_trace` và cắt message ở 300 ký tự; mở một dòng mới gọi `log_get` lấy cả hàng.
superseded_by:
---
## Rule

Danh sách MUST chỉ tải hàng gọn: không có `context` và `stack_trace`, và `message` cùng `error_message` bị cắt ở 300 ký tự đầu; dòng bộ đệm trên máy MUST cũng gọn như vậy. Mở một dòng MUST gọi `log_get` để lấy cả hàng; dòng của bộ đệm đọc cả hàng từ `LogDatabase`. Dòng phụ của một hàng MUST là dòng đầu của message, nếu không thì dòng đầu của error message, nếu không thì loại lỗi; không có cái nào thì không có dòng phụ.

Trang chi tiết MUST hiện: mức và trạng thái; rồi, chỉ khi log có, "Message", "Error" (loại lỗi trên một dòng rồi message), "Stack trace" (một frame mỗi hàng, `#n` ở màu chính) và "Context" (JSON canh lề, tối đa 256 kB); rồi "Details" (Fixed by, Fixed at, Note, Category, Source, Device, App, Platform, User; một hàng log không có thì bỏ). Chữ MUST chọn được và id MUST có nút sao chép riêng. Nút sao chép trên thanh trên MUST đưa cả log, dạng JSON, vào clipboard và hiện "Copied".

**Enforced by:** server (`public.log_query` cắt `left(…, 300)` và bỏ `context`, `public.log_get`, `supabase/migrations/20261007000000_log_admin_reads.sql`); app: `lib/features/monitoring/domain/entities/log_summary_entity.dart` (`subtitle`), `lib/features/monitoring/presentation/widgets/sections/monitoring_detail_body_widget.dart`, `lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart` (`_copy`)
**Liên quan:** BR-MONITORING-005, BR-MONITORING-008, BR-MONITORING-009
**Nguồn:** [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §8; [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §3.2, §3.3, §7; detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md)

## Lý do

ADR-018 §8: tab chính đọc danh sách bằng hàng gọn (không `context` và `stack_trace`), mở một dòng mới gọi `log_get`. Spec §7: `context` lên tới 256 kB nên danh sách không bao giờ tải nó.

## Ví dụ

Danh sách một trang 100 dòng gọn; chạm một dòng error, trang chi tiết hiện thông điệp, loại lỗi, stack trace và context, rồi Details. Chạm biểu tượng sao chép: toàn bộ log dạng JSON vào clipboard.

## Edge case

- Một log đã bị dọn giữa lúc xem danh sách và lúc mở: "This log is gone" ("It may have been cleaned up.").
- Chi tiết đọc lỗi: trạng thái lỗi với Retry; offline: trạng thái offline với Retry.
