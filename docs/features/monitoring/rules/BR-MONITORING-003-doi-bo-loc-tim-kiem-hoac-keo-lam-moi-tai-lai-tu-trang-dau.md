---
id: BR-MONITORING-003
title: Đổi bộ lọc, tìm kiếm hoặc kéo làm mới thì tải lại từ trang đầu
status: active
summary: Mọi thay đổi bộ lọc, tìm kiếm hay kéo làm mới tải lại từ trang đầu; câu trả lời của lần hỏi cũ không bao giờ ghi đè lần mới.
superseded_by:
---
## Rule

Mọi thay đổi bộ lọc, mọi thay đổi ô tìm kiếm, "Retry" sau lỗi và kéo xuống để làm mới trên tab Server MUST tải lại từ trang đầu với cùng bộ lọc. Một lần hỏi từ trang đầu MUST có số thế hệ; câu trả lời của một lần hỏi cũ hơn lần mới nhất MUST bị bỏ, để một phản hồi chậm không ghi đè một phản hồi mới. Một lần tìm kiếm đã gõ nhưng chưa hỏi (đang đợi 400 ms) MUST được mang theo vào mọi lần hỏi khác thay vì bị mất; kéo làm mới MUST hỏi nó ngay. Đặt một bộ lọc bằng đúng bộ lọc hiện tại MUST NOT hỏi lại.

Khi quay lại từ trang chi tiết, danh sách MUST giữ các trang đã tải và vị trí cuộn. Khi server từ chối vì không phải admin, ô tìm kiếm và các chip MUST biến mất cùng danh sách (BR-ACCOUNT-019); khi offline chúng MUST ở lại để một thay đổi là cách thử lại.

**Enforced by:** `lib/features/monitoring/presentation/controllers/monitoring_list_controller.dart` (`_generation`, `setFilter`, `refresh`, `retry`), `lib/features/monitoring/presentation/widgets/sections/monitoring_server_tab_widget.dart`
**Liên quan:** BR-MONITORING-004, BR-MONITORING-005, BR-ACCOUNT-019
**Nguồn:** [monitoring spec](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md) §3.5, §4.3; code như trên

## Lý do

Spec §3.5 (đã triển khai): "Pull to refresh reloads from the first page with the same filters. So does any filter or search change." Số thế hệ bảo đảm thứ tự câu trả lời không phụ thuộc thứ tự mạng.

## Ví dụ

Admin gõ `sync` rồi nhanh chóng đổi Status sang Fixed. Câu trả lời của lần tìm `sync` về sau cùng bị bỏ vì lần hỏi mới hơn đã được gửi.

## Edge case

- Trong lúc tải một trang kế, một lần hỏi từ trang đầu làm trang kế đó bị bỏ.
