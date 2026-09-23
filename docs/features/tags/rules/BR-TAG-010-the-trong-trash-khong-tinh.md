---
id: BR-TAG-010
title: Thẻ trong Trash không được tính
status: active
summary: Khi có Trash, thẻ trong Trash không được đếm và không xuất hiện khi lọc theo tag.
superseded_by:
---
## Rule

Khi Trash tồn tại, thẻ đang ẩn trong Trash MUST NOT được tính vào số đếm "thẻ đang hoạt động" của catalog (BR-TAG-003) và MUST NOT xuất hiện trong kết quả lọc theo tag. Đổi tên và gộp MUST vẫn giữ liên kết tag của thẻ đang ẩn để khôi phục không mất metadata; purge vĩnh viễn MUST cascade dọn `card_tags` như xoá thẻ thường. Chừng nào Trash chưa tồn tại, mọi thẻ đã lưu đều là thẻ đang hoạt động và rule này MUST NOT được hiện thực bằng một cột hay một trạng thái ẩn được phát minh trước.

**Enforced by:** store
**Liên quan:** BR-TAG-003, BR-TAG-008

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
