---
id: BR-SETTINGS-007
title: Mỗi lần lưu một transaction
status: active
summary: Mỗi lần lưu một tuỳ chọn là một transaction độc lập; lỗi là `Failure` có kiểu.
superseded_by:
---
## Rule

Mỗi lần lưu một tuỳ chọn MUST là **một** transaction và MUST là một submit độc lập: hỏng khi lưu theme MUST NOT ghi ngôn ngữ hay mặc định học. Lỗi MUST đi ra ngoài dưới dạng `Failure` có kiểu, MUST NOT là exception của tầng dữ liệu và MUST NOT lộ SQL, đường dẫn hay stack trace. Lần gửi thứ hai khi lần đầu chưa xong MUST bị bỏ qua. Lưu thất bại MUST giữ nguyên draft người dùng đang nhập và MUST tiếp tục hiển thị **giá trị đã persisted** cho các control còn lại; MUST NOT vẽ một giá trị chưa lưu như thể đã lưu.

Mỗi lần lưu MUST chỉ ghi cột của tuỳ chọn mình lưu: lưu thứ tự thẻ mới MUST NOT ghi lại giới hạn thẻ từ ảnh chụp của form (và ngược lại), để một giá trị sync vừa kéo về giữa lúc form đọc và lúc lưu không bị ghi đè (DEV-217).

**Enforced by:** store + UI
**Liên quan:** BR-SETTINGS-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
