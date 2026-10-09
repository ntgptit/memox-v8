---
id: BR-STUDY-078
title: Đọc term khi thẻ mới xuất hiện
status: active
summary: Trong phiên `learning`, mỗi lượt mới ở `browse`, `self_assess`, `guess`, `recall` đọc to `front` một lần bằng ngôn ngữ phát âm của root deck.
superseded_by:
---
## Rule

Trong phiên `learning`, khi lượt thẻ phục vụ đổi (`cardId` khác, hoặc cùng thẻ ở mode, round hay lượt khác của hàng), app MUST đọc to `front` của thẻ đúng một lần bằng ngôn ngữ phát âm của root deck (BR-SETTINGS-009) khi mode là `browse`, `self_assess`, `guess` hoặc `recall`. App MUST NOT đọc ở `fill` (term là đáp án), ở `match` (không có một thẻ hiện hành) và trong phiên `reviewing`.

**Enforced by:** UI
**Liên quan:** BR-MODE-002, BR-STUDY-056, BR-SETTINGS-009, BR-STUDY-079

## Lý do

Nghe từ là mục đích của việc học từ vựng; chỉ đọc khi term là đề, không đọc khi term là đáp án.

## Ví dụ

Không áp dụng

## Edge case

Nhìn lại thẻ cũ trong Browse (BR-STUDY-048) không tự đọc: đó là liếc lại, không phải thẻ mới; nút loa trên mặt thẻ đọc thẻ đang hiển thị. Khi screen reader bật (`accessibleNavigation`) app MUST NOT tự đọc vì TalkBack đã đọc thẻ; nút loa vẫn đọc.
