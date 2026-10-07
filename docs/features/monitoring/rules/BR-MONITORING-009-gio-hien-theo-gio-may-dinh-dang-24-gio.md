---
id: BR-MONITORING-009
title: Giờ hiện theo giờ máy, định dạng 24 giờ
status: active
summary: Log lưu giờ UTC và hiện theo giờ máy: `HH:mm` trong ngày, "Sep 26" ngày trước, và đủ ngày với `HH:mm:ss` ở chi tiết.
superseded_by:
---
## Rule

Thời điểm của log MUST được lưu theo UTC và hiện theo giờ địa phương của máy. Ở danh sách, một dòng MUST hiện `HH:mm` (24 giờ, mọi ngôn ngữ) nếu thuộc ngày địa phương hiện tại, ngược lại hiện ngày ngắn ("Sep 26"). Ở chi tiết, dòng đầu MUST hiện ngày đầy đủ và `HH:mm:ss` theo giờ địa phương. Khoảng thời gian của bộ lọc Time (1 giờ, 24 giờ, 7 ngày, 30 ngày) MUST là tương đối so với lúc hỏi, nên cùng bộ lọc hỏi lại một phút sau với tới xa hơn một phút. TalkBack MUST đọc dòng log là "{level}, {event}, {time}, {status}" (không có status với dòng không có trạng thái).

**Enforced by:** `lib/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart` (`monitoringRowTime`, `monitoringFullTime`), `lib/features/monitoring/domain/models/log_window_model.dart` (`since`), `lib/features/monitoring/presentation/widgets/items/log_row_widget.dart`
**Liên quan:** BR-MONITORING-001, BR-MONITORING-010
**Nguồn:** [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §3.2, §3.5; ADR-008 (giờ lưu UTC); detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md)

## Lý do

Spec §3.5: giờ lưu UTC (ADR-008), hiện theo giờ địa phương; 24 giờ `HH:mm` ở mọi nơi.

## Ví dụ

Một log ghi lúc 07:15 UTC hiện "14:15" ở máy UTC+7 trong ngày đó; ngày hôm sau nó hiện "Sep 26". Chi tiết hiện ngày đầy đủ cùng `14:15:08`.

## Edge case

- Dòng của bộ đệm trên máy dùng cùng widget và cùng định dạng giờ.
