---
id: BR-SRS-007
title: Thứ tự thủ công trong nhóm sibling
status: active
summary: Thứ tự thủ công của deck xác định trong nhóm sibling bằng `(sibling_position, id)`; reorder chỉ đổi `sibling_position`.
superseded_by:
---
## Rule

Thứ tự thủ công của deck MUST chỉ được xác định trong một nhóm sibling có cùng `parent_id`, bằng `(sibling_position, id)` để luôn deterministic. Reorder MUST đọc lại source và target active trong cùng transaction, và MUST từ chối nếu chúng không còn là sibling. Reorder MUST chỉ đổi `sibling_position` (và `updated_at` của các sibling đổi vị trí); MUST NOT đổi `parent_id`, `root_id`, scheduler/generation, card, study state hay descendant. Transaction thất bại MUST rollback toàn bộ thứ tự.

**Enforced by:** store + db

> ⚠️ OPEN QUESTION: rule này ràng buộc thứ tự thủ công của **deck** (`sibling_position`, dùng bởi UC-DECK-006) nhưng mang DOMAIN `SRS`. Theo quyết định giữ ID (Plan Q1) nó ở lại feature `srs`. (Plan OQ-16)

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
