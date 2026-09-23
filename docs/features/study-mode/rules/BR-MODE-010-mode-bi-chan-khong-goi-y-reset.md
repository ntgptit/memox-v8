---
id: BR-MODE-010
title: Mode bị chặn không gợi ý Reset
status: active
summary: Mode bị chặn vì thuật toán được trình bày là không khả dụng, không gợi ý Reset để mở khoá.
superseded_by:
---
## Rule

Mode bị chặn vì thuật toán MUST được trình bày là không khả dụng cho deck này, và MUST NOT gợi ý Reset learning progress như cách mở khoá.

**Enforced by:** UI
**Liên quan:** BR-SRS-003, BR-SRS-021

## Lý do

BR-MODE-010 tồn tại vì lối thoát duy nhất là có thật nhưng không được phép đề nghị:
thuật toán khoá khi thẻ đầu tiên học xong chuỗi học mới (BR-SRS-003) và chỉ Reset mới mở, mà
Reset xoá toàn bộ tiến độ học. Một dòng copy gợi ý điều đó đang đề nghị người
dùng đánh đổi thứ họ không định đánh đổi.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
