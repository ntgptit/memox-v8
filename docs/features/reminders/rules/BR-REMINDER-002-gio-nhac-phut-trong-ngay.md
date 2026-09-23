---
id: BR-REMINDER-002
title: Giờ nhắc là phút trong ngày
status: active
summary: Giờ nhắc lưu là phút trong ngày theo giờ địa phương, miền 0…1439, gợi ý mặc định 1200.
superseded_by:
---
## Rule

Giờ nhắc MUST lưu dưới dạng **phút trong ngày theo giờ địa phương**, miền hợp lệ `0…1439`, mặc định gợi ý `1200` (20:00). Giá trị ngoài miền MUST bị từ chối ở tầng nghiệp vụ bằng lý do có kiểu trước khi chạm database. Giờ nhắc MUST được diễn giải theo offset địa phương **tại thời điểm tính lịch**, MUST NOT quy đổi sang UTC rồi lưu — quy đổi lúc lưu làm giờ nhắc trôi đúng bằng lượng offset đổi khi người dùng qua múi giờ khác.

**Enforced by:** rule + db
**Liên quan:** BR-STUDY-074

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Đổi múi giờ sau khi đã bật nhắc | Đặt lại lịch theo giờ địa phương mới; giờ nhắc hiển thị không đổi (BR-REMINDER-002, BR-REMINDER-009) |
