---
id: BR-PROGRESS-018
title: Progress tự cập nhật
status: active
summary: Màn Progress tự cập nhật khi lịch sử đổi và tại nửa đêm địa phương.
superseded_by:
---
## Rule

Màn Progress MUST tự cập nhật khi lịch sử đổi (một answer mới ghi vào, một card hay deck bị xoá) và tại **local midnight**, không cần thao tác của người dùng. Bộ hẹn giờ midnight MUST là one-shot đặt theo `startOfTomorrow` của emission hiện tại, MUST bị huỷ khi controller dispose hoặc rebuild, MUST NOT lặp vô hạn khi ranh giới đã ở quá khứ tại lúc emission tới, và MUST resolve lại UTC offset ở **mỗi** lần đọc lại — resume, midnight hoặc Retry — chứ MUST NOT giữ offset mà màn hình mở lần đầu. Live refresh và midnight rollover MUST là chuyển tiếp giữa hai trạng thái loaded: khi đã có dữ liệu trên màn, cả hai MUST NOT hạ màn về loading.

**Enforced by:** UI
**Liên quan:** BR-PROGRESS-013

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
