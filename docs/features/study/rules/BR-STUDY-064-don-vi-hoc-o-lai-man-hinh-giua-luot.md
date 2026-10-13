---
id: BR-STUDY-064
title: Đơn vị học ở lại màn hình giữa hai lượt
status: active
summary: Đơn vị học đang hiện ở lại trong lúc đọc kết quả và tải lượt kế; mỗi mode có thời lượng hiện kết quả riêng.
superseded_by:
---
## Rule

Đơn vị học đang hiển thị MUST ở lại màn hình trong suốt thời gian đọc kết quả và trong suốt lúc tải lượt kế tiếp; MUST NOT thay thân màn bằng trạng thái tải giữa hai lượt. Trạng thái tải toàn thân MUST chỉ dùng khi phiên chưa có lượt nào. Mỗi mode MUST có thời lượng hiển thị kết quả riêng, đặt ở widget của mode đó:

| Mode | Kết quả đúng | Kết quả sai |
|---|---|---|
| `guess` | giữ 1,2 giây; chạm bất kỳ đâu hoặc `Next` thì sang ngay; khi trình đọc màn hình bật thì chỉ có `Next` | như kết quả đúng |
| `match` | không giữ; cặp chuyển sang matched | nháy 600 ms rồi bàn nhận chạm tiếp |
| `recall` | tự đánh giá: không giữ (BR-STUDY-066) | hết giờ: giữ tới khi bấm `Continue` (BR-STUDY-066) |
| `fill` | không giữ | giữ tới khi bấm `Continue` |
| `self_assess` | không giữ | không giữ |

`browse` không có kết quả để hiện.

**Enforced by:** UI
**Liên quan:** BR-STUDY-004, BR-STUDY-063

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
