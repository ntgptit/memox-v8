---
id: BR-MONITORING-007
title: Đổi trạng thái một lần một thay đổi và cập nhật tại chỗ
status: active
summary: Đổi trạng thái chạy một lần một thay đổi, cập nhật dòng ở chi tiết và danh sách, bỏ dòng khỏi danh sách nếu bộ lọc không còn khớp, và lỗi không đổi gì.
superseded_by:
---
## Rule

Trang chi tiết MUST chạy tối đa một lần đổi trạng thái tại một thời điểm; nút MUST quay trong lúc chạy và MUST NOT nhận lần nhấn thứ hai. Thành công MUST hiện dòng theo câu trả lời của server ở chi tiết, hiện "Marked fixed" hoặc "Reopened", và cập nhật dòng ở danh sách tại chỗ: nếu bộ lọc Status không còn khớp trạng thái mới (mặc định chỉ `open`), dòng MUST rời danh sách; ngược lại dòng MUST hiện trạng thái mới. Câu trả lời MUST đến được danh sách kể cả khi trang chi tiết đã đóng trước khi server trả lời.

Thất bại MUST giữ nguyên mọi thứ như trước và hiện "Couldn't change that. Nothing changed." với Retry cho cùng thay đổi (cùng ghi chú); toast đó MUST rời đi cùng trang. Nếu server báo log không còn (`NOT_FOUND`), trang chi tiết MUST chuyển sang "This log is gone" ("It may have been cleaned up.").

**Enforced by:** `lib/features/monitoring/presentation/controllers/monitoring_detail_controller.dart` (`setStatus`, `changing`), `lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart` (`statusChanged`), `lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart`
**Liên quan:** BR-MONITORING-006, BR-MONITORING-001
**Nguồn:** [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §1, §3.3 ("Changing the status"), §3.4; detail file [28](../../../shared/ui/screen-handoff/28-monitoring.md)

## Lý do

Tiêu chí thành công của spec: sau khi đánh dấu fixed, log "rời danh sách mặc định". Nguồn không ghi lý do riêng cho việc chỉ một thay đổi một lúc.

## Ví dụ

Từ danh sách mặc định (chỉ `open`), admin mở một log, "Mark fixed", rồi Back: dòng đó không còn trong danh sách, và tiêu đề đếm giảm một.

## Edge case

- Log bị bộ chạy retention dọn (debug và info sau 7 ngày, warning và error sau 180 ngày tính từ lúc server nhận, ADR-018 §5) giữa lúc mở và lúc đổi: "This log is gone".
- Trạng thái đổi mà bộ lọc Status có cả hai giá trị: dòng ở lại và đổi huy hiệu.
