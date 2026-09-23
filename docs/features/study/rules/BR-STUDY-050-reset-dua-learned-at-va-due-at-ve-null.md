---
id: BR-STUDY-050
title: Reset đưa learned_at và due_at về NULL
status: active
summary: Reset đặt `learned_at` và `due_at` cùng về NULL.
superseded_by:
---
## Rule

Reset MUST đặt `learned_at` và `due_at` cùng về NULL. MUST NOT để thẻ có `learned_at` mà không có lịch (BR-STUDY-058).

**Enforced by:** store
**Liên quan:** BR-SRS-022, BR-STUDY-058

## Lý do

**BR-STUDY-050 tồn tại vì invariant 24 đã bắt được một mâu thuẫn.** Reset xoá lịch;
nếu nó giữ `learned_at` thì mỗi lần reset sẽ để lại một thẻ "đã học xong nhưng
không có lịch" — đúng thiếu sót mà invariant 24 được viết để chặn, và một thẻ
không thuộc tập nào trong hai tập của BR-STUDY-051. Xoá cả hai cùng lúc đưa thẻ về
đúng trạng thái trước khi học — đúng nghĩa của "đặt lại tiến độ".

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
