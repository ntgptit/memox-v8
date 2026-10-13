---
id: BR-PROGRESS-018
title: Progress tự cập nhật
status: active
summary: Màn Progress tự cập nhật khi lịch sử đổi và tại nửa đêm địa phương.
superseded_by:
---
## Rule

Màn Progress MUST tự cập nhật khi lịch sử đổi (một answer mới ghi vào, một card hay deck bị xoá) và tại **local midnight**, không cần thao tác của người dùng. Lần đọc lại tại midnight MUST đến từ `DayClock.dayStarts()` qua `watchEachLocalDay` trong use case, không phải một timer trong UI: một timer mỗi listener, đặt theo nửa đêm kế tiếp của `now` lần đọc hiện tại, dựng lại từ nửa đêm vừa phát nên MUST NOT phát hai lần cho một ngày hay lặp khi ranh giới đã ở quá khứ, và MUST bị huỷ khi stream bị huỷ (provider dispose hoặc rebuild). Mỗi lần đọc lại — ngày mới hoặc Retry (`invalidate` provider) — MUST đọc lại `now` và resolve lại UTC offset từ đó, chứ MUST NOT giữ offset mà màn hình mở lần đầu; resume app không kích hoạt một lần đọc lại. Live refresh và midnight rollover MUST là chuyển tiếp giữa hai trạng thái loaded: khi đã có dữ liệu trên màn, cả hai MUST NOT hạ màn về loading.

**Enforced by:** rule + UI
**Liên quan:** BR-PROGRESS-013

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
