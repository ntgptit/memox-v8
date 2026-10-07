---
id: BR-TRANSFER-006
title: Nội dung import là dữ liệu riêng tư
status: active
summary: File import xử lý trong bộ nhớ ứng dụng, chỉ nhận UTF-8, không đoán encoding.
superseded_by:
---
## Rule

Nội dung import thuộc dữ liệu riêng tư của [BR-CORE-001](../../../shared/rules/BR-CORE-001-noi-dung-nguoi-dung-la-du-lieu-rieng-tu.md). Log thì theo [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) (2026-09-29, thay vế "MUST NOT log" cũ). File MUST xử lý trong bộ nhớ ứng dụng, MUST NOT để lại bản sao ở thư mục dùng chung. V1 chỉ hỗ trợ UTF-8 và UTF-8 BOM; encoding khác MUST báo lỗi có hướng dẫn, MUST NOT đoán mò.

**Enforced by:** store + UI
**Liên quan:** BR-CORE-001, ADR-018

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
