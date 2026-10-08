---
id: BR-TRANSFER-001
title: Điều kiện deck đích của import
status: active
summary: Nguồn phẳng ghi vào deck card/unset hoặc một deck con mặc định; nguồn có dòng sao cần deck đích chứa được deck con.
superseded_by:
---
## Rule

Deck đích của một lần import MUST là deck người dùng mở import (spec 2026-10-08 §4.2). Nguồn **phẳng** (BR-TRANSFER-015) vào deck loại `card` hoặc sub-deck `unset` ghi card thẳng vào deck đích như trước. Nguồn phẳng vào root hoặc deck loại `deck` ghi vào **một** deck con mặc định. Nguồn **có dòng sao** tạo deck con của deck đích, nên deck đích MUST chứa được deck con: deck loại `card` MUST bị từ chối với lý do có kiểu (mở import từ deck cha), và deck ở cấp 10 MUST bị từ chối theo BR-DECK-001. Mọi điều kiện này MUST được kiểm tra lại **bên trong** transaction commit — deck có thể đã đổi loại hoặc biến mất giữa lúc preview và lúc ghi — kể cả từng deck có sẵn được chọn "Thêm vào có sẵn": deck đó MUST vẫn là deck con trực tiếp còn sống của deck đích và vẫn là `card` hoặc `unset`, nếu không cả lần import MUST bị từ chối và không ghi gì.

**Enforced by:** store
**Liên quan:** BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TRANSFER-015, BR-DECK-001

## Lý do

Nửa nhập của Card Transfer.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Import vào root deck hoặc deck đang giữ deck con | Chặn trong transaction, lỗi có kiểu (BR-TRANSFER-001) |
| File có dòng sao, mở từ deck loại `card` | Preview từ chối, hướng dẫn import từ deck cha (BR-TRANSFER-001) |
| Deck có sẵn được chọn "Thêm vào" bị xoá hoặc chuyển trước lúc ghi | Cả commit bị từ chối, không ghi gì (BR-TRANSFER-001) |
