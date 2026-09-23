---
id: BR-PROGRESS-017
title: Reset và xoá đối với Progress
status: active
summary: Reset không đổi số nào của Progress; card đã xoá cứng không còn xuất hiện.
superseded_by:
---
## Rule

Reset learning progress giữ `review_history`/`review_log` (BR-SRS-023), nên nó MUST NOT làm thay đổi bất kỳ con số nào của Progress. Ngược lại, card đã bị xoá cứng — trực tiếp, hay theo cascade từ deck bị xoá — MUST NOT còn xuất hiện trong Progress, kể cả trong các ngày quá khứ, vì hàng `review_log` của nó bị cascade xoá theo. v1 MUST NOT tạo tombstone, bảng bóng hay bản sao analytics để giữ lại hoạt động của card đã xoá.

**Enforced by:** db (schema cascade)
**Liên quan:** BR-SRS-021, BR-SRS-023

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
