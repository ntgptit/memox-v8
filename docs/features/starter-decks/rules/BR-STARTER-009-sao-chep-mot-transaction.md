---
id: BR-STARTER-009
title: Sao chép trong một transaction
status: active
summary: Toàn bộ việc sao chép nằm trong một transaction.
superseded_by:
---
## Rule

Toàn bộ việc sao chép MUST nằm trong một transaction.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Bộ nhớ đầy khi sao chép starter deck | Transaction rollback (BR-STARTER-009); không để lại deck nửa vời |
