---
id: BR-CORE-003
title: Media trong thư mục riêng của ứng dụng
status: active
summary: Media lưu trong thư mục riêng của ứng dụng.
superseded_by:
---
## Rule

Media MUST lưu trong thư mục riêng của ứng dụng.

**Enforced by:** store

> ⚠️ OPEN QUESTION: BR-CARD-019 và UC-CARD-002 E1 trích rule này (khi còn là `BR-PRIVACY-003`) cho ý "không lộ id, đường dẫn hay SQL", trong khi rule chỉ nói về nơi lưu media. (Plan OQ-5)

## Lý do

ID cũ: `BR-PRIVACY-003` (đổi thành BR-CORE-003 khi migrate, Plan Q2). Lý do của nhóm rule riêng tư nằm ở [ADR-002](../decisions/ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md).

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
