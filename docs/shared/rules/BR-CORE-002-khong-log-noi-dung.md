---
id: BR-CORE-002
title: Không log nội dung
status: deprecated
summary: Không log nội dung flashcard hoặc ghi chú ở bất kỳ log level nào; log ID thì được.
superseded_by: ADR-018
---
## Rule

> **Hết hiệu lực từ 2026-09-29.** Chủ dự án quyết định log mọi thứ, kể cả nội dung
> thẻ, vào bảng chỉ admin đọc được: xem
> [ADR-018](../decisions/ADR-018-log-tap-trung-va-monitoring.md). Nội dung dưới đây
> giữ lại làm lịch sử.

MUST NOT log nội dung flashcard hoặc ghi chú ở bất kỳ log level nào. Log ID thì MAY.

**Enforced by:** logging

## Lý do

ID cũ: `BR-PRIVACY-002` (đổi thành BR-CORE-002 khi migrate, Plan Q2). Lý do của nhóm rule riêng tư nằm ở [ADR-002](../decisions/ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md).

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
