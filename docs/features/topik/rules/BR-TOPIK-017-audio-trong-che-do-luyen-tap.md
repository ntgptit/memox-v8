---
id: BR-TOPIK-017
title: Audio trong chế độ luyện tập
status: active
summary: Practice mode phát tự do trong đoạn audio của nhóm (phát, dừng, tua, nghe lại, tốc độ 0.75–1.5), không tự phát, không phát lại khi đổi câu trong cùng nhóm.
superseded_by:
---
## Rule

- Một nhóm MUST chỉ phát đoạn `[startMs, endMs)` của nó trong file của phần thi.
- Người dùng được phát, dừng, tua trong đoạn, nghe lại và chọn tốc độ 0.75, 1.0, 1.25 hoặc 1.5 (chủ dự án chốt 2026-10-15).
- Audio MUST NOT tự phát khi mở một nhóm.
- Chuyển giữa các câu của cùng một nhóm MUST giữ nguyên audio; sang nhóm khác thì audio của nhóm trước dừng.
- File phát lỗi: trình phát hiện lỗi kèm thử lại; lượt và đáp án không bị ảnh hưởng. File thiếu đã làm đề bị loại khi nạp (BR-TOPIK-008).

**Enforced by:** UI
**Liên quan:** BR-TOPIK-004, BR-TOPIK-008, BR-TOPIK-016, BR-TOPIK-032

## Lý do

Practice là để luyện nghe; người học cần nghe lại và chậm lại. Thi thật có luật phát riêng ở Exam mode (BR-TOPIK-032).

## Ví dụ

Nhóm [21～22] đang phát ở giây 30; chuyển từ câu 21 sang 22: audio vẫn phát tiếp từ giây 30.

## Edge case

Tua quá `endMs` thì dừng ở `endMs`; nghe lại bắt đầu từ `startMs`.
