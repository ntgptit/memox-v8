---
id: BR-STUDY-059
title: Mode chấm điểm chạy theo round
status: active
summary: Bốn mode chấm điểm chạy theo round; round sau chỉ gồm thẻ không đạt; `self_assess` không dùng round.
superseded_by:
---
## Rule

Bốn mode chấm điểm (`match`, `guess`, `recall`, `fill`) MUST chạy theo **round**, ở cả hai loại phiên: round 1 gồm toàn bộ thẻ đủ dữ liệu; mỗi round sau chỉ gồm thẻ không đạt ở round vừa xong. `self_assess` MUST NOT dùng round — nó lặp theo BR-STUDY-005.

**Enforced by:** store
**Liên quan:** BR-STUDY-005, BR-STUDY-060

## Lý do

**`self_assess` không bao giờ dùng round.** Nó lặp bằng BR-STUDY-005 ở **mọi loại phiên**:
thẻ quay lại sau ≥ 3 thẻ khác, trần 3 lượt rồi rời hàng đợi kèm cờ (BR-STUDY-073). Bốn
mode chấm điểm dùng round, không trần (BR-STUDY-069). Hai cơ chế, ranh giới là **mode**
chứ không phải loại phiên — vì `self_assess` không có "bàn" để hết, còn bốn mode
kia thì có.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
