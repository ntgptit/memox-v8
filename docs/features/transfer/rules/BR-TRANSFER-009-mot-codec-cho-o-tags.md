---
id: BR-TRANSFER-009
title: Một codec cho ô tags
status: active
summary: Ô `tags` đi qua đúng một codec dùng chung cho Import và Export.
superseded_by:
---
## Rule

Ô `tags` MUST đi qua đúng **một** codec dùng chung cho cả Import và Export; MUST NOT có bản thứ hai trong encoder, decoder hay preview. Encode: các tag nối bằng `;` (BR-TRANSFER-002); `;` bên trong một tag MUST escape thành `\;` và `\` MUST escape thành `\\`. Decode: backslash MUST chỉ được coi là escape khi đứng ngay trước `;` hoặc `\`; backslash trước ký tự khác và backslash ở cuối ô MUST giữ nguyên verbatim, vì nguồn legacy chưa từng escape. Round-trip export → import MUST giữ nguyên cả spelling lẫn tập tag.

**Enforced by:** rule
**Liên quan:** BR-TAG-001, BR-TRANSFER-002

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Tag chứa `;` hoặc `\` | Escape khi ghi, khôi phục nguyên văn khi import lại (BR-TRANSFER-009) |
