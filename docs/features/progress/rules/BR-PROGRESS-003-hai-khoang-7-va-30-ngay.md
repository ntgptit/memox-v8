---
id: BR-PROGRESS-003
title: Hai khoảng 7 và 30 ngày
status: active
summary: v1 có đúng hai khoảng 7 và 30 ngày, gồm trọn các ngày địa phương kết thúc bằng hôm nay.
superseded_by:
---
## Rule

v1 MUST có đúng hai khoảng — **7 ngày** và **30 ngày** — và MUST NOT có khoảng thứ ba hay date picker tự do. Mỗi khoảng MUST gồm trọn các ngày địa phương **kết thúc bằng hôm nay**: 7 ngày là hôm nay cộng sáu ngày trước đó. Biên MUST dẫn xuất từ `clockProvider` và offset múi giờ do composition root cấp, MUST NOT đọc đồng hồ hay múi giờ trong SQL hay trong tầng nghiệp vụ. Hai khoảng MUST đến từ **một** lần đọc, nên đổi khoảng trên màn hình MUST NOT mở lại query và MUST NOT hiện trạng thái loading. Snapshot MUST mang theo thời điểm nó hết hạn — nửa đêm địa phương kế tiếp — vì mọi số của nó đổi tại đó mà không có write nào trong database.

**Enforced by:** rule + store
**Liên quan:** BR-STUDY-074

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
