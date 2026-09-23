---
id: BR-STUDY-056
title: Tùy chọn học hai tầng
status: active
summary: Tùy chọn học có mặc định toàn app và ghi đè trên root deck; deck con không có tùy chọn riêng.
superseded_by:
---
## Rule

Tùy chọn học MUST có hai tầng: mặc định toàn app, và ghi đè trên **root deck**. Deck có giá trị riêng thì dùng giá trị đó; NULL thì theo mặc định. Deck con MUST NOT có tùy chọn riêng — tra qua `root_id` như BR-DECK-025.

**Enforced by:** db
**Liên quan:** BR-DECK-025, BR-STUDY-024, BR-STUDY-057

## Lý do

**BR-STUDY-056 tách hai tầng vì hai deck không giống nhau.** Một deck nhập từ giáo trình
cần học theo thứ tự bài; một deck từ vựng rời thì ngẫu nhiên tốt hơn. Bắt người
dùng chọn một kiểu cho cả hai là bắt họ chọn sai cho một trong hai. Deck để NULL
thì theo mặc định, nên không ai phải cấu hình gì để bắt đầu.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
