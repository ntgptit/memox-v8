---
id: BR-MONITORING-002
title: Chọn debug, info hoặc không mức nào thì bỏ lọc trạng thái
status: active
summary: Hàng debug và info không có trạng thái, nên chọn chúng (hoặc không chọn mức nào) xoá bộ lọc Status để không giấu chúng.
superseded_by:
---
## Rule

Chọn mức `debug` hoặc `info`, hoặc không chọn mức nào (mọi mức), trong bộ lọc Level MUST xoá bộ lọc Status: những hàng này không có trạng thái và một bộ lọc trạng thái sẽ giấu chúng. Admin MUST có thể đặt lại Status sau đó. Chọn chỉ `warning` và/hoặc `error` MUST giữ nguyên bộ lọc Status.

Một tập rỗng trong bất kỳ bộ lọc nào MUST không hạn chế gì (bộ lọc để mở thì không gửi lên server); "Reset" của mỗi sheet MUST đưa lựa chọn trong sheet về mặc định: Level về warning và error, Status về `open`, Category về mọi category, Time về mọi khoảng thời gian.

**Enforced by:** `lib/features/monitoring/domain/models/log_filter_model.dart` (`withLevels`), `lib/features/monitoring/data/mappers/log_mapper.dart` (`queryFilterOf` bỏ danh sách rỗng), `lib/features/monitoring/presentation/widgets/overlays/monitoring_filter_sheets_widget.dart`
**Liên quan:** BR-MONITORING-001, BR-MONITORING-006
**Nguồn:** detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md) ("Choosing Debug or Info…"); code như trên; [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §3.2

## Lý do

Chỉ warning và error có `open`/`fixed` (ADR-018 §6); giữ bộ lọc Status `open` cùng mức debug sẽ trả về rỗng và khó hiểu. Spec không nêu rõ luật này; nó được ghi ở detail file 28 và code.

## Ví dụ

Từ mặc định, admin thêm "Debug" vào Level: chip Status mất ("Status" không còn "Open"), danh sách hiện cả debug lẫn warning, error ở mọi trạng thái.

## Edge case

- Một `LogFilter` mới (mặc định) có Status `open`; chỉ `withLevels` tự xoá nó; không có đường nào tự đặt lại.
- Bộ lọc Category dựa vào `LogCategory.values`, nên category mới (như `network`) hiện không cần đổi code ở đây.
