---
id: BR-STUDY-048
title: browse: xem lại thẻ đã qua
status: active
summary: Chỉ `browse` cho xem lại thẻ đã qua trong round; xem lại không ghi lượt, không lùi `cursor`.
superseded_by:
---
## Rule

Chỉ stage `browse` MUST cho xem lại thẻ đã qua trong cùng round, bằng vuốt hoặc bằng một control tương đương. Đây là **xem, không phải trả lời**: thẻ MUST giữ nguyên `completed`, `study_session.cursor` MUST NOT lùi, và tiến lại qua thẻ đó MUST NOT ghi lượt thứ hai hay tăng `cursor` lần hai. Các stage khác MUST NOT có thao tác này.

**Enforced by:** UI + rule
**Liên quan:** BR-MODE-005, BR-STUDY-004, BR-STUDY-042

## Lý do

**BR-STUDY-048 tồn tại vì `browse` là stage duy nhất không có câu hỏi nào.** Năm stage
còn lại đều lấy một câu trả lời từ thẻ đang hiện; đặt một thẻ đã trả lời lên đó
là mời người dùng chấm lại thứ phiên đã chấm — BR-STUDY-042 nói mỗi câu hỏi sinh tối đa
một lượt, và một màn cho phép quay lại thẻ đã chấm là đường đi thẳng tới lượt thứ
hai. `browse` không chấm gì (BR-MODE-005), nên quay lại nó không mâu thuẫn với điều gì.

Chỗ dễ sai là **lùi rồi tiến**. Nếu lùi làm `cursor` giảm thì tiến lại sẽ đi qua
`markBrowsed` một lần nữa: thẻ được ghi hai lần và bộ đếm nhảy quá tay. Vì vậy
BR-STUDY-048 nói rõ lùi **không** đụng tới queue — nó chỉ đổi thẻ nào đang được vẽ. Bộ
đếm và thanh tiến trình vẫn mô tả lượt đang mở, nên màn hình MUST nói rõ đang xem
lại; nếu không, một thẻ đã qua trông như phiên vừa tự lùi.

Chỗ dễ sai thứ hai là **thứ tự của vết đã xem**. Danh sách thẻ đã xong của một
round trước đây được đọc không kèm `ORDER BY`; `match` dùng nó như một tập nên
không thấy gì, còn `browse` đi ngược nó nên thứ tự là bắt buộc. Câu truy vấn nay
sắp theo `position` — thứ tự queue phục vụ, cũng chính là thứ tự người dùng đã
thấy trong một round phục vụ mỗi thẻ đúng một lần.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
