---
id: BR-MONITORING-004
title: Tìm kiếm khớp event và message nguyên văn, hỏi sau 400 ms
status: active
summary: Ô tìm kiếm khớp `event` và `message` không phân biệt hoa thường, coi `%`, `_` và `\` là chữ, và chỉ hỏi server 400 ms sau lần gõ cuối.
superseded_by:
---
## Rule

Tìm kiếm ở tab Server MUST khớp một phần trong `event` hoặc `message` của log, không phân biệt hoa thường. Server MUST coi `%`, `_` và `\` trong truy vấn là ký tự thường, không phải ký tự đại diện. App MUST cắt khoảng trắng hai đầu truy vấn; một truy vấn rỗng sau khi cắt MUST không hạn chế gì. App MUST chỉ hỏi server 400 ms sau lần gõ cuối. Mọi lần tìm là một lần hỏi từ trang đầu (BR-MONITORING-003).

**Enforced by:** server (`public.log_query`, `supabase/migrations/20261007000000_log_admin_reads.sql`: `ilike` với thoát `%`, `_`, `\`); app: `lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart` (`monitoringSearchDebounce`), `lib/features/monitoring/domain/models/log_filter_model.dart` (`withSearch`)
**Liên quan:** BR-MONITORING-003
**Nguồn:** [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §3.2, §2; [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §8; migration như trên

## Lý do

Spec §2 yêu cầu "literal search". Log chứa câu SQL và tham số (ADR-018 §1), nơi `%` và `_` xuất hiện thường xuyên, nên truy vấn của admin phải khớp đúng chữ đã gõ.

## Ví dụ

Gõ `100%` tìm các log có chữ `100%`, không phải mọi log bắt đầu bằng `100`. Gõ `SYNC` tìm cả `sync.push_failed`.

## Edge case

- Chỉ `event` và `message` được tìm: không tìm trong `context`, `error_message` hay `stack_trace`.
- Server so sánh `message` đầy đủ, dù danh sách chỉ hiện 300 ký tự đầu (BR-MONITORING-010).
