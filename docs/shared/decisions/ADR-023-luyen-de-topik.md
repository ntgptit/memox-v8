---
id: ADR-023
title: Luyện đề TOPIK trong MemoX
status: active
superseded_by:
---
## Bối cảnh

MemoX là app thẻ từ vựng chỉ có văn bản: audio và hình ảnh nằm ngoài MVP
([`README.md`](../../README.md), mục "Explicitly out of MVP"), và app có đúng bốn
destination ([`navigation.md`](../ui/navigation.md), [ADR-009](ADR-009-chot-pham-vi-v8-0.md) #3).
Chủ dự án là người ôn thi tiếng Hàn và muốn luyện đề TOPIK thật các kỳ NIIED đã
công bố ngay trong app, với điểm và cấp tính đúng như kỳ thi thật. Đề thi cần audio
(phần 듣기), hình ảnh (câu tranh, biểu đồ, quảng cáo) và nội dung đóng gói sẵn — đều
là thứ app chưa có. Chủ dự án chốt các điểm dưới đây ngày 2026-10-15; thiết kế ở
[`superpowers/specs/2026-10-15-topik-practice-design.md`](../../superpowers/specs/2026-10-15-topik-practice-design.md).

## Quyết định

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | Phạm vi | Thêm feature `topik`: luyện đề PBT công khai của NIIED, phần 듣기 và 읽기. Audio và hình ảnh được phép **trong feature này**; thẻ vẫn chỉ có văn bản |
| 2 | Lối vào | Một thẻ lối vào trên màn Study home (màn 13). Bốn destination giữ nguyên; các màn TOPIK nằm dưới `/study/topik` |
| 3 | Nội dung | ~~Đề là dữ liệu: JSON, audio và ảnh đóng gói trong `assets/topik/`, kiểm bằng một bộ kiểm tra duy nhất ở app và ở gate, không nạp vào Drift. MVP đóng gói một kỳ; gói tải về là Phase B với spec riêng~~ Thay bởi [ADR-024](ADR-024-master-data-topik-tren-supabase-va-admin-web.md) (2026-10-16): Master Data trong Supabase, publish qua Admin Web, app cache document trong Drift |
| 4 | Nguồn | Chỉ đề NIIED đã công bố (`topik.go.kr`), ghi nguồn trên từng đề. Đề thuộc bản quyền NIIED, công bố cho mục đích học; MemoX là app cá nhân ([`PRODUCT.md`](../../../PRODUCT.md)). Không đề không rõ nguồn |
| 5 | Công cụ nội dung | Repo này giữ schema, bộ kiểm tra (Dart, bản tham chiếu), lint cho fixture và SQL của kho Master Data; ~~gói đã kiểm~~ gói nằm trong database ([ADR-024](ADR-024-master-data-topik-tren-supabase-va-admin-web.md)). Pipeline dựng nội dung từ PDF/MP3 nằm ở repo riêng `memox-topik-content`, kết quả nhập qua Admin Web |
| 6 | Dữ liệu người dùng | Bảng riêng của feature; lượt đã nộp đồng bộ như bản ghi bất biến, lượt đang dở gắn với máy (giống [ADR-013](ADR-013-dong-bo-voi-server-offline-first.md) #7, #10); dữ liệu theo tài khoản và bị xoá khi đổi tài khoản |
| 7 | Không quảng cáo | Không bao giờ có quảng cáo |

## Hệ quả

- `README.md` và `PRODUCT.md` ghi ngoại lệ audio và hình ảnh cho feature `topik`.
- Thêm một dependency phát audio vào `pubspec.yaml`, chủ dự án duyệt trong
  engineering design, kèm file "door" duy nhất import nó (như `flutter_tts`).
- Schema Drift lên v17 với hai bảng mới; Supabase thêm một loại entity đồng bộ.
- Màn 13 thêm một vùng; các màn 34–39 có detail file riêng.
- Phương án bị loại:
  - **tab thứ năm:** đổi điều hướng toàn app cho một tính năng;
  - **nạp đề vào Drift:** mỗi kỳ mới cần migration, nội dung tồn tại hai nơi;
  - **đồng bộ cả lượt đang dở:** đặt lại bài toán hai máy cùng làm một phiên.
