---
id: BR-MONITORING-005
title: Trang 100 dòng theo con trỏ, tải khi gần cuối
status: active
summary: Tab Server tải 100 dòng một trang theo con trỏ (thời gian, id), trang kế tải khi mười dòng cuối vào tầm nhìn và kết thúc ở "No more logs".
superseded_by:
---
## Rule

Tab Server MUST tải tối đa 100 dòng một trang, theo con trỏ keyset gồm `occurred_at` và `id` của dòng cuối (mới nhất trước), không theo offset. Server MUST kẹp `limit` trong 1 đến 100. Một trang nhận đủ 100 dòng MUST được coi là còn trang sau; một trang ít hơn MUST là trang cuối. Trang kế MUST tự tải khi mười dòng cuối vào tầm nhìn; trong lúc đó MUST hiện spinner dưới dòng cuối, và một trang đang tải MUST NOT tải trang nữa.

Trang kế lỗi MUST hiện "Couldn't load more logs." với Retry và MUST NOT tự hỏi lại ở mỗi lần cuộn. Hết trang MUST hiện "No more logs". Các dòng đã tải MUST ở lại trong lúc trang kế đến hoặc lỗi.

**Enforced by:** `lib/features/monitoring/domain/models/log_page_model.dart` (`size`, `next`), `lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart` (`loadMore`), `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart`, server (`public.log_query`: `before`, `limit`)
**Liên quan:** BR-MONITORING-003, BR-MONITORING-010
**Nguồn:** [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §3.2, §7; [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §8; detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md)

## Lý do

Nhiều dòng debug sẽ đầy bảng (spec §7): bộ lọc mặc định giấu chúng, và trang keyset giữ mỗi lần gọi ở 100 dòng gọn.

## Ví dụ

Trang đầu có đúng 100 dòng nên còn trang sau; cuộn gần cuối thì trang hai tải về 37 dòng, nên đó là trang cuối và hiện "No more logs".

## Edge case

- Một trang có đúng 100 dòng cuối cùng cho một trang kế rỗng; khi đó "No more logs" hiện sau lần tải đó.
- Tiêu đề đếm dùng "{n}+ logs" trong lúc còn trang sau và "{n} logs" khi hết (BR-MONITORING-001).
