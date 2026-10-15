---
id: BR-TOPIK-009
title: Thẻ nội dung suy ra từ dữ liệu
status: active
summary: Các thẻ explanation, translation, words, grammars, script của một đề được suy ra từ dữ liệu có thật, không nhập tay.
superseded_by:
---
## Rule

Một đề mang thẻ `explanation`, `translation`, `words`, `grammars` hoặc `script` khi và chỉ khi ít nhất một câu (hoặc nhóm, với `script`) có dữ liệu đó. Thẻ MUST được tính lúc nạp, không lưu trong file nội dung.

**Enforced by:** rule
**Liên quan:** BR-TOPIK-006, BR-TOPIK-022

## Lý do

Thẻ nhập tay có thể nói một đề có bản dịch trong khi không có; suy ra thì không bao giờ sai.

## Ví dụ

Đề có `words` ở 12 câu và không có `grammars`: hàng của đề hiện thẻ words, không hiện grammars.

## Edge case

Không áp dụng
