---
id: ADR-004
title: Khoá scheduler và reset learning progress
status: active
superseded_by:
---
Quyết định đã chốt ngày 2026-07-28 (trước migrate nằm ở `product/product.md`, mục "Quyết định đã chốt").

## Quyết định

**Scheduler bị khoá khi thẻ đầu tiên học xong chuỗi học mới** (BR-SRS-003). Trước đó đổi tự do; sau đó muốn
đổi phải **Reset learning progress**. Lý do: đổi thuật toán giữa chừng đặt ra
những câu hỏi không có câu trả lời trung thực — box 5 tương ứng ease factor nào,
history theo luật cũ còn giá trị gì. Mọi ánh xạ đều là bịa đặt. Khoá-và-reset
thừa nhận điều đó thẳng thắn và để người dùng biết rõ mình đánh đổi cái gì.

**Reset giữ nguyên** deck, sub-deck, flashcard, media, tag và nội dung; **xoá**
lịch ôn, ngày đến hạn, box/ease factor/interval, trạng thái thành thạo và phiên
đang dở. Study answers cũ được giữ để tham khảo nhưng không dùng cho chu kỳ mới.
Mỗi deck có `generation` tăng sau mỗi lần reset, và kết quả từ session
thuộc generation cũ bị từ chối.

Luật: BR-SRS-003, BR-SRS-020…BR-SRS-030; luồng UC-SRS-001.
