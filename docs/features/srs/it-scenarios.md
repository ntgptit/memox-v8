# srs — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: Kịch bản IT — Phiên học thẻ mới

## IT-LEARN-010 — Chỉ hoàn tất chuỗi mới tạo lịch đầu tiên và khóa thuật toán xếp lịch

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`, đồng hồ kiểm thử ở `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới và dừng giữa chuỗi | Thẻ đã trả lời vẫn thuộc `New`; `Due` vẫn 0; thuật toán xếp lịch của bộ thẻ gốc chưa bị coi là đã có lượt ôn theo lịch |
| 2 | Hoàn tất toàn bộ giai đoạn mỗi thẻ tham gia | Mỗi thẻ rời `New` đúng một lần; phiên chuyển sang `completed` |
| 3 | Quay về bộ thẻ tại `T0` | `New 0`, `Due 0`; không cho ôn lại cùng ngày |
| 4 | Dịch đồng hồ kiểm thử tới đầu ngày học kế tiếp | Các thẻ xuất hiện trong `Due`; hạn neo ở 00:00 địa phương, không phải `T0 + 24 giờ` |
| 5 | Mở chỉnh thuật toán xếp lịch của bộ thẻ gốc | Thuật toán đã khóa và giải thích Đặt lại tiến độ học là đường đổi duy nhất |

## Nhóm: Kịch bản IT — Phiên ôn tập và thuật toán xếp lịch

## IT-REVIEW-005 — Lượt đầu là theo lịch, lượt lặp là học lại và không xếp lịch lần hai

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; chọn thẻ ở hộp 4 làm thẻ đầu của một phiên có chế độ chấm điểm độc lập.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở lượt đầu, trả lời sai | Thẻ được xếp về hộp 1, đến hạn đầu ngày kế tiếp; số lượt trả lời/sai tăng theo lượt `scheduled` |
| 2 | Khi thẻ quay lại, trả lời đúng | Đây là lượt `relearning`: thẻ rời hàng đợi nhưng lịch vẫn ở hộp 1/đầu ngày kế tiếp |
| 3 | Quay về bộ thẻ rồi khởi động lại | Lịch không nhảy thành hộp 2 vì lượt đúng thứ hai; kết quả đã được lưu ngay ở từng lượt |

## IT-REVIEW-006 — Eight Box đưa `Forgotten` và `Remembered` tới đúng hộp/khoảng cách

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2` có thẻ `Due` ở hộp 4 và hộp 8; đồng hồ kiểm thử ở `T0`; mỗi nhánh nạp lại bộ dữ liệu sạch.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ôn thẻ ở hộp 4 và tạo kết quả đúng | Thẻ sang hộp 5, hạn lúc 00:00 địa phương của ngày học `T0 + 16 ngày` |
| 2 | Ở một phiên độc lập, tạo kết quả sai cho thẻ ở hộp 4 | Thẻ về hộp 1, hạn lúc 00:00 địa phương của ngày học `T0 + 1 ngày` |
| 3 | Ôn thẻ ở hộp 8 với kết quả đúng | Thẻ vẫn ở hộp 8, hạn lúc 00:00 địa phương của ngày học `T0 + 128 ngày`; không biến mất như “tốt nghiệp” |

## IT-REVIEW-007 — SM-2 áp dụng `Again`/`Hard`/`Good`/`Easy` đúng thứ tự cập nhật

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-SM2-V2` có bốn bản sao độc lập với hệ số dễ 2.5, số lần lặp 2, khoảng cách 10 ngày; đồng hồ kiểm thử ở `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn `Again` cho bản 1 | Số lần lặp về 0, khoảng cách 1 ngày; hệ số dễ giảm nhưng không dưới 1.3; hạn ở đầu ngày thứ 1 |
| 2 | Chọn `Hard` cho bản 2 | Hệ số dễ mới 2.36 được dùng trước khi nhân; khoảng cách là 24 ngày, không phải 25 |
| 3 | Chọn `Good` cho bản 3 | Hệ số dễ giữ 2.5; khoảng cách là 25 ngày |
| 4 | Chọn `Easy` cho bản 4 | Hệ số dễ thành 2.6, khoảng cách thành 26 ngày; hạn neo ở 00:00 địa phương của ngày học `T0 + 26 ngày` |

## Nhóm: Kịch bản IT — Tiếp tục phiên, ngoại tuyến và lỗi

## IT-CONT-009 — Đặt lại khi phiên đang mở làm phiên mất hiệu lực với `scheduler_reset`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; UC-SRS-001 có giao diện hoàn chỉnh; đã tạo phiên `in_progress` bằng giao diện.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Từ cửa sổ khác, Đặt lại tiến độ học của bộ thẻ gốc và xác nhận | Đặt lại thành công cho toàn cây |
| 2 | Quay lại phiên cũ | Phiên bị đóng ở trạng thái `invalidated` vì đặt lại thuật toán xếp lịch, không tiếp tục được |
| 3 | Thử đánh giá thẻ đang mở | Không ghi lượt mới và không hồi sinh thế hệ dữ liệu cũ |
| 4 | Mở lịch sử/tiến độ khả dụng | Các lượt đã ghi trước khi đặt lại vẫn được giữ ở chu kỳ cũ |
