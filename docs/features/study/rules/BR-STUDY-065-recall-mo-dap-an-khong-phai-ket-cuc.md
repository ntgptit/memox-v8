---
id: BR-STUDY-065
title: recall: mở đáp án không phải kết cục
status: active
summary: Ở `recall`, mở đáp án không ghi lượt; dừng đồng hồ và chuyển sang tự đánh giá hai lựa chọn.
superseded_by:
---
## Rule

Ở `recall`, mở đáp án MUST NOT là một kết cục: nó MUST NOT ghi `review_log`, MUST NOT được chấm đúng hay sai, và MUST dừng đồng hồ rồi chuyển sang **tự đánh giá** với đúng hai lựa chọn — nhớ được (đúng) và đã quên (sai). Chỉ lựa chọn của người học MUST được ghi, đúng một lần cho một lượt.

**Enforced by:** rule + UI
**Liên quan:** BR-MODE-012, BR-STUDY-070, BR-STUDY-032, BR-STUDY-035

## Lý do

**BR-STUDY-065 sửa một lỗi chấm điểm, không phải một lỗi giao diện.** Mở đáp án từng
*là* kết cục "đúng": người học bấm Xem đáp án ở giây thứ tư và thẻ được thăng
hộp vì đã bỏ cuộc. 8-box cần đúng một bit bằng chứng cho mỗi lượt, và bằng chứng
ấy chỉ người học có — nhìn vào mặt sau không nói gì về việc có nhớ hay không.
Nên reveal là **trạng thái trình bày**, còn kết cục là thứ người học nói ra.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
