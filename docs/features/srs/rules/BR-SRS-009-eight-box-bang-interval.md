---
id: BR-SRS-009
title: eight_box: bảng interval
status: active
summary: `eight_box`: interval theo box là 1, 2, 4, 8, 16, 32, 64, 128 ngày; box 8 là box cuối.
superseded_by:
---
## Rule

| Box | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Ngày | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

`next_due_at` = đầu ngày học thứ `interval(box đích)` — 00:00 giờ địa phương,
lưu bằng UTC, không phải `now + N*24h` (lý do: BR-STUDY-074).

Box 8 là box cuối. Card ở box 8 trả lời `remembered` vẫn ở box 8 và xếp lịch lại
sau 128 ngày — không có trạng thái "tốt nghiệp" khiến card biến mất, vì trí nhớ
vẫn phai. "Đã thuộc" (`current_box == 8`) là giá trị suy ra để hiển thị, không
phải cột trong DB.

**Enforced by:** rule

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Card ở box 8 trả lời `remembered` trong lượt `scheduled` | Vẫn box 8, xếp lịch lại 128 ngày (BR-SRS-009). `kind` vẫn là `scheduled` dù box không đổi (BR-SRS-015) |
