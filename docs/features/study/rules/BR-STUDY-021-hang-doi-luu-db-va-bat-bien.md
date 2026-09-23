---
id: BR-STUDY-021
title: Hàng đợi lưu DB và bất biến
status: active
summary: Hàng đợi được lưu trong database và bất biến trong suốt phiên.
superseded_by:
---
## Rule

Hàng đợi MUST được lưu trong database và MUST bất biến trong suốt phiên: thay đổi deck sau khi phiên mở MUST NOT đổi hàng đợi đang chạy.

**Enforced by:** db
**Liên quan:** BR-STUDY-003, BR-STUDY-022

## Lý do

BR-STUDY-021 thay câu cũ trong `data-model.md` rằng hàng đợi là trạng thái tạm của
controller. Lý do đổi: hàng đợi mang **luật**, không chỉ mang thứ tự — thứ tự
BR-STUDY-002, lượt quay lại BR-STUDY-005, trần BR-STUDY-073 — và một cấu trúc mang luật nằm trong
UI là chỗ luật đi ra khỏi tầm với của mọi phép kiểm. Đặt nó vào
database biến "snapshot bất biến" từ một lời hứa thành một ràng buộc, và cho phép
BR-STUDY-072 tồn tại: một phiên sống sót qua việc app bị hệ điều hành thu hồi.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
