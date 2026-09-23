---
id: BR-STUDY-034
title: Lưu lý do hết giờ
status: active
summary: Lý do hết giờ lưu tường minh ở `review_log.outcome_reason`, không suy từ `action`.
superseded_by:
---
## Rule

Lý do "hết giờ" MUST được lưu tường minh trên `review_log.outcome_reason`. MUST NOT suy luận từ `action`, vì tự nhận quên và hết giờ cho cùng một `action`.

**Enforced by:** db
**Liên quan:** BR-SRS-015, BR-STUDY-033

## Lý do

**BR-STUDY-034 là BR-SRS-015 lặp lại ở một chỗ khác.** Người học tự nhận quên và người học
hết giờ đều cho `action = forgotten`. Không có cột riêng thì hai điều đó không phân
biệt được từ dữ liệu đã lưu — và chúng nói hai chuyện rất khác nhau về chất
lượng thẻ. `review_log` là bảng chỉ thêm, nên một cột thiếu hôm nay không tính
ngược được ngày mai.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
