---
id: BR-TOPIK-025
title: Định dạng thời lượng và điểm
status: active
summary: Thời lượng hiện đến giây qua một formatter dùng chung; điểm luôn hiện đủ `điểm / tối đa`.
superseded_by:
---
## Rule

Thời lượng MUST hiện đến giây, không bao giờ mili giây, qua formatter dùng chung trong `lib/core/text/` (chủ dự án chốt 2026-10-15): `42s`, `3m 05s`, `1h 02m 11s`, theo ngôn ngữ giao diện. Điểm MUST hiện đủ `score / max_score` (ví dụ `96 / 100`), không bị cắt.

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-015, BR-TOPIK-020, BR-TOPIK-023

## Lý do

App tham khảo hiện `57mn 19s 43ms` và `96/10` vì tràn chữ; một formatter chung và bố cục chịu được 100/100 loại cả hai lỗi.

## Ví dụ

3 731 000 ms hiện `1h 02m 11s`.

## Edge case

0 ms hiện `0s`; 59 999 ms hiện `59s`.
