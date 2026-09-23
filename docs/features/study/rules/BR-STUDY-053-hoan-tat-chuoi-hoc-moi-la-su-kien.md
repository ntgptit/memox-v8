---
id: BR-STUDY-053
title: Hoàn tất chuỗi học mới là sự kiện
status: active
summary: Chuỗi học mới không đổi lịch tới khi thẻ đi hết stage của nó; hoàn tất là sự kiện đặt `learned_at` và lịch đầu.
superseded_by:
---
## Rule

Chuỗi học mới MUST NOT đổi `card_schedule` cho tới khi thẻ đi hết **stage cuối mà chính nó tham gia** — stage bỏ qua thẻ theo BR-STUDY-071 không được tính là stage nó phải đợi. **Hoàn tất là một sự kiện, không phải một lượt đánh giá**: nó đặt `learned_at`, khởi tạo lịch ở mức thấp nhất — `eight_box` box 1, `sm2` interval 1 — với `due_at` là đầu ngày học kế tiếp (BR-STUDY-074), và MUST NOT ghi lượt `scheduled` nào.

**Enforced by:** store
**Liên quan:** BR-STUDY-023, BR-STUDY-074, BR-SRS-003, BR-STUDY-071

## Lý do

**BR-STUDY-053 làm một vấn đề biến mất thay vì phải xử lý nó.** Nếu chuỗi học mới đặt
lịch dọc đường thì một phiên bỏ dở ở stage 3 để lại thẻ có lịch nhưng chưa học
xong, và lần học mới sau sẽ đặt lại lịch lần hai. Gỡ chuyện đó cần hoàn tác
`card_schedule` từ `previous_*`, giảm `lapse_count`, và xoá lượt — tức sửa BR-STUDY-019,
thứ tồn tại để đảm bảo không lượt nào bị mất.

Không đặt lịch cho tới khi xong chuỗi thì **không có gì để hoàn tác**: thẻ bỏ dở
chưa có `learned_at`, chưa có `due_at`, nên nó đơn giản nằm lại trong tập học mới
và học lại từ `browse`. Các lượt đã ghi vẫn ở nguyên trong `review_log` dưới
`kind = 'learning'` — chúng là lịch sử thật về việc người học đã gặp thẻ đó.

**Hoàn tất học mới là sự kiện, không phải lượt đánh giá** — và đó là lý do nó
không cần một `action` tổng kết. Bốn stage chấm điểm đều lặp round tới khi sạch
(BR-STUDY-069), nên mọi thẻ đều kết thúc chuỗi bằng một lần đúng: một action suy từ đó
sẽ luôn là "nhớ được" và không phân biệt được thẻ nào. Thẻ vừa học lần đầu
vì thế bắt đầu ở mức thấp nhất và gặp lại ngay ngày học kế — một buổi học không
đủ dữ kiện để nói thẻ nào dễ.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
