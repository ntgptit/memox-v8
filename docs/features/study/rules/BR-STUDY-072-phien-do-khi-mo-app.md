---
id: BR-STUDY-072
title: Phiên dở khi mở app
status: active
summary: Còn phiên dở cùng ngày học: ba đường tiếp tục, Học mới, Ôn tập; phiên của ngày khác bị đóng `interrupted`.
superseded_by:
---
## Rule

Khi mở app còn session `in_progress` của **cùng ngày học**, màn chọn MUST có ba đường: tiếp tục phiên đó, Học mới, hoặc Ôn tập. Chọn một trong hai đường sau MUST chuyển phiên dở sang `abandoned`/`user_exit`. Session `in_progress` của ngày học khác MUST chuyển `abandoned` với `end_reason = interrupted`.

**Enforced by:** store
**Liên quan:** BR-STUDY-012, BR-STUDY-074, BR-STUDY-051

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| App bị thu hồi giữa phiên `mixed`, mở lại | Resume đọc chiều đã lưu, không hỏi lại và không gieo lại (BR-STUDY-072, BR-MODE-017) |
