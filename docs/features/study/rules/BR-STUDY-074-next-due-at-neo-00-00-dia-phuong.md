---
id: BR-STUDY-074
title: next_due_at neo 00:00 địa phương
status: active
summary: `next_due_at` rơi vào 00:00 giờ địa phương của ngày thứ N; lưu bằng UTC.
superseded_by:
---
## Rule

`next_due_at` MUST rơi vào **00:00 giờ địa phương** của ngày thứ N, với N là interval do thuật toán trả về. Giá trị lưu vẫn là UTC.

**Enforced by:** rule
**Liên quan:** BR-SRS-009, BR-SRS-011

## Lý do

BR-STUDY-074 sửa một chỗ trôi mà không ai thấy: `now + N*24h` đẩy mốc đến hạn muộn dần
theo giờ người dùng bấm. Học lúc 23:00 thì hôm sau 22:00 thẻ **chưa** tới hạn, và
mỗi phiên lại đẩy thêm — giờ học trôi dần về khuya cho tới khi người dùng hụt cả
một ngày. Neo vào đầu ngày lịch làm "đến hạn hôm nay" đúng nghĩa là hôm nay.

**Mốc 00:00 làm khoảng cách đầu tiên phụ thuộc giờ học, và đó là đánh đổi đã
nhận.** Thẻ học xong lúc 09:00 đến hạn sau 15 giờ; thẻ học xong lúc 23:00 đến hạn
sau **một giờ**. Từ lượt ôn thứ hai trở đi thì khoảng cách đo bằng ngày lịch nên
không còn lệch, nhưng lượt đầu tiên thì có.

Đây là giá của việc neo vào **ngày lịch** thay vì cộng giờ (BR-STUDY-074), và cái mua
được lớn hơn: giờ học không trôi dần về khuya, và "đến hạn hôm nay" đúng nghĩa là
hôm nay. Nếu sau này muốn gỡ, lối đi là mốc cắt khác 00:00 — sửa ở đúng một chỗ,
vì offset múi giờ chỉ do composition root cấp, không phải sửa công thức.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
