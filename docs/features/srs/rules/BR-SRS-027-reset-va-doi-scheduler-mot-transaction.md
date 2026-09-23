---
id: BR-SRS-027
title: Reset và đổi scheduler trong một transaction
status: active
summary: Reset và đổi scheduler chạy trong một Drift transaction duy nhất.
superseded_by:
---
## Rule

Reset và đổi scheduler MUST chạy trong một Drift transaction duy nhất.

**Enforced by:** store

## Lý do

BR-SRS-027 quan trọng vì nửa vời ở đây nghĩa là một cây deck có card thuộc hai
generation, hoặc scheduler mới với card state theo luật cũ. Cả hai là dữ liệu
hỏng không tự phục hồi, tệ hơn nhiều so với reset thất bại sạch sẽ.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| App bị kill giữa lúc reset | Transaction rollback; giữ nguyên generation và state cũ (BR-SRS-027) |
