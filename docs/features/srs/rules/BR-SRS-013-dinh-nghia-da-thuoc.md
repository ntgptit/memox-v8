---
id: BR-SRS-013
title: Định nghĩa "đã thuộc"
status: active
summary: Card "đã thuộc" khi `current_box = 8` (`eight_box`) hoặc `interval_days >= 128` (`sm2`); suy ra khi đọc.
superseded_by:
---
## Rule

Một card MUST được tính là "đã thuộc" khi:

| Scheduler | Điều kiện |
|---|---|
| `eight_box` | `current_box = 8` |
| `sm2` | `interval_days >= 128` |

Giá trị này MUST được suy ra khi đọc và MUST NOT là cột trong DB.

**Enforced by:** db (query tổng hợp)
**Liên quan:** BR-SRS-009, BR-SRS-011

## Lý do

**Nửa `eight_box` không phải luật mới.** BR-SRS-009 đã phát biểu nó bằng văn xuôi từ
trước: *"Đã thuộc" (`current_box == 8`) là giá trị suy ra để hiển thị, không phải
cột trong DB*. BR-SRS-013 chỉ nâng nó thành một rule có ID và mở rộng sang scheduler
thứ hai, vì màn deck cần một con số dùng được cho cả hai.

**Vì sao `sm2` là 128 ngày và không phải 21.** 21 là ngưỡng "mature card" quen
thuộc của SM-2/Anki, và nó tới sớm hơn nhiều — khoảng bốn lần trả lời tốt
(1 → 6 → 15 → 37). Chọn 128 vì nó **khớp đúng interval của box 8** (BR-SRS-009), nên
"đã thuộc" nghĩa là cùng một khoảng cách thời gian ở cả hai scheduler thay vì
cùng một quy ước ở một cái và một quy ước khác ở cái kia.

Cái giá đã nhận, nói thẳng vì nó nhìn thấy được: một deck `sm2` cần khoảng bảy
lần trả lời tốt mới có card đầu tiên "đã thuộc", nên thanh tiến độ của nó nhúc
nhích chậm hơn hẳn một deck `eight_box` cùng số lần ôn. Đó là hệ quả của việc
khớp theo thời gian chứ không phải theo công sức, và là lựa chọn có ý thức.

**Suy ra khi đọc, không lưu.** Một cột `is_learned` sẽ phải cập nhật ở mọi
đường ghi chạm vào `current_box` hoặc `interval_days`, và sẽ sai ngay lần đầu
một đường nào đó quên — trong khi ngưỡng thì đứng yên và cả hai cột đã có index
cần thiết. Reset learning progress vì thế cũng tự động đúng: nó đặt lại state,
và con số suy ra đi theo.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
