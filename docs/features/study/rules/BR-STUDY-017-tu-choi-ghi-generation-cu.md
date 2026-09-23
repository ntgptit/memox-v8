---
id: BR-STUDY-017
title: Từ chối ghi của generation cũ
status: active
summary: Session thuộc generation cũ bị từ chối ghi và chuyển `invalidated`/`stale_generation`.
superseded_by:
---
## Rule

Session thuộc generation cũ cố ghi lượt học MUST bị từ chối ghi, và MUST chuyển `invalidated`, `end_reason = stale_generation`.

**Enforced by:** store

## Lý do

BR-STUDY-017 chống một tình huống thật và dễ bỏ sót: người dùng mở phiên ôn, để đó, vào
Settings reset deck, rồi quay lại phiên cũ và bấm đánh giá. Không kiểm tra
generation thì kết quả đó ghi đè trạng thái vừa được làm mới.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Mở phiên → reset ở màn khác → quay lại bấm đánh giá | Từ chối ghi; session → `invalidated`/`stale_generation` (BR-STUDY-017) |
