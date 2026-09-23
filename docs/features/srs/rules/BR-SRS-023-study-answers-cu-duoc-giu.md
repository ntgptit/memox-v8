---
id: BR-SRS-023
title: Study answers cũ được giữ
status: active
summary: Study answers cũ được giữ với generation cũ và không dùng cho chu kỳ mới.
superseded_by:
---
## Rule

Study answers cũ MUST được giữ lại, mang generation cũ, và MUST NOT được dùng cho chu kỳ mới.

**Enforced by:** store

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Reset learning progress rồi học tiếp | Cả hai generation đều được đếm — reset không làm việc đã học biến mất (BR-SRS-023, BR-PROGRESS-017) |
