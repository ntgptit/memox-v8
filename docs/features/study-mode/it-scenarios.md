# study-mode — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: Kịch bản IT — Phiên học thẻ mới

## IT-LEARN-003 — `Browse` chỉ làm quen, hiện cả hai mặt và không chấm điểm

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; chọn Học mới để vào Browse.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát thẻ | Mặt trước và mặt sau cùng hiện, có nhãn cho hai mặt; không cần lật |
| 2 | Kiểm tra vùng hành động | Chỉ có hành động đi tiếp; không có hành động của thuật toán xếp lịch và không có đúng/sai |
| 3 | Đi qua một thẻ, đóng hẳn ứng dụng rồi chọn Tiếp tục | Thẻ đã xem ở `Browse` không quay lại; ứng dụng tiếp tục đúng điểm dừng |
| 4 | Quan sát trạng thái và hạn của thẻ trước khi hết chuỗi | Thẻ vẫn thuộc `New`, chưa có lịch ôn |

## IT-LEARN-006 — `Guess` bị bỏ qua khi tập phiên không đủ năm nghĩa khác nhau

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-4`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Hoàn tất `Match` | Hệ thống đánh giá điều kiện `Guess` trên cả tập thẻ của phiên |
| 2 | Quan sát giai đoạn kế | Không hiển thị câu hỏi `Guess` thiếu lựa chọn và không báo lỗi |
| 3 | Tiếp tục | Chuyển tới `Recall`; các thẻ vẫn còn trong chuỗi học |

## IT-LEARN-007 — `Match` bị bỏ qua khi chỉ có một cặp

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-1`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đi hết `Browse` | `Match` không mở bàn một cặp vì đáp án sẽ hiển nhiên |
| 2 | Quan sát chuỗi tiếp theo | `Guess` cũng bị bỏ qua do thiếu dữ liệu; `Recall` vẫn chạy cho thẻ |
| 3 | Hoàn tất các giai đoạn thẻ tham gia | Thẻ vẫn được đánh dấu học xong; giai đoạn bị bỏ qua không giữ thẻ lại |

## Nhóm: Kịch bản IT — Phiên ôn tập và thuật toán xếp lịch

## IT-REVIEW-002 — Phiên ôn tập Eight Box chạy đúng một chế độ đã chọn

> **Tách thành** — `IT-REVIEW-002` (`HOST-FLOW`) · `IT-REVIEW-002W` (`HOST-WIDGET`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập rồi `Match` | Phiên mở tại `Match` |
| 2 | Hoàn tất hàng đợi/vòng | Không tự chuyển sang `Guess`, `Recall` hoặc `Fill` |
| 3 | Quan sát tổng kết | Phiên chuyển sang `completed` ngay khi `Match` hết; nhãn chế độ không đổi trong phiên |

## IT-REVIEW-010 — Số lượng và hàng đợi của từng chế độ không dùng chung một con số giả

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi số lượng `Match`/`Guess`/`Recall`/`Fill` | Lần lượt 5/5/5/3 |
| 2 | Chọn `Fill` | Hàng đợi có đúng ba thẻ có câu ví dụ |
| 3 | Thoát và chọn `Match` trong phiên mới | Hàng đợi có đủ năm thẻ, không bị giới hạn bởi số lượng 3 của `Fill` |
| 4 | So tổng kết hai phiên | Mỗi tổng kết dùng mẫu số của chính chế độ/phiên, không dùng số lượng chung |

## Nhóm: Kịch bản IT — Sáu chế độ học

## IT-MODE-002 — `Browse` hiện hai mặt cùng lúc, đi tiếp và xem lại bằng vuốt

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; chọn Học mới để vào Browse.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát thẻ | Mặt trước và mặt sau cùng hiện trong **một** thẻ, phân tách bằng đường kẻ và nhãn Mặt trước/Mặt sau |
| 2 | Quan sát nhãn chế độ | Nhãn là `Browse`, không phải `Review` |
| 3 | Kiểm tra hành động | Không có lật thẻ, hành động xếp lịch, nút Tiếp tục/Quay lại nhìn thấy được, biểu tượng loa hoặc biểu tượng sửa thẻ |
| 4 | Vuốt sang trái | Tiến đúng một điểm dừng; không hiện phán quyết đúng/sai |
| 5 | Vuốt sang phải | Hiện lại thẻ đã qua trong cùng round; điểm dừng và tiến độ **không** đổi |
| 6 | Vuốt trái trở lại thẻ đang sống rồi vuốt trái lần nữa | Chỉ tiến một điểm dừng; thẻ đã xem lại **không** bị ghi lượt thứ hai |
| 7 | Duyệt bằng trình đọc màn hình | Có custom action tương đương cho Tiếp tục và Thẻ trước; Thẻ trước chỉ xuất hiện khi có chỗ để lùi |

**Bước 3 và 4 từng nói ngược với BR-STUDY-048.** Bảng cũ ghi "không có vuốt lùi" và
"chạm Tiếp tục", trong khi BR-STUDY-048 bắt buộc `browse` — và chỉ `browse` — cho xem
lại thẻ đã qua bằng vuốt hoặc một control tương đương, còn BR-MODE-005 thì không cho
mode này có bất kỳ hành động chấm điểm nào. Cái không tồn tại là **nút** Tiếp
tục, không phải thao tác đi tiếp.

## IT-MODE-004 — `Match` quy kết lượt cho thuật ngữ được chọn trước và giữ thẻ sai sang vòng sau

> **Tách thành** — `IT-MODE-004` (`HOST-WIDGET`) · `IT-MODE-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới vòng 1 của `Match`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn thuật ngữ của `ST-01`, rồi chọn nhầm ý nghĩa của `ST-02` | Kết quả sai thuộc `ST-01`; ý nghĩa của `ST-02` không làm `ST-02` bị đánh dấu là thẻ sai |
| 2 | Sau đó ghép đúng `ST-01`; tiếp tục làm sai rồi ghép đúng thuật ngữ `ST-03` | Hai cặp có thể hoàn tất nhưng `ST-01` và `ST-03` vẫn thuộc tập không đạt của vòng |
| 3 | Hoàn tất đúng các cặp còn lại | Vòng sau có đúng hai thẻ `ST-01`/`ST-03`, không trùng; `ST-02` không bị kéo vào vì ý nghĩa của nó từng bị chọn nhầm |
| 4 | Quan sát phản hồi và ngữ cảnh trong cả vòng | Chỉ có đúng/sai, không có `Almost`; ngữ cảnh dùng nhãn Vòng và số cặp còn lại, không dùng khái niệm Bàn |

## IT-MODE-006 — `Guess` bị bỏ qua khi cả tập phiên không đủ năm nghĩa

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-4`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới và hoàn tất `Match` | Hệ thống đánh giá điều kiện trên tập bốn thẻ của phiên |
| 2 | Quan sát giai đoạn kế | Toàn bộ giai đoạn `Guess` bị bỏ qua như trạng thái bình thường; không hiển thị câu hỏi chỉ có 2–4 lựa chọn |
| 3 | Tiếp tục tới `Recall` | Không có lỗi và không thẻ nào bị loại khỏi các giai đoạn khác |
