---
id: BR-SRS-029
title: Một generation cho toàn cây
status: active
summary: Bất biến: mọi card state trong một cây thuộc cùng một generation.
superseded_by:
---
## Rule

Bất biến 2: toàn bộ card state trong một cây MUST thuộc cùng một generation.

**Enforced by:** invariant Q9

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Pull từ máy khác: pull bỏ qua `card_schedule` đang chờ đẩy ở máy này, nên một Reset hay đổi scheduler kéo về có thể đưa root lên generation mới mà hàng đó vẫn ở generation cũ. Cuối pull, `CardScheduleSyncDao.afterPull` seed lại mọi hàng lệch root (`generation` hoặc `scheduler_type`) về trạng thái ban đầu ở generation của root, như máy kia đã làm, và xếp vào outbox (DEV-224).
