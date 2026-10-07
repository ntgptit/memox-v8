---
id: BR-MONITORING-001
title: Mặc định mở vào các vấn đề đang mở
status: active
summary: Tab Server mở với bộ lọc mặc định là warning và error ở trạng thái open, mới nhất trước; rỗng ở mặc định là "No open problems".
superseded_by:
---
## Rule

Tab Server MUST mở với bộ lọc mặc định: mức `warning` và `error`, trạng thái `open`, mọi category, mọi khoảng thời gian, mọi thiết bị và người dùng, không tìm kiếm. Các hàng MUST sắp mới nhất trước (`occurred_at` giảm dần, rồi `id`). Tiêu đề đếm MUST là "{n} logs" với mọi bộ lọc, hoặc "{n}+ logs" khi còn trang sau; số là số đã tải, chip bộ lọc nói bộ lọc là gì.

Danh sách rỗng ở bộ lọc mặc định MUST là "No open problems" ("Warnings and errors will show here.") tông success. Danh sách rỗng ở bộ lọc khác MUST là "Nothing matches" với "Clear filters", đưa mọi bộ lọc và ô tìm kiếm về mặc định. Chip có lựa chọn MUST hiện nó ("Level · Warning, Error", "Status · Open", "Time · Last 24 hours"), gọi tên một hoặc hai lựa chọn và đếm từ ba ("Level · 3"); chip Device / user đếm một cặp vì các lựa chọn của nó là id.

**Enforced by:** `lib/features/monitoring/domain/models/log_filter_model.dart` (`LogFilter`, `isDefault`), `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart`, `lib/features/monitoring/presentation/widgets/sections/monitoring_filter_bar_widget.dart`, server (`public.log_query` sắp theo `occurred_at desc, id desc`)
**Liên quan:** BR-MONITORING-002, BR-MONITORING-003, BR-ACCOUNT-019
**Nguồn:** [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §1, §3.2, §3.4; [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §8; detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md)

## Lý do

Chủ dự án chốt (Impeccable `shape`, 2026-09-29): việc chính của admin là phân loại vấn đề đang mở, nên màn mở thẳng vào warning và error đang open, mới nhất trước.

## Ví dụ

Admin mở Monitoring: thấy 12 dòng error và warning đang mở, mới nhất ở trên, tiêu đề "12 logs", chip "Level · Warning, Error" và "Status · Open". Khi đã sửa hết: "No open problems".

## Edge case

- Monitoring spec §3.2 viết tiêu đề đếm "{n} open" ở bộ lọc mặc định; code và detail file 28 dùng "{n} logs" cho mọi bộ lọc (critique 2026-09-30 part 3d-2). Theo code.
- Một hàng có đúng trạng thái mà chip Status đang giữ không hiện huy hiệu trạng thái (chip và tiêu đề đã nói); TalkBack vẫn đọc trạng thái.
