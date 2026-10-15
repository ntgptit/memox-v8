---
id: BR-TOPIK-015
title: Thời gian từng câu
status: active
summary: Luôn có đúng một câu hiện tại; thời gian chỉ cộng cho câu hiện tại khi màn làm bài ở foreground, cộng dồn khi quay lại; tổng thời gian bằng tổng thời gian các câu.
superseded_by:
---
## Rule

- Màn làm bài hiện một câu mỗi trang, nên tại mọi thời điểm có đúng một câu hiện tại.
- Thời gian MUST chỉ cộng cho câu hiện tại khi màn làm bài ở foreground; app ở nền thì dừng đếm (chủ dự án chốt 2026-10-15).
- Quay lại một câu thì thời gian cộng dồn.
- `total_time_ms` MUST bằng tổng `time_spent_ms` của các câu.
- Thời gian MUST được ghi ở mỗi lần đổi đáp án, chuyển câu, chuyển nền và rời màn; crash chỉ mất phần thời gian sau lần ghi cuối.
- Thời gian lưu theo mili giây và hiện đến giây (BR-TOPIK-025).

**Enforced by:** rule + store
**Liên quan:** BR-TOPIK-012, BR-TOPIK-025

## Lý do

Practice đo thời gian làm bài thật; một cuộc gọi hay chuyển app không được làm phồng thời gian.

## Ví dụ

Ở câu 5 trong 40 giây, sang câu 6 trong 20 giây, quay lại câu 5 thêm 10 giây: câu 5 là 50 giây, tổng 70 giây.

## Edge case

Chuyển nền 5 phút giữa câu 5: câu 5 không cộng 5 phút đó.
