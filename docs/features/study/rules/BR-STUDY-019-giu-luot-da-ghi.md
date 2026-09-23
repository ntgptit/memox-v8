---
id: BR-STUDY-019
title: Giữ các lượt đã ghi
status: active
summary: Lượt đã ghi trước khi session kết thúc bất thường được giữ ở mọi trạng thái kết thúc.
superseded_by:
---
## Rule

Các lượt học đã ghi thành công trước khi session kết thúc bất thường MUST được giữ, ở mọi trạng thái kết thúc.

**Enforced by:** store

## Lý do

BR-STUDY-019 là điều phân biệt "session hỏng" với "mất tiến độ". Session chuyển sang
`failed` hay `invalidated` không được kéo theo việc xoá các lượt đã ghi xong —
người dùng đã bỏ công ôn 20 card thì 20 lượt đó là thật.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
