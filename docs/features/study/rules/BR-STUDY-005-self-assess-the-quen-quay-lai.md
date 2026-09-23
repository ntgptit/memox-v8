---
id: BR-STUDY-005
title: self_assess: thẻ quên quay lại
status: active
summary: Chỉ `self_assess`: thẻ `forgotten`/`again` quay lại cùng hàng đợi sau ít nhất 3 thẻ khác.
superseded_by:
---
## Rule

**Chỉ áp cho mode `self_assess`, ở mọi loại phiên.** Card đánh giá `forgotten`/`again` MUST quay lại trong cùng hàng đợi, sau ít nhất 3 card khác, hoặc cuối hàng đợi nếu không đủ 3. `self_assess` MUST NOT dùng round.

**Enforced by:** store
**Liên quan:** BR-STUDY-073, BR-STUDY-059

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Thẻ trả lời sai trong phiên `mixed`, quay lại sau ba thẻ | Vẫn hỏi đúng chiều cũ — chiều nằm trên chính dòng hàng đợi (BR-STUDY-005, BR-MODE-015) |
