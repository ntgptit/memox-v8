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

> ⚠️ OPEN QUESTION: nguồn định nghĩa cùng khái niệm ở hai rule của hai section (Progress by Deck và Progress overview): card-day ở BR-PROGRESS-002 và BR-PROGRESS-011; phân hoạch Learning/Reviewing ở BR-PROGRESS-005 và BR-PROGRESS-014; chỉ-đọc ở BR-PROGRESS-007 và BR-PROGRESS-009. Chưa rõ rule nào là nguồn duy nhất. Nguồn: `business-rules/progress.md`. (Plan OQ-19)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
