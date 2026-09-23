---
id: BR-SRS-018
title: Bộ đếm
status: active
summary: Quy tắc cập nhật `answer_count`, `lapse_count`, `last_answered_at` theo loại lượt.
superseded_by:
---
## Rule

| Cột | Quy tắc |
|---|---|
| `answer_count` | +1 mỗi lượt `scheduled` (không tính `learning` hay `relearning`) |
| `lapse_count` | +1 khi lượt `scheduled` có action `forgotten` hoặc `again` |
| `last_answered_at` | = thời điểm đánh giá, cập nhật ở **cả ba** loại lượt |

**Enforced by:** store

## Lý do

**`answer_count` bằng 0 sau khi học xong lần đầu là đúng, không phải lỗi.** Chuỗi
học mới không sinh lượt `scheduled` nào (BR-STUDY-053), nên bộ đếm này chỉ bắt đầu chạy
từ phiên ôn tập đầu tiên. Nó đếm "đã được xếp lịch bao nhiêu lần", không đếm "đã
gặp bao nhiêu lần" — số thứ hai đọc từ `review_log`. Vì thế BR-CARD-007 xác định thẻ
mới bằng `learned_at`, không bằng bộ đếm này.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
