---
id: BR-PROGRESS-001
title: Bốn số của Progress by Deck
status: active
summary: Progress by Deck v1 chỉ báo cáo bốn số: unique active cards, active days, Learning và Reviewing card-days.
superseded_by:
---
## Rule

Progress by Deck v1 MUST chỉ báo cáo đúng bốn số cho mỗi phạm vi: **unique active cards**, **active days**, **Learning card-days** và **Reviewing card-days** (BR-PROGRESS-002, BR-PROGRESS-005). v1 MUST NOT báo cáo accuracy, điểm số, streak dài nhất, dự báo due, so sánh giữa hai khoảng, hay bất kỳ số dẫn xuất nào khác — mỗi số đó cần một định nghĩa riêng phải chốt trước, và một màn hình chứa năm số nửa-đồng-thuận thì không số nào đáng tin. Màn hình MUST là read-only (BR-PROGRESS-007).

**Enforced by:** rule
**Liên quan:** BR-PROGRESS-002, BR-PROGRESS-005, BR-PROGRESS-007

## Lý do

Drill-down hoạt động học theo cây deck (UC-PROGRESS-002). Các rule dưới đây **không** phát
biểu lại định nghĩa ngày địa phương (BR-STUDY-074), quan hệ cha–con và `root_id`
(BR-DECK-001…BR-DECK-003), tính append-only của `review_log` (BR-SRS-023) hay luật riêng tư
chung (BR-CORE-001…BR-CORE-004) — chúng chỉ nói phần mà chiều đọc tiến độ thêm vào.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
