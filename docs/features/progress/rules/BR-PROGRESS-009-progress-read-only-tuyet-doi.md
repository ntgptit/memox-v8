---
id: BR-PROGRESS-009
title: Progress read-only tuyệt đối
status: active
summary: Progress không ghi hay sửa hàng nào và không mở, tiếp tục hay đóng session.
superseded_by:
---
## Rule

Progress MUST là read-only tuyệt đối: mở màn, đóng màn, Retry, đổi tab hay quay lại MUST NOT ghi hay sửa bất kỳ hàng nào — không `study_session`, không `card_schedule`, không `review_log`, không `app_settings` — và MUST NOT mở, tiếp tục hay đóng session nào.

**Enforced by:** store + UI
**Liên quan:** BR-TRANSFER-011

> ⚠️ OPEN QUESTION: nguồn định nghĩa cùng khái niệm ở hai rule của hai section (Progress by Deck và Progress overview): card-day ở BR-PROGRESS-002 và BR-PROGRESS-011; phân hoạch Learning/Reviewing ở BR-PROGRESS-005 và BR-PROGRESS-014; chỉ-đọc ở BR-PROGRESS-007 và BR-PROGRESS-009. Chưa rõ rule nào là nguồn duy nhất. Nguồn: `business-rules/progress.md`. (Plan OQ-19)

## Lý do

Progress đọc `review_log` (BR-SRS-016) và **không** ghi gì. Các rule dưới đây chỉ
nói phần mà việc *đọc lại lịch sử* thêm vào; chúng không phát biểu lại luật ghi
lượt (BR-SRS-015, BR-SRS-016, BR-MODE-005), luật reset (BR-SRS-021…BR-SRS-027) hay luật ngày học
(BR-STUDY-074).

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
