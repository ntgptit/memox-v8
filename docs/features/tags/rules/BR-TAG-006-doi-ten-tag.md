---
id: BR-TAG-006
title: Đổi tên tag
status: active
summary: Đổi tên tag qua đúng validation của BR-TAG-001; tên chưa thuộc tag khác thì giữ nguyên tag.
superseded_by:
---
## Rule

Đổi tên tag MUST đi qua đúng validation của BR-TAG-001 — trim, tối đa 50 ký tự, không ký tự điều khiển, và fold bằng chính hàm mà việc tạo tag dùng. Nếu tên đã fold **chưa** thuộc về tag nào khác, đổi tên MUST giữ nguyên `id` của tag và toàn bộ quan hệ `card_tags` của nó; chỉ `name` và `name_folded` được ghi. Đổi tên chỉ khác cách viết hoa của chính nó (`noun` → `Noun`) MUST được chấp nhận và MUST NOT bị coi là trùng với chính mình.

**Enforced by:** rule + store
**Liên quan:** BR-TAG-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
