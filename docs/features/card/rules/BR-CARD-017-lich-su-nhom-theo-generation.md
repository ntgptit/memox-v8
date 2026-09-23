---
id: BR-CARD-017
title: Lịch sử nhóm theo generation
status: active
summary: Lịch sử nhóm theo `generation` đã lưu, còn xem được sau reset; không tính giá trị tổng hợp.
superseded_by:
---
## Rule

Hàng lịch sử MUST được nhóm theo `generation` đã lưu trên chính hàng đó, và nhóm MUST đọc được mà không cần màu — mỗi nhóm có tiêu đề dạng chữ. Reset (BR-SRS-021…BR-SRS-023) MUST NOT xoá hàng nào, nên generation cũ MUST vẫn xem được sau reset, kể cả khi scheduler của root đã đổi. Màn này MUST NOT tính accuracy, điểm số, streak hay bất kỳ giá trị tổng hợp nào từ lịch sử: đây là bản ghi thô, và một con số tổng hợp ở đây sẽ là định nghĩa thứ hai cạnh phần thống kê thật.

**Enforced by:** rule + UI
**Liên quan:** BR-SRS-021, BR-SRS-022, BR-SRS-023

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Reset tiến độ rồi mở lại chi tiết | Hàng của generation cũ vẫn xem được, có tiêu đề nhóm riêng (BR-CARD-017) |
