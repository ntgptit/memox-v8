---
id: BR-MONITORING-008
title: Tab Not sent đọc bộ đệm trên máy và chạy được khi offline
status: active
summary: Tab "Not sent" đọc bộ đệm log của máy (`LogDatabase`), được theo dõi, chỉ lọc theo mức, không có trạng thái, và dùng được khi offline.
superseded_by:
---
## Rule

Tab "Not sent ({n})" MUST đọc bộ đệm log chưa gửi của máy (`LogDatabase`, cơ sở dữ liệu riêng) và MUST được theo dõi, nên cập nhật khi bộ đệm đổi. Nó MUST dùng được khi offline và MUST NOT cần server. n MUST là mọi dòng của bộ đệm, bất kể mức. Tab MUST chỉ lọc theo mức (mặc định warning và error); các dòng MUST NOT có trạng thái, và chi tiết của một dòng (`/settings/monitoring/:id?local=1`) MUST NOT có nút triage và MUST NOT có user.

Khi bộ đệm có dòng, tab MUST hiện ghi chú "These logs wait on this device. They are sent when MemoX is online." và tiêu đề "{n} at these levels" cho số dòng đang hiện. Bộ đệm rỗng MUST là "Nothing waiting" ("Every log on this device has been sent."); bộ đệm có dòng nhưng không ở mức đã chọn MUST là "No logs at these levels" ("Try another level."). Một dòng đã được gửi đi từ lúc danh sách vẽ MUST hiện "This log is gone" ở chi tiết.

**Enforced by:** `lib/features/monitoring/presentation/controllers/pending_logs_controller.dart`, `lib/features/monitoring/presentation/widgets/sections/monitoring_pending_tab_widget.dart`, `lib/features/monitoring/data/repositories/monitoring_repository_impl.dart` (`watchPending`, `getPending`), `lib/features/monitoring/domain/usecases/get_pending_log_use_case.dart`
**Liên quan:** BR-MONITORING-006, BR-MONITORING-010, BR-ACCOUNT-019
**Nguồn:** [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §1, §3.2, §3.3, §6; [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §3, §4, §8

## Lý do

ADR-018 §8: tab "Chưa gửi" đọc bộ đệm trên máy để xem được cả lúc offline. Tiêu chí thành công của spec: offline, tab Server nói vậy và "Not sent" vẫn hiện bộ đệm của máy.

## Ví dụ

Máy mất mạng cả ngày và đã ghi 14 log: tab ghi "Not sent (14)"; ở mức mặc định hiện, ví dụ, 3 dòng với "3 at these levels". Khi online, log được gửi đi và các dòng biến khỏi tab.

## Edge case

- Spec §3.2 viết ghi chú luôn hiện; code chỉ hiện ghi chú khi bộ đệm có dòng, vì bộ đệm rỗng đã nói trong trạng thái rỗng.
- Bộ đệm áp cùng mốc giữ log như server cho các dòng chưa gửi được (ADR-018 §5).
- Tab bị cổng admin che như mọi thứ trong Monitoring: người không phải admin không đọc được kể cả bộ đệm (BR-ACCOUNT-019).
