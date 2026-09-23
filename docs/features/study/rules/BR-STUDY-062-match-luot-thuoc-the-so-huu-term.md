---
id: BR-STUDY-062
title: match: lượt thuộc thẻ sở hữu term
status: active
summary: Lượt `match` thuộc thẻ sở hữu term bất kể vế nào chạm trước; cặp sai giữ thẻ trên bàn.
superseded_by:
---
## Rule

Một lượt MUST thuộc về thẻ sở hữu **term**, bất kể vế nào được chạm trước; chạm meaning trước MUST được chấp nhận. Chọn nhầm meaning MUST NOT đánh dấu thẻ sở hữu meaning đó là không đạt. Một cặp sai MUST giữ hàng queue của round hiện tại ở `pending` — thẻ ở lại bàn để ghép lại — và MUST enroll thẻ vào round kế tiếp đúng một lần.

**Enforced by:** rule
**Liên quan:** BR-STUDY-059, BR-STUDY-060

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
