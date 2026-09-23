---
id: BR-STUDY-045
title: match: ít nhất hai cặp
status: active
summary: `match` cần ít nhất hai cặp; một cặp thì bỏ qua (learning) hoặc vô hiệu hoá (reviewing).
superseded_by:
---
## Rule

`match` MUST có ít nhất **hai** cặp trên bàn. Một cặp duy nhất làm đáp án hiển nhiên, nên stage MUST bị bỏ qua (phiên `learning`) hoặc vô hiệu hoá trên màn chọn (phiên `reviewing`) theo BR-MODE-009.

**Enforced by:** rule + UI
**Liên quan:** BR-MODE-009, BR-STUDY-059

## Lý do

BR-STUDY-045 tồn tại vì một deck mới tạo với đúng một thẻ là ca thật, không phải ca biên:
người dùng thêm thẻ đầu tiên rồi bấm Học mới ngay. Không có luật này thì `match`
hiện một cặp và người học ghép nó với chính nó — một lượt đúng không chứng minh gì.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
