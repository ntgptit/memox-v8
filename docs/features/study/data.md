# Study session — dữ liệu

Bảng, cột, index và invariant nằm ở `shared/data/schema.md`. File này chỉ giữ phần dữ liệu riêng của feature.

## Study session

| From | To | Trigger |
|---|---|---|
| in_progress | completed | hết queue (BR-STUDY-013), kể cả khi các dòng còn lại biến mất vì thẻ của chúng bị xóa hẳn: Tiếp tục phiên sẽ đi tiếp và kết thúc nó. `content_deleted` chỉ dành cho nội dung vào Trash |
| in_progress | abandoned | người dùng thoát hoặc chọn đường mới thay vì tiếp tục (`user_exit`, BR-STUDY-014, BR-STUDY-072), hoặc phiên của ngày học trước không được tiếp tục (`interrupted`, BR-STUDY-072) |
| in_progress | invalidated | reset khi đang mở (`scheduler_reset`, BR-STUDY-015), đổi scheduler khi chưa khoá (`scheduler_changed`, BR-STUDY-016), ghi từ generation cũ (`stale_generation`, BR-STUDY-017), hoặc nội dung của phiên vào Trash (`content_deleted`, BR-TRASH-004) |
| in_progress | failed | lỗi không thể tiếp tục (BR-STUDY-018) |

Trạng thái kết thúc là terminal — không có đường quay lại `in_progress`.

## Dựng round

Một round có được thứ nó cần khi bắt đầu được phục vụ: lúc mở phiên ôn tập, khi phiên
học mới sang một stage, khi dựng một round mới, và khi Tiếp tục.

- `match`: mỗi bàn (các vị trí `5k … 5k+4` của round) có chỗ riêng cho nghĩa của từng
  cặp. Chỗ được xáo theo bàn, và không trùng thứ tự term khi bàn có từ hai cặp
  (BR-STUDY-049).
- `guess`: mỗi dòng `pending` có một câu năm lựa chọn. Nguồn là thẻ trong hàng đợi của
  phiên và thẻ đã học, còn hoạt động, của cây; mỗi nghĩa (`back_folded`) góp tối đa một
  thẻ (BR-STUDY-037, BR-STUDY-038, BR-STUDY-039). Câu không dựng đủ năm lựa chọn thì bị
  chặn (BR-STUDY-040).
- Dựng chỉ bổ sung phần còn thiếu: bàn đã có chỗ và câu đã đủ năm lựa chọn giữ nguyên,
  nên Tiếp tục không đổi thứ tự (BR-STUDY-043). Tiếp tục dựng lại câu đã mất một lựa
  chọn vì card của lựa chọn đó bị xoá hẳn.

## Ghi không phải lượt

Ba lệnh ghi trạng thái của lượt đang dở mà không phải một lượt: không ghi
`review_log`, không tiến `cursor`. Chúng bị từ chối ở đúng những chỗ một lượt bị từ
chối: phiên đã đóng, root đã reset sau khi phiên mở, thẻ không phải thẻ đang phục vụ,
hoặc phiên đang ở mode khác.

| Lệnh | Mode | Ghi |
|---|---|---|
| Lật đáp án | `recall` | `is_revealed = 1`; đồng hồ dừng ở thời gian còn lại. Lật lần hai không đổi gì (BR-STUDY-065, BR-STUDY-036) |
| Lưu thời gian | `recall` | `remaining_ms`, chỉ giảm; đã lật thì không đổi nữa (BR-STUDY-036) |
| Hiện gợi ý | `fill` | `hint_shown = 1`; lượt sau đó ghi `used_hint = 1` mà kết quả không đổi. Thẻ không có gợi ý thì bị từ chối (BR-STUDY-028) |

Một lượt mới ở round sau là một dòng mới, nên bắt đầu lại đủ 20 giây, đáp án ẩn và
gợi ý chưa hiện (BR-STUDY-036).

## Tab Study

Tab Study đọc một snapshot trong một transaction: mọi root deck kèm workload của cả
cây (cùng câu truy vấn với cấp root của Thư viện), phiên có thể Resume cùng số đếm của
round nó đang phục vụ, và hạn gần nhất sau hiện tại (UC-STUDY-002).

- Resume chỉ nhận phiên `in_progress`, bắt đầu từ đầu ngày học hiện tại, cùng
  generation với root, deck và root không nằm trong Trash, và còn ít nhất một dòng hàng
  đợi. Nhiều phiên thì lấy phiên mới nhất; bắt đầu cùng lúc thì lấy `id` lớn hơn
  (BR-STUDY-075). Tiếp tục ở màn vào học dùng đúng các điều kiện này.
- Đọc không ghi gì: phiên của ngày trước vẫn mở cho tới khi `abandonStaleSessions` đóng
  nó (BR-STUDY-072).
- Snapshot được đọc lại sau mỗi lần ghi vào `deck`, `card`, `card_schedule`,
  `study_session` hay `study_queue_items`, và ở mỗi nửa đêm địa phương.
