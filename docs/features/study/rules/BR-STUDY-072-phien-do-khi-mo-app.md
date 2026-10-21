---
id: BR-STUDY-072
title: Phiên dở khi mở app
status: active
summary: Còn phiên dở cùng ngày học: ba đường tiếp tục, Học mới, Ôn tập; phiên của ngày khác bị đóng `interrupted`; toàn app tối đa một phiên `in_progress`, và Study Entry của mọi deck hiện phiên đó với đường dẫn deck đầy đủ.
superseded_by:
---
## Rule

Khi mở app còn session `in_progress` của **cùng ngày học**, màn chọn MUST có ba đường: tiếp tục phiên đó, Học mới, hoặc Ôn tập. Chọn một trong hai đường sau MUST chuyển phiên dở sang `abandoned`/`user_exit`. Session `in_progress` của ngày học khác MUST chuyển `abandoned` với `end_reason = interrupted`. Toàn app MUST có tối đa **một** session `in_progress`: mở phiên mới trên **bất kỳ** deck nào MUST đóng mọi phiên đang mở trước đó theo đúng hai cách trên — `user_exit` nếu phiên đó bắt đầu trong ngày học hiện tại, `interrupted` nếu từ ngày học trước — trong cùng transaction mở phiên (spec study session D2, chủ dự án 2026-09-24). Vì vậy, Study Entry của **mọi** deck MUST hiện phiên dở hợp lệ của toàn app (BR-STUDY-075), kể cả khi phiên thuộc deck khác. Khi đó nó MUST nêu tên deck của phiên (tối đa hai dòng, quá thì cắt bằng "…"), như thẻ Resume của Study home; đường dẫn đầy đủ từ root xem qua nút ⓘ (sheet "Vị trí bộ thẻ"). Phiên được định danh bằng id, không dựa vào tên: hai deck trùng tên vẫn mở đúng phiên (chủ dự án 2026-10-21, spec 2026-10-21 D2, D3). Continue MUST mở đúng phiên đó và là hành động primary duy nhất, và MUST nói trước rằng bắt đầu phiên mới sẽ kết thúc phiên dở và giữ câu trả lời. Chỉ xem hoặc chuyển giữa các deck MUST NOT kết thúc phiên (chủ dự án 2026-10-21).

**Enforced by:** store + UI
**Liên quan:** BR-STUDY-012, BR-STUDY-074, BR-STUDY-051, BR-STUDY-075

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| App bị thu hồi giữa phiên `mixed`, mở lại | Resume đọc chiều đã lưu, không hỏi lại và không gieo lại (BR-STUDY-072, BR-MODE-017) |
| Mở Study Entry của deck A khi phiên dở thuộc deck B (con của A hoặc deck không liên quan) | Banner Continue nêu đường dẫn của B, Continue mở phiên của B; bắt đầu phiên mới trên A đóng phiên của B `abandoned`/`user_exit`, giữ câu trả lời, sau khi ghi chú và caption đã báo trước (chủ dự án 2026-10-21) |
