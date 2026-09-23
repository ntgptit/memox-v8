# Study session — dữ liệu

Bảng, cột, index và invariant nằm ở `shared/data/schema.md`. File này chỉ giữ phần dữ liệu riêng của feature.

## Study session

| From | To | Trigger |
|---|---|---|
| in_progress | completed | hết queue (BR-STUDY-013) |
| in_progress | abandoned | người dùng thoát hoặc chọn đường mới thay vì tiếp tục (`user_exit`, BR-STUDY-014, BR-STUDY-072), hoặc phiên của ngày học trước không được tiếp tục (`interrupted`, BR-STUDY-072) |
| in_progress | invalidated | reset khi đang mở (`scheduler_reset`, BR-STUDY-015), đổi scheduler khi chưa khoá (`scheduler_changed`, BR-STUDY-016), ghi từ generation cũ (`stale_generation`, BR-STUDY-017), hoặc nội dung của phiên vào Trash (`content_deleted`, BR-TRASH-004) |
| in_progress | failed | lỗi không thể tiếp tục (BR-STUDY-018) |

Trạng thái kết thúc là terminal — không có đường quay lại `in_progress`.
