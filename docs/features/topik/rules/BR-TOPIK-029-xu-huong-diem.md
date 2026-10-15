---
id: BR-TOPIK-029
title: Xu hướng điểm
status: draft
summary: Phase B: xu hướng so trung bình k lượt mới nhất với k lượt trước, ngưỡng ±3 điểm.
superseded_by:
---
## Rule

Cần ít nhất hai lượt đã nộp. k = min(2, ⌊n/2⌋). Δ = trung bình điểm của k lượt mới nhất − trung bình của k lượt trước chúng. Δ > 3: Improving; Δ < −3: Declining; còn lại Stable.

**Enforced by:** rule
**Liên quan:** BR-TOPIK-020

## Lý do

Phase B ([spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §6.5); công thức chốt trước để không ai tự nghĩ ra khi làm.

## Ví dụ

Điểm 70, 72, 80, 84 (n = 4, k = 2): Δ = 82 − 71 = 11, Improving.

## Edge case

n = 2: k = 1, so lượt cuối với lượt trước nó.
