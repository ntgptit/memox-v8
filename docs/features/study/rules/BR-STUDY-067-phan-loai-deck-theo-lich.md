---
id: BR-STUDY-067
title: Phân loại deck theo lịch
status: active
summary: Danh sách deck phân loại `notDue`/`dueToday`/`overdue`, suy ra lúc đọc, badge số ngày quá hạn.
superseded_by:
---
## Rule

Danh sách deck MUST phân loại mỗi deck theo lịch, suy ra lúc đọc và MUST NOT lưu thành cột: `notDue` khi `dueCardCount = 0`; `dueToday` khi thẻ Due **cũ nhất** của subtree có `due_at` thuộc ngày học địa phương hiện tại; `overdue` khi ngày của nó đã qua. Badge MUST hiện số **ranh giới ngày địa phương đã hoàn tất** giữa `due_at` của thẻ Due cũ nhất và hôm nay (theo mốc BR-STUDY-074), MUST NOT là phép chia số giờ cho 24. Qua đầu ngày địa phương, trạng thái và badge MUST tự làm mới dù database không có write nào. Cả `dueToday` lẫn `overdue` vẫn thuộc đúng một tập Reviewing của BR-STUDY-051 — phân loại này là UI, MUST NOT tạo loại phiên thứ ba, MUST NOT đổi thứ tự thẻ hay hành vi scheduler, Trạng thái `overdue` MUST mang cặp `errorContainer`/`onErrorContainer` trên **chip đếm overdue của workload line** (quyết định chủ dự án 2026-08-20 — dời khỏi ô icon, đảo phần "ô icon" của quyết định 2026-08-11 vốn đã đảo phán quyết "không danger" cùng ngày): trễ hạn vẫn là tín hiệu đỏ, nhưng nó là **một con số**, không phải một ô vuông — ô icon đỏ cạnh chip đỏ nói cùng một điều hai lần, bằng một glyph đọc ra "đã huỷ" chứ không phải "trễ". Ô icon MUST là danh tính của deck (`folder`/`card`) trên cặp `primaryContainer`/`onPrimaryContainer` ở **mọi** trạng thái lịch. `dueToday` và `notDue` MUST NOT dùng màu đỏ. Level summary MUST tiếp tục phản ánh trạng thái của chính level đang xem — kể cả khi deck mang backlog không còn là một hàng trên màn hình: Due/New là tổng các child subtree (rời nhau), số ngày quá hạn là **max** trên các child có Due, và phân loại đi qua đúng một hàm chung với tile, MUST NOT chép lại điều kiện ở widget khác. Breakdown bốn tập của hero: BR-STUDY-068.

**Enforced by:** UI + store
**Liên quan:** BR-STUDY-074, BR-STUDY-051, BR-STUDY-046, BR-STUDY-008

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
