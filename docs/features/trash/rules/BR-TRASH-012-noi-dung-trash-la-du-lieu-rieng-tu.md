---
id: BR-TRASH-012
title: Nội dung Trash là dữ liệu riêng tư
status: active
summary: Nội dung trong Trash là dữ liệu riêng tư; đường dẫn gốc chỉ là thông tin.
superseded_by:
---
## Rule

Nội dung trong Trash thuộc dữ liệu riêng tư của [BR-CORE-001](../../../shared/rules/BR-CORE-001-noi-dung-nguoi-dung-la-du-lieu-rieng-tu.md). Log thì theo [ADR-018](../../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) (2026-09-29, thay vế "MUST NOT log nội dung card" cũ). Trash MUST hiển thị đường dẫn gốc của item **chỉ như thông tin**, MUST NOT trình bày nó như nơi item sẽ được khôi phục về.

**Enforced by:** store + UI
**Liên quan:** BR-CORE-001, ADR-018

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
