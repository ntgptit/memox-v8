---
id: BR-CARD-007
title: Thẻ chưa học xong lần đầu là new
status: active
summary: Thẻ `learned_at IS NULL` là `new` ở cả hai thuật toán, không suy từ `answer_count`.
superseded_by:
---
## Rule

Thẻ **chưa học xong lần đầu** (`learned_at IS NULL`) MUST là `new`, ở cả hai thuật toán. MUST NOT suy từ `answer_count`, vì chuỗi học mới không sinh lượt `scheduled` nào (BR-STUDY-053).

**Enforced by:** rule
**Liên quan:** BR-CARD-006, BR-SRS-018, BR-STUDY-053

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
