---
id: BR-PROGRESS-011
title: Đơn vị hoạt động card-day (overview)
status: active
summary: Đơn vị hoạt động của Progress là cặp distinct (localDay, cardId); cùng thẻ cùng ngày đếm một.
superseded_by:
---
## Rule

Đơn vị hoạt động của Progress là một cặp **distinct `(localDay, cardId)`**, gọi là một *card-day*. Nhiều answer, nhiều stage, nhiều round hay nhiều session của **cùng một card trong cùng một local day** MUST đếm đúng **một**. Progress MUST NOT đếm số hàng `review_log`, số session hay số lượt. Một card được trả lời trong hai local day khác nhau MUST đếm hai. `localDay` của **mọi** hàng — kể cả hàng ghi từ nhiều tháng trước — MUST được tính bằng UTC offset của **lần đọc hiện tại**, vì `review_log` không lưu offset theo hàng. Hệ quả đã biết và chấp nhận cho v1: đổi múi giờ hoặc qua một mốc DST làm các ngày quá khứ được phân bucket lại, nên một chuỗi có thể dài ra hoặc đứt hồi tố.

**Enforced by:** store (SQL)
**Liên quan:** BR-SRS-016, BR-STUDY-074

## Lý do

Cùng khái niệm card-day với BR-PROGRESS-002, rule tương ứng của Progress by Deck; hai rule áp cho hai màn và được giữ cả hai (chủ dự án chốt khi xử lý OQ-19 (2026-09-23)). Sửa một rule thì kiểm tra rule kia.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
