---
id: BR-DECK-027
title: Sắp theo tiến độ
status: active
summary: Sort Progress xếp deck theo mastery tăng dần; deck không có thẻ xếp cuối; bằng nhau thì theo thứ tự thủ công.
superseded_by:
---
## Rule

Sort "Progress · Least mastered first" MUST xếp các deck của một level theo mastery (BR-DECK-026) **tăng dần**. Deck không có thẻ nào MUST đứng sau mọi deck có thẻ. Hai deck có cùng tỉ lệ MUST giữ thứ tự thủ công `(sibling_position, id)`, như mọi kiểu sort khác. So sánh MUST dùng số nguyên (nhân chéo), để 1/2 và 2/4 bằng nhau.

**Enforced by:** rule
**Liên quan:** BR-DECK-026, UC-DECK-003, UC-DECK-006

## Lý do

Sort này trả lời câu "deck nào cần mình nhất". Deck rỗng không cần gì, nên đứng cuối
thay vì đứng đầu cùng các deck 0 % (chủ dự án chốt ngày 2026-09-27,
[spec](../../../superpowers/specs/2026-09-27-deck-mastery-design.md) R2). Đây là
view-only sort: khi nó đang dùng, thao tác reorder bị ẩn (UC-DECK-006).

## Ví dụ

0 % (có thẻ) < 3,5 % < 16 % < 100 %, rồi tới các deck rỗng.

## Edge case

Bộ lọc "Only decks with due cards" lọc trước; sort chỉ xếp các deck còn lại.
