# tags — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: IT scenarios — Tìm kiếm, tổ chức và tiến độ card

## IT-ORG-007 — Thêm và tái sử dụng tag không phân biệt hoa thường

> **Tách thành** — `IT-ORG-007` (`HOST-WIDGET`) · `IT-ORG-007F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có `C-001` và `C-002`, chưa có tag.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-001`, thêm tag `IELTS` | Tag xuất hiện dạng chip trong editor |
| 2 | Quay về list | Row `C-001` hiện chip `IELTS` |
| 3 | Mở `C-002`, thêm tag `ielts` | Card nhận tag tương ứng; hệ thống không tạo hai tag nghiệp vụ khác nhau chỉ vì hoa/thường |
| 4 | Thêm lại `IELTS` trên cùng card | Không xuất hiện chip trùng |

## IT-ORG-008 — Xoá tag khỏi card không xoá nội dung card

- **Ưu tiên:** P1
- **Tiền điều kiện:** `C-001` có tag `IELTS` và `Writing`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-001`, xoá chip `IELTS` | Chip `IELTS` biến mất; `Writing` còn |
| 2 | Quay về list | Row chỉ còn chip `Writing`; front/back và state không đổi |
| 3 | Restart app | Kết quả xoá tag được giữ |

## IT-ORG-009 — Validation tên tag và giới hạn 10 tag

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có một card đang mở ở edit mode.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Thử thêm tag rỗng/chỉ khoảng trắng | Hiện lỗi; không tạo chip |
| 2 | Thử thêm tag dài hơn 50 ký tự | Không tạo tag: ký tự dư bị chặn, hoặc lỗi inline giữ form mở cho tới khi tên còn tối đa 50 ký tự |
| 3 | Thêm lần lượt 10 tag hợp lệ, khác nhau | Hiện đúng 10 chip và counter 10/10 |
| 4 | Thử thêm tag thứ 11 | Bị từ chối với thông báo rõ; 10 tag cũ còn nguyên |
