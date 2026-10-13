---
id: BR-MONITORING-006
title: Chỉ warning và error của server có trạng thái open hoặc fixed
status: active
summary: Admin đánh dấu fixed hoặc mở lại một log warning hoặc error của server, kèm ghi chú tuỳ chọn; debug, info và log chưa gửi không có trạng thái.
superseded_by:
---
## Rule

Chỉ log mức `warning` và `error` trên server MUST có trạng thái `open` hoặc `fixed`; log mới MUST bắt đầu `open`. Log `debug`, `info` và mọi dòng của bộ đệm chưa gửi MUST NOT có trạng thái và MUST NOT có nút triage. Với một log có trạng thái, trang chi tiết MUST có đúng một nút ở footer: "Mark fixed" khi đang `open`, "Reopen" khi đang `fixed`. Nút mở một sheet ("Mark fixed" hoặc "Reopen") với một ghi chú tuỳ chọn ("Note (optional)") và Cancel · "Save".

Ghi chú MUST được cắt khoảng trắng hai đầu, và một ghi chú rỗng MUST là không có ghi chú. Server MUST ghi thời điểm, người đổi và ghi chú của lần đổi gần nhất; chi tiết MUST hiện "Fixed by", "Fixed at" (chỉ log đang fixed) và ghi chú. Server MUST từ chối đổi trạng thái cho log không phải warning hay error (`NOT_FOUND`) và cho giá trị khác `open`, `fixed` (`VALIDATION_FAILED`).

**Enforced by:** server (`public.log_set_status`, `supabase/migrations/20261003000000_app_log.sql`; `private.log_server` và `log_push` đặt `open`); app: `lib/features/monitoring/domain/entities/log_record_entity.dart` (`canTriage`), `lib/features/monitoring/domain/usecases/set_log_status_use_case.dart` (cắt ghi chú), `lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart`, `lib/features/monitoring/presentation/widgets/overlays/monitoring_status_sheet_widget.dart`
**Liên quan:** BR-MONITORING-002, BR-MONITORING-007, BR-ACCOUNT-019
**Nguồn:** [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §6, §7; [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §1, §3.3; detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md)

## Lý do

ADR-018 §6: `warning` và `error` có trạng thái `open`/`fixed` kèm thời điểm, người đổi và ghi chú; admin đổi qua RPC. Tiêu chí thành công của spec: admin mở một vấn đề, đọc nó, đánh dấu đã sửa với ghi chú tuỳ chọn, và nó rời danh sách mặc định.

## Ví dụ

Admin mở một log `error` đang `open`, bấm "Mark fixed", gõ "Đã sửa ở bản 8.0.1", bấm "Save": log thành `fixed`, kèm "Fixed by", "Fixed at" và ghi chú, nút đổi thành "Reopen".

## Edge case

- Một log debug mở từ danh sách (bộ lọc đã mở rộng) không có footer triage; một log của bộ đệm (`?local=1`) cũng vậy.
- Nhãn của nút xác nhận trong sheet là "Save" ở code; monitoring spec §3.3 viết "Confirm" (DEV-179 đổi nhãn).
