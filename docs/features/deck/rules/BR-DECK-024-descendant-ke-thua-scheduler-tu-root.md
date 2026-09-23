---
id: BR-DECK-024
title: Descendant kế thừa scheduler từ root
status: active
summary: Scheduler thuộc root deck; mọi descendant kế thừa `scheduler_type`, `scheduler_version`, `generation` và không chọn riêng.
superseded_by:
---
## Rule

Scheduler thuộc về root deck. Mọi descendant ở mọi cấp MUST kế thừa `scheduler_type`, `scheduler_version` và `generation` từ root, và MUST NOT chọn riêng.

**Enforced by:** db + invariant Q9, Q10

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Ôn phiên trải trên nhiều deck con | Một tập action duy nhất, của root deck (BR-DECK-024, BR-STUDY-009) |
