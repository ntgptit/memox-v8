---
id: BR-STUDY-036
title: Lưu thời gian còn lại và trạng thái lật
status: active
summary: Thời gian còn lại và trạng thái đã lật được lưu để Resume đúng chỗ, không đặt lại 20 giây.
superseded_by:
---
## Rule

Thời gian còn lại và trạng thái đã lật MUST được lưu để Resume tiếp tục đúng chỗ, MUST NOT đặt lại 20 giây. Lượt Resume với `is_revealed = true` và còn thời gian MUST quay lại **tự đánh giá** với đáp án đang hiện và đồng hồ đã dừng, MUST NOT chạy lại đồng hồ. Một lượt mới của thẻ ở round sau là lượt khác và MUST bắt đầu lại đủ 20 giây với đáp án ẩn.

**Enforced by:** db + UI
**Liên quan:** BR-STUDY-072, BR-STUDY-059, BR-STUDY-031, BR-STUDY-065

## Lý do

**BR-STUDY-036 là hệ quả của BR-STUDY-072, không phải một yêu cầu UI.** Phiên sống sót qua
việc hệ điều hành thu hồi app, nên "còn bao nhiêu giây" phải nằm trong database
chứ không trong bộ nhớ của một controller. Ngược lại, một lượt mới ở round sau
bắt đầu lại đủ 20 giây — nó là lượt khác, không phải phần còn lại của lượt cũ.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
