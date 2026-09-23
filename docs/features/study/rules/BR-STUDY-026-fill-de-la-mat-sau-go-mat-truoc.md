---
id: BR-STUDY-026
title: fill: đề là mặt sau, gõ mặt trước
status: active
summary: `fill` hiện mặt sau làm đề, yêu cầu gõ mặt trước, chấm bằng so dạng fold với `front_folded`.
superseded_by:
---
## Rule

`fill` MUST hiển thị **mặt sau** của thẻ làm đề bài và MUST yêu cầu người học gõ **mặt trước**: theo BR-CARD-002, `front` giữ term (tiếng Hàn) và `back` giữ nghĩa. Việc chấm MUST so dạng **đã fold** của câu trả lời với `front_folded` của thẻ — trim hai đầu và hạ hoa Unicode-aware — và khi sai, đáp án hiển thị MUST là `front`. Chính sách này **giữ nguyên dấu** — `cong` MUST NOT khớp `công`.

**Enforced by:** rule
**Liên quan:** BR-CARD-002, BR-STUDY-039, BR-STUDY-027

## Lý do

**BR-STUDY-026 dùng lại `back_folded`, và điều đáng kiểm là nó fold những gì.** Cột đó
trim và hạ hoa Unicode-aware nhưng **không bỏ dấu** — chỉ fold hoa/thường, nên
`công` vẫn không khớp `cong`. Nếu nó fold cả dấu thì `fill`
sẽ chấm "ma" bằng "mà" là đúng, và một app học từ vựng tiếng Việt hỏng ở đúng chỗ
quan trọng nhất. Kiểm trước khi dùng lại, không suy từ cái tên.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
