---
id: BR-TOPIK-028
title: Server chỉ kiểm tính toàn vẹn của lượt
status: active
summary: Server từ chối lượt không toàn vẹn nhưng không chấm điểm; luật chấm chỉ sống trong app.
superseded_by:
---
## Rule

Server MUST từ chối một lượt khi `status` khác `completed`, `score` khác tổng `points_earned` hay vượt `max_score`, các số đếm không khớp danh sách đáp án, chỉ số lựa chọn ngoài 1–4, hoặc số câu trùng. Server MUST NOT chấm lại hay biết đáp án ([ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

**Enforced by:** db
**Liên quan:** BR-TOPIK-013, BR-TOPIK-026

## Lý do

Luật nghiệp vụ chỉ sống trong app (ADR-015); server giữ cho dữ liệu chung không tự mâu thuẫn.

## Ví dụ

Payload có `score 90` nhưng tổng `points_earned` là 88: server từ chối.

## Edge case

Không áp dụng
