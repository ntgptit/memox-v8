---
id: BR-STUDY-072
title: Phiên dở khi mở app
status: active
summary: Còn phiên dở cùng ngày học: ba đường tiếp tục, Học mới, Ôn tập; phiên của ngày khác bị đóng `interrupted`; toàn app tối đa một phiên `in_progress`.
superseded_by:
---
## Rule

Khi mở app còn session `in_progress` của **cùng ngày học**, màn chọn MUST có ba đường: tiếp tục phiên đó, Học mới, hoặc Ôn tập. Chọn một trong hai đường sau MUST chuyển phiên dở sang `abandoned`/`user_exit`. Session `in_progress` của ngày học khác MUST chuyển `abandoned` với `end_reason = interrupted`. Toàn app MUST có tối đa **một** session `in_progress`: mở phiên mới trên **bất kỳ** deck nào MUST đóng mọi phiên đang mở trước đó theo đúng hai cách trên — `user_exit` nếu phiên đó bắt đầu trong ngày học hiện tại, `interrupted` nếu từ ngày học trước — trong cùng transaction mở phiên (spec study session D2, chủ dự án 2026-09-24).

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
