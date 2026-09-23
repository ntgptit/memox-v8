---
id: BR-CARD-004
title: Tạo card tạo study state
status: active
summary: Tạo card đồng thời tạo study state theo scheduler và `generation` của root, `due_at = NULL`.
superseded_by:
---
## Rule

Tạo card MUST đồng thời tạo study state theo scheduler của root deck, với `generation` hiện tại của root và `due_at = NULL`.

Giá trị khởi tạo của study state theo scheduler:

| Scheduler | Khởi tạo |
|---|---|
| `eight_box` | `current_box = 1`; cột SM-2 để NULL |
| `sm2` | `ease_factor = 2.5`, `interval_days = 0`, `repetitions = 0`; `current_box` NULL |

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
