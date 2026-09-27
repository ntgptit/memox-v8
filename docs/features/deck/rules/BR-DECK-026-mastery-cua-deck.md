---
id: BR-DECK-026
title: Mastery của deck
status: active
summary: Mastery của một deck là số thẻ `mastered` chia cho mọi thẻ active trong cả cây, kể cả thẻ mới; suy ra khi đọc, không lưu cột.
superseded_by:
---
## Rule

Mastery của một deck MUST là số thẻ active có trạng thái hiển thị `mastered` (BR-CARD-006, BR-SRS-013) trong cả cây của deck, chia cho **mọi** thẻ active của cây đó, kể cả thẻ `new`. Thẻ và deck trong Trash MUST NOT được tính. Tỉ lệ MUST được suy ra khi đọc và MUST NOT là cột trong DB. Deck không có thẻ nào MUST NOT có tỉ lệ: thanh mastery chỉ vẽ track rỗng.

**Enforced by:** rule
**Liên quan:** BR-CARD-006, BR-SRS-013, BR-DECK-002, BR-DECK-027

## Lý do

**Mẫu số gồm cả thẻ mới.** Thanh mastery trả lời "bao nhiêu phần của deck này đã ở lại
với mình", không phải "mình đã đi được bao xa". Một deck lớn mới bắt đầu học vì thế
hiện thấp, và điều đó đúng. Số liệu mẫu của kit cũng tính như vậy: 204 / 1.248 thẻ =
16 %. Donut của card list (màn 07) cũng dùng đúng tỉ lệ `mastered / total`, nên hai màn
không lệch nhau.

**Không có tỉ lệ khi không có thẻ.** 0 / 0 không phải 0 %. Deck rỗng không có gì để
thuộc, nên nó xếp cuối khi sort theo tiến độ (BR-DECK-027) và hàng của nó không đọc
phần trăm nào.

Chủ dự án chốt định nghĩa này ngày 2026-09-27
([spec](../../../superpowers/specs/2026-09-27-deck-mastery-design.md) R1).

## Ví dụ

- Cây có 1.248 thẻ, 204 thẻ `mastered`: mastery 16 %.
- Cây có 5 thẻ đều `new`: mastery 0 %.
- Cây có 10 thẻ, 1 thẻ `mastered` nằm trong Trash: mastery 0 / 9.

## Edge case

- Thẻ chưa học xong lần đầu (`learned_at IS NULL`) không bao giờ `mastered`, kể cả khi
  box hay interval chạm ngưỡng (BR-CARD-007).
- Deck chỉ chứa deck con rỗng: không có tỉ lệ; donut ở tóm tắt của deck đó đọc 0 %.
