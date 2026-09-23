---
id: BR-CARD-002
title: Giới hạn độ dài hai mặt
status: active
summary: Mặt trước tối đa 60 ký tự, mặt sau tối đa 240 ký tự, đo sau trim.
superseded_by:
---
## Rule

Mặt trước MUST tối đa **60** ký tự và mặt sau MUST tối đa **240** ký tự, đo sau khi trim.

**Enforced by:** rule

## Lý do

**BR-CARD-002 đổi số: 2000 cho cả hai → 60 và 240.** Rule giữ nguyên ID chứ
không đánh `superseded`, vì cơ chế supersede (mục "Convention → ID" của `docs/README.md`) dành cho lúc *danh tính* một
rule đổi khiến tham chiếu cũ trỏ sai chỗ. Ở đây ý nghĩa không đổi — "hai mặt có
giới hạn độ dài" — nên 21 chỗ đang trích BR-CARD-002 vẫn trích đúng thứ chúng định
trích. Cái đổi là con số, và nó được ghi ở đây thay vì im lặng.

2000 là **hàng rào chống dán**, không phải một quyết định về thẻ: nó chặn ai đó
thả nguyên một trang vào ô và không nói gì về thẻ nên dài bao nhiêu. 60 là bề
rộng mà hàng danh sách và mặt trước thẻ ôn được vẽ cho; quá đó thì prompt xuống
ba dòng trên điện thoại và câu trả lời rơi khỏi tầm nhìn. 240 gấp bốn vì một
nghĩa chứa nhiều hơn một từ — hai ngôn ngữ, ngăn bằng dấu phẩy.

**Hai mặt nay có hai số, nên giới hạn thuộc về từng mặt thẻ** chứ không phải một
hằng số dùng chung. Một hằng chung là đúng khi số giống nhau và trở thành cách
âm thầm cho mặt trước mượn hạn mức của mặt sau ngay khi chúng khác nhau; test
cho từng mặt ghim đúng điều đó.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
