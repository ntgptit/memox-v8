---
id: BR-CARD-008
title: Ngưỡng 8 ngày giữa beginning và reviewing
status: active
summary: Thẻ đã học, chưa "đã thuộc": interval dưới 8 ngày là `beginning`, từ 8 ngày là `reviewing`.
superseded_by:
---
## Rule

Với thẻ đã học và chưa "đã thuộc": interval hiện tại dưới 8 ngày MUST là `beginning`, từ 8 ngày trở lên MUST là `reviewing`. Với `eight_box` đó là box 1–3 và box 4–7; với `sm2` là `interval_days` < 8 và 8…127.

**Enforced by:** rule
**Liên quan:** BR-CARD-006, BR-SRS-009, BR-SRS-013

## Lý do

**Mốc 8 ngày không phải số mới.** Nó là interval của box 4 trong BR-SRS-009, và thang
đó là luỹ thừa của hai — 1, 2, 4, **8**, 16, 32, 64, 128 — nên box 1–3 là toàn bộ
phần dưới một tuần và box 4 là bước đầu tiên ra khỏi nhịp ôn ngắn. Dùng lại đúng
mốc đó cho `sm2` khiến `beginning` nghĩa là **cùng một khoảng cách thời gian** ở
cả hai scheduler, là chính lập luận BR-SRS-013 dùng khi chọn 128 thay vì 21.

Chọn một ngưỡng riêng cho `sm2` — 7 ngày, hay 30 — sẽ khiến hai deck cùng nhịp
ôn hiện hai nhãn khác nhau, và không có gì trong dữ liệu giải thích được vì sao.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
