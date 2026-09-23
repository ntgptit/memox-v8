---
id: BR-TRANSFER-014
title: File export là dữ liệu riêng tư
status: active
summary: File export là dữ liệu riêng tư, chỉ tạo khi người dùng chủ động yêu cầu.
superseded_by:
---
## Rule

File export là dữ liệu riêng tư cùng mức nội dung card (BR-PRIVACY-001, BR-PRIVACY-002) và MUST chỉ được tạo khi người dùng chủ động yêu cầu (BR-PRIVACY-004). Ứng dụng MUST NOT xin quyền truy cập bộ nhớ diện rộng, và MUST NOT ghi artifact vào thư mục dùng chung trước một hành động tường minh của người dùng; bản tạm MUST nằm trong vùng riêng của ứng dụng và là transient. Bàn giao file MUST đi qua share sheet của hệ điều hành. Người dùng đóng share sheet MUST được hiểu là **cancel**, MUST NOT báo lỗi. UI MUST NOT nói file đã được lưu khi hệ điều hành không xác nhận điều đó — copy trung thực nói "đã bàn giao cho hệ thống", không nói "đã lưu".

**Enforced by:** store + UI
**Liên quan:** BR-PRIVACY-001, BR-PRIVACY-002, BR-PRIVACY-004, BR-TRANSFER-006

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Người dùng đóng share sheet | Coi là cancel; không toast lỗi, không nói đã lưu (BR-TRANSFER-014) |
