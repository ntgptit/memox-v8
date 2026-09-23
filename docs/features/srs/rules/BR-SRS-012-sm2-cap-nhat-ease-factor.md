---
id: BR-SRS-012
title: sm2: cập nhật ease factor
status: active
summary: `sm2`: công thức ease factor, sàn 1.3, cập nhật ở mọi lượt `scheduled`.
superseded_by:
---
## Rule

```
ease_factor = max(1.3, ease_factor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
```

Cập nhật ở mọi lượt `scheduled`, kể cả khi `q < 3`. Sàn 1.3 là bắt buộc: không có
nó, một card liên tục bị quên sẽ có ease factor tiến về 0 và interval kẹt ở 1
ngày vĩnh viễn.

**Enforced by:** rule

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| SM-2, card bị quên liên tục | `ease_factor` chạm sàn 1.3 và dừng ở đó (BR-SRS-012) |
