---
id: BR-SEARCH-008
title: Kết quả chỉ đọc và tự cập nhật
status: active
summary: Kết quả chỉ đọc, không mở phiên học; đổi tên, di chuyển, xoá tự cập nhật kết quả.
superseded_by:
---
## Rule

Kết quả MUST là chỉ-đọc: MUST NOT ghi bất cứ gì và MUST NOT mở phiên học. Đổi tên deck tổ tiên, di chuyển card hoặc deck, đổi tên tag và xoá MUST cập nhật kết quả cùng đường dẫn đang hiển thị mà không cần thao tác thủ công. Mở một kết quả deck MUST đi tới màn deck tương ứng; mở một kết quả card MUST đi tới màn chi tiết card ở chế độ đọc và MUST NOT đi tới màn sửa card. Khi route chi tiết card chưa tồn tại, hệ thống MUST khai báo đích đến bằng một kiểu dữ liệu và nói rõ là chưa mở được, MUST NOT dựng màn chi tiết thứ hai và MUST NOT âm thầm thay bằng màn khác.

**Enforced by:** store + UI
**Liên quan:** BR-DECK-009

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
