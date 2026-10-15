---
id: BR-TOPIK-012
title: Đáp án lưu ngay và đổi được
status: active
summary: Mỗi lần chọn hoặc đổi đáp án được ghi ngay; đáp án mới ghi đè đáp án cũ; MVP không có thao tác bỏ chọn.
superseded_by:
---
## Rule

Khi lượt đang `in_progress`, mỗi lần chọn một lựa chọn MUST được ghi vào database ngay, ghi đè lựa chọn trước của câu đó, cùng `answered_at` và câu hiện tại. Câu bỏ qua (chưa chọn) giữ `selected_idx` rỗng. MVP không có thao tác bỏ chọn một câu đã trả lời.

**Enforced by:** store
**Liên quan:** BR-TOPIK-010, BR-TOPIK-015

## Lý do

Học trên điện thoại hay bị ngắt; lưu từng lần chọn bảo đảm không mất gì khi app bị kill.

## Ví dụ

Chọn ② ở câu 9, quay lại và chọn ④: câu 9 lưu ④.

## Edge case

App bị kill ngay sau khi chọn: mở lại thấy lựa chọn đó.
