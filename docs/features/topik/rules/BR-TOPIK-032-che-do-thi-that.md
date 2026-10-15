---
id: BR-TOPIK-032
title: Chế độ thi thật
status: draft
summary: Phase B: Exam mode phát audio đúng số lần, không tua, không dừng, tự chuyển nhóm và tự nộp khi hết giờ.
superseded_by:
---
## Rule

Exam mode MUST phát mỗi nhóm đúng `playCount` lần (BR-TOPIK-004), không cho tua hay dừng, đếm ngược thời gian trả lời sau mỗi nhóm rồi tự chuyển, và tự nộp khi hết thời gian chính thức của phần thi. Đổi câu trong cùng nhóm không phát thêm lần nào.

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-004, BR-TOPIK-010

## Lý do

Phase B ([spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §5.5).

## Ví dụ

TOPIK II câu 5 phát một lần; câu 21–22 phát hai lần rồi tự sang câu 23.

## Edge case

Không áp dụng
