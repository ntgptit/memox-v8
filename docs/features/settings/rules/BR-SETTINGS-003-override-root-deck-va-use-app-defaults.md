---
id: BR-SETTINGS-003
title: Override của root deck và Use app defaults
status: active
summary: Root có `study_config` giữ override khi mặc định đổi; `Use app defaults` xoá override của root.
superseded_by:
---
## Rule

Root deck đang có `study_config` MUST tiếp tục dùng override đó sau khi mặc định toàn app đổi; root không override MUST đọc mặc định mới ngay ở lần giải kế tiếp. Hành động `Use app defaults` MUST xoá override của **root** trong một transaction và MUST NOT đụng `card_schedule`, `review_log`, `study_session`, `scheduler_*` hay `first_answered_at`. Hành động này MUST sống ở surface tuỳ chọn của deck, MUST NOT nằm trên màn hình Settings toàn app, và deck con MUST NOT sở hữu override để mà xoá.

**Enforced by:** store + UI
**Liên quan:** BR-STUDY-056, BR-DECK-025

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
