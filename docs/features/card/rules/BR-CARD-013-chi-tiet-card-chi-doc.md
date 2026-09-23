---
id: BR-CARD-013
title: Chi tiết card là chỉ đọc
status: active
summary: Mở, cuộn chi tiết và tải lịch sử là chỉ đọc; xem một thẻ không phải là học nó.
superseded_by:
---
## Rule

Mở chi tiết card, cuộn nó và tải thêm trang lịch sử MUST là thao tác chỉ-đọc: MUST NOT ghi hay chạm tới nội dung card, `updated_at`, `content_type` của deck (BR-DECK-015), study state, review history, session, cờ hay quan hệ tag; MUST NOT đánh dấu thẻ đã học (`learned_at`) và MUST NOT tính là một lượt ôn. Xem một thẻ **không** phải là học nó.

**Enforced by:** store + UI
**Liên quan:** BR-DECK-015, BR-TRANSFER-011

## Lý do

Mặt đọc của thẻ. Các rule dưới đây **không** phát biểu lại nội dung
(BR-CARD-001, BR-CARD-002, BR-CARD-003), cờ và tag (BR-CARD-009, BR-TAG-001, BR-TAG-002), trạng thái hiển thị
(BR-CARD-006…BR-CARD-008) hay tính bất biến của `review_log` (BR-SRS-023, BR-SRS-015) — chúng chỉ
nói phần mà một màn **chỉ đọc** thêm vào.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
