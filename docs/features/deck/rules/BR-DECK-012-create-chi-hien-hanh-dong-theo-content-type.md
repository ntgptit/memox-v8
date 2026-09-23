---
id: BR-DECK-012
title: Create chỉ hiện hành động theo content_type
status: active
summary: Sau khi `content_type` được xác lập, nút Create chỉ hiển thị hành động tương ứng.
superseded_by:
---
## Rule

Sau khi `content_type` được xác lập, nút Create MUST chỉ hiển thị hành động tương ứng.

**Enforced by:** UI

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Bấm Create ở sub-deck `content_type = card` | Chỉ có Create card (BR-DECK-012) |
