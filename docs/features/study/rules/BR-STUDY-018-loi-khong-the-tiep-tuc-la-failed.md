---
id: BR-STUDY-018
title: Lỗi không thể tiếp tục là failed
status: active
summary: Lỗi không thể tiếp tục cho `failed`, `end_reason = persistence_error`.
superseded_by:
---
## Rule

Lỗi không thể tiếp tục MUST cho `failed`, `end_reason = persistence_error`.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Session lỗi ghi không thể tiếp tục | Session → `failed`/`persistence_error`; các lượt đã ghi vẫn giữ (BR-STUDY-018, BR-STUDY-019) |
