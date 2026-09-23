---
id: BR-STUDY-012
title: Bảy giá trị end_reason
status: active
summary: `study_session.end_reason` có đúng bảy giá trị; NULL khi chưa hoặc kết thúc bình thường.
superseded_by:
---
## Rule

`study_session.end_reason` MUST có đúng bảy giá trị: `user_exit`, `interrupted`, `scheduler_reset`, `scheduler_changed`, `stale_generation`, `persistence_error`, `content_deleted`; NULL khi chưa kết thúc hoặc kết thúc bình thường.

**Enforced by:** db + invariant Q12
**Liên quan:** BR-STUDY-072, BR-STUDY-016, BR-TRASH-004

## Lý do

BR-STUDY-012 thay BR-STUDY-011 chỉ để đếm lại tập giá trị. BR-STUDY-011 được viết khi `end_reason`
có năm giá trị; `content_deleted` vào sau, cùng Trash (BR-TRASH-004), và
`scheduler_changed` vào sau, khi đổi scheduler tách khỏi reset (BR-STUDY-016).
CHECK trong schema và kiểu dữ liệu lý do kết thúc phiên (`end_reason`) đã nhận
cả bảy từ lúc đó, còn BR-STUDY-011 thì không được đếm lại — tài liệu nói năm trong khi
database nhận bảy.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
