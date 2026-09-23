---
id: BR-STUDY-066
title: recall: nhịp của hai kết thúc
status: active
summary: Tự đánh giá tự chuyển lượt sau commit; hết giờ hiện trạng thái sai và nút Tiếp theo.
superseded_by:
---
## Rule

Hai kết thúc của `recall` MUST có nhịp khác nhau. Tự đánh giá: sau khi commit MUST tự chuyển lượt, MUST NOT giữ thêm một thời lượng cố định và MUST NOT hiện nút Tiếp theo. Hết giờ: sau khi commit MUST hiện trạng thái đã bị tính sai và một nút Tiếp theo, MUST NOT tự chuyển theo thời lượng; bấm Tiếp theo MUST chỉ chuyển lượt và MUST NOT ghi thêm đáp án nào.

**Enforced by:** UI
**Liên quan:** BR-STUDY-032, BR-STUDY-033, BR-STUDY-063, BR-STUDY-064

## Lý do

**BR-STUDY-066 là hệ quả của việc hai kết thúc do hai người bấm giờ.** Tự đánh giá xảy
ra *sau* khi người học đã đọc mặt sau, nên giữ màn hình thêm một nhịp là bắt họ
chờ trên thứ họ đọc xong rồi. Hết giờ thì ngược lại: mặt sau là chữ họ chưa từng
thấy, trên một thẻ vừa mất vì đồng hồ — không ai chọn hộ được thời lượng ấy, nên
nó kết thúc ở một nút họ bấm. Một con số cố định phục vụ cả hai thì sai cả hai
lần, và 1800/2200ms đang đo một việc không ai làm.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
