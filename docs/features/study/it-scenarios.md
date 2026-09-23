# study — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: Kịch bản IT — Khởi động, điều hướng và tiếp tục

## IT-NAV-002 — Chuyển giữa tab Thư viện và Học giữ nguyên bộ thẻ đang mở

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có cây `D-EB > D-BRANCH`; người dùng đang ở trong `D-BRANCH`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm tab Học | Tab Học được chọn; hiện bề mặt Study thật, không còn thông báo tính năng chưa sẵn sàng, không tạo phiên chỉ vì đổi tab |
| 2 | Chạm tab Thư viện | Quay lại đúng `D-BRANCH`, không bị đưa về danh sách bộ thẻ gốc |
| 3 | Quan sát đường dẫn phân cấp và danh sách | Đường dẫn và nội dung tại cấp đang mở vẫn đúng; không có phiên Study mới để Tiếp tục |

## IT-NAV-008 — Back từ màn vào học quay về đúng bộ thẻ nguồn mà không tạo phiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SCOPE`; người dùng đang mở bộ thẻ con `Lesson A`; chưa có phiên đang dở.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Học từ `Lesson A` | Màn vào học mở cho đúng `Lesson A`, hiện `New 3`; không lấy hai thẻ của `Lesson B` |
| 2 | Bấm Back của hệ thống khi chưa chọn loại phiên | Quay về đúng `Lesson A`, không về bộ thẻ gốc hoặc tab Học |
| 3 | Quan sát đường dẫn và danh sách thẻ | Ngữ cảnh `Lesson A` còn nguyên; không có route Study trùng trong ngăn xếp |
| 4 | Mở Học lần nữa | Không có hành động Tiếp tục hoặc tổng kết vì lần mở trước chưa tạo phiên |

## IT-NAV-009 — Back qua màn chọn chế độ không tạo phiên và giữ đúng ngăn xếp

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; đang ở bộ thẻ chứa các thẻ đến hạn; chưa có phiên đang dở.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Học rồi chọn Ôn tập | Màn chọn chế độ Eight Box mở; chưa có chế độ nào được chọn |
| 2 | Bấm Back của hệ thống | Quay đúng màn vào học của bộ thẻ đó; chưa tạo phiên ôn tập |
| 3 | Bấm Back của hệ thống lần nữa | Quay đúng bộ thẻ nguồn, không về danh sách bộ thẻ gốc hoặc tab Học |
| 4 | Mở Học lại | Không có phiên để Tiếp tục; số `New`/`Due` không đổi chỉ vì đã đi qua màn chọn |

## IT-NAV-010 — Back của hệ thống trong phiên dùng cùng hợp đồng thoát như nút ✕

> **Tách thành** — `IT-NAV-010` (`HOST-WIDGET`) · `IT-PLAT-005` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đã bắt đầu Học mới và hoàn tất ít nhất một lượt; phiên đang `in_progress`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bấm Back của hệ thống | Hiện cùng xác nhận thoát như nút ✕; màn phiên không bị đóng âm thầm |
| 2 | Hủy xác nhận | Vẫn ở đúng chế độ, vòng, thẻ và tiến độ; phiên còn `in_progress` |
| 3 | Bấm Back lần nữa và xác nhận thoát | Phiên dừng do người dùng, hiện trạng thái đã dừng thay vì tổng kết thành tích và có lối về đúng bộ thẻ |
| 4 | Mở lại màn vào học | Không có Tiếp tục cho phiên đã thoát; các lượt ghi thành công trước đó vẫn được giữ |

## Nhóm: Kịch bản IT — Điểm vào chức năng học và tùy chọn

## IT-STUDY-001 — Màn vào học tách thẻ mới và thẻ đến hạn thành hai tập rời nhau

> **Tách thành** — `IT-STUDY-001` (`HOST-WIDGET`) · `IT-STUDY-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở bộ thẻ và chạm Học | Màn vào học mở cho đúng bộ thẻ |
| 2 | Quan sát hai lựa chọn | Hiện `New 2` và `Due 2` thành hai lựa chọn riêng; không có tổng gộp 4 dưới một hành động |
| 3 | Mở danh sách thẻ với bộ lọc `New` rồi quay lại | Chỉ hai thẻ chưa học xuất hiện; không thẻ đến hạn nào nằm trong tập này |
| 4 | Mở bộ lọc `Due` | Chỉ hai thẻ đã học và đến hạn xuất hiện; không thẻ mới nào nằm trong tập này |

## IT-STUDY-002 — Chỉ xem số lượng hoặc huy hiệu không tạo phiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; chưa từng bấm Học mới.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở danh sách bộ thẻ gốc, danh sách thẻ và màn vào học; chỉ quan sát số lượng/huy hiệu | Mọi nơi thống nhất `New 5`, `Due 0`; chưa vào màn phiên |
| 2 | Đóng hẳn ứng dụng rồi mở lại, vào màn học | Không có hành động Tiếp tục phiên và không có tổng kết của phiên bỏ dở |
| 3 | Chạm Học mới | Chỉ lúc này phiên mới được tạo và giai đoạn đầu xuất hiện |

## IT-STUDY-003 — Không có thẻ đến hạn là trạng thái bình thường và không cho ôn sớm

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FUTURE-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở màn vào học tại `T0` | Lựa chọn Ôn tập không kích hoạt được; màn hình không báo lỗi |
| 2 | Quan sát giải thích | Hiện thời điểm thẻ gần nhất đến hạn bằng ngôn ngữ người dùng |
| 3 | Tìm mọi hành động trên màn | Không có “ôn ngay”, “ôn sớm” hoặc đường vòng mở chế độ ôn tập |
| 4 | Thử kích hoạt lựa chọn Ôn tập bằng thao tác hỗ trợ tiếp cận hoặc chạm | Mục bị vô hiệu hóa không kích hoạt; không tạo phiên và vẫn ở màn vào học |

## IT-STUDY-004 — Eight Box chỉ đưa các chế độ chấm điểm hợp lệ vào ôn tập

> **Tách thành** — `IT-STUDY-004` (`HOST-WIDGET`) · `IT-STUDY-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Hiện màn chọn chế độ cho Eight Box |
| 2 | Kiểm tra danh sách | Có `Match`, `Guess`, `Recall` và `Fill`; không có `Browse` hoặc `Self assess` |
| 3 | Quan sát từng chế độ | Mỗi chế độ có số lượng và trạng thái khả dụng riêng |
| 4 | Quay lại màn vào học mà chưa chọn chế độ | Không có phiên mới để tiếp tục |

## IT-STUDY-005 — SM-2 chỉ có một chế độ ôn nên vào thẳng `Self assess`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-SM2-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Vào thẳng phiên `Self assess`, không hiện màn chọn chỉ có một mục |
| 2 | Quan sát nhãn chế độ và mặt thẻ | Chế độ là `Self assess`; mặt sau còn ẩn |
| 3 | Lật thẻ | Hiện bốn hành động `Again`, `Hard`, `Good`, `Easy`; không có `Forgotten`/`Remembered` |

## IT-STUDY-006 — Chế độ thiếu dữ liệu bị vô hiệu hóa kèm lý do, không mở màn rỗng

> **Tách thành** — `IT-STUDY-006` (`HOST-WIDGET`) · `IT-STUDY-006F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-MINIMAL-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Cho thấy các chế độ của Eight Box |
| 2 | Quan sát `Match` | Bị vô hiệu hóa vì không đủ tối thiểu hai cặp; lý do vẫn đọc được |
| 3 | Quan sát `Guess` | Bị vô hiệu hóa vì không đủ năm nghĩa khác nhau; lý do không gợi ý Đặt lại tiến độ học |
| 4 | Quan sát `Fill` | Bị vô hiệu hóa vì không có thẻ chứa câu ví dụ (`example`); số lượng của `Fill` là 0 |
| 5 | Chọn `Recall` | Phiên mở bình thường; các chế độ bị vô hiệu hóa không chặn toàn bộ việc ôn tập |

## IT-STUDY-007 — Số lượng của từng chế độ ôn phản ánh đúng tập thẻ sử dụng được

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở màn chọn Ôn tập | `Match 5`, `Guess 5`, `Recall 5` và `Fill 3` |
| 2 | Mở `Fill` | Phiên chỉ gồm ba thẻ có câu ví dụ; mẫu số tiến độ là 3 |
| 3 | Thoát, mở lại Ôn tập và chọn `Recall` | `Recall` dùng đủ năm thẻ đến hạn; mẫu số là 5 |

## IT-STUDY-008 — Tùy chọn toàn ứng dụng được giữ sau khi khởi động lại

> **Tách thành** — `IT-STUDY-008` (`HOST-FLOW`) · `IT-PLAT-002` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; bộ thẻ gốc chưa có giá trị ghi đè.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đặt giới hạn thẻ toàn ứng dụng thành 7 và thứ tự thẻ mới thành `Random`; lưu | Có xác nhận lưu thành công, không đóng ứng dụng trước khi ghi xong |
| 2 | Đóng hẳn rồi mở lại ứng dụng | Hai giá trị vẫn là 7 và `Random` |
| 3 | Mở Học mới trên bộ thẻ không có giá trị ghi đè | Màn vào học và phiên dùng giới hạn 7, thứ tự `Random` |

## IT-STUDY-010 — Phiên chốt giới hạn thẻ lúc mở và không đổi theo tùy chọn sau đó

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; giới hạn thẻ hiệu lực là 20.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới | Tập thẻ đã chốt có đúng 20 thẻ riêng biệt và còn đúng 1 thẻ ngoài phiên |
| 2 | Trên một cửa sổ ứng dụng khác, đổi giới hạn thành 5 | Lưu thành công cho phiên tương lai |
| 3 | Quay lại và hoàn thành phiên đang chạy | Phiên vẫn dùng tập 20 thẻ đã chốt, không co xuống 5 |
| 4 | Bắt đầu phiên kế tiếp | Phiên mới dùng giới hạn 5 |

## IT-STUDY-011 — Phạm vi phiên là bộ thẻ đang mở và toàn bộ cây con của nó

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SCOPE`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở bộ thẻ gốc `Korean`, mở Học | Màn vào học hiện `New 5`, lấy cả hai bài trong cây |
| 2 | Tìm tùy chọn thu hẹp phạm vi trước khi bắt đầu | Không có bộ chọn phạm vi hoặc ô đánh dấu tự chọn một phần cây; người dùng chỉ chọn loại phiên |
| 3 | Quay lại, mở `Lesson A` rồi chọn Học | Màn vào học hiện `New 3`; hai thẻ của bộ thẻ cùng cấp `Lesson B` không thuộc phạm vi này |
| 4 | Bắt đầu Học mới tại `Lesson A` và ghi tập mặt trước ở `Browse` | Có đúng ba thẻ của `Lesson A`, không lẫn thẻ cùng cấp |

## IT-STUDY-012 — `Created` chọn đúng tập cũ nhất; `Random` không đổi tập đã chốt khi tiếp tục

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; thời điểm tạo thẻ phân biệt; giới hạn 7.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn `Created`, bắt đầu Học mới và ghi đủ tập thẻ ở `Browse` | Tập phiên có đúng `limit-001`…`limit-007`; không kiểm thứ tự hiển thị vì hàng đợi của giai đoạn được xáo độc lập |
| 2 | Chủ động thoát, chọn `Random`, bắt đầu phiên mới và ghi tập 7 thẻ; nếu trùng tập `Created` thì bỏ phiên và thử lại, tối đa 3 phiên `Random` | Mỗi tập đã chốt có đúng 7 thẻ riêng biệt thuộc 21 thẻ mới; mỗi lần thử lại tạo một phiên mới |
| 3 | So tối đa ba lần lấy với tập `Created` | Ít nhất một tập `Random` khác `limit-001`…`limit-007`; cả ba tập đều giống `Created` là `FAIL` |
| 4 | Trong phiên `Random` khác biệt đó, ghi tập thẻ và thứ tự, buộc đóng tiến trình rồi Tiếp tục trong cùng ngày | Đúng tập đã chốt, thẻ hiện tại và thứ tự đang dở được giữ; `Random` không chạy lại khi Tiếp tục |

## IT-STUDY-013 — Cấu hình bộ thẻ gốc không đọc được thì dùng mặc định và không chặn học

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-BROKEN-OPTIONS-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Tùy chọn học từ bộ thẻ gốc | Hiện giá trị hiệu lực mặc định 20/`Created`; không lộ JSON, ngoại lệ hoặc dấu vết ngăn xếp |
| 2 | Quay lại và mở Học | Màn vào học vẫn hiện `New 21`; lỗi cấu hình không biến thành trạng thái bị chặn hoặc trạng thái rỗng giả |
| 3 | Chọn Học mới và ghi tập thẻ ở `Browse` | Phiên mở với đúng 20 thẻ cũ nhất `limit-001`…`limit-020` |
| 4 | Thoát và mở lại Tùy chọn học | Vẫn dùng mặc định một cách xác định; ứng dụng không tự ghi giá trị đè mới nếu người dùng chưa bấm lưu |

## Nhóm: Kịch bản IT — Phiên học thẻ mới

## IT-LEARN-001 — Eight Box đi đúng chuỗi năm giai đoạn

> **Tách thành** — `IT-LEARN-001` (`HOST-FLOW`) · `IT-LEARN-001W` (`HOST-WIDGET`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Học mới | Giai đoạn đầu là `Browse`; người dùng không được chọn giai đoạn |
| 2 | Đi hết `Browse` | Chuyển sang `Match`, không nhảy thẳng tới giai đoạn khác |
| 3 | Hoàn tất mỗi vòng `Match` bằng kết quả đúng | Chuyển lần lượt sang `Guess`, `Recall`, rồi `Fill` |
| 4 | Hoàn tất `Fill` | Phiên chuyển sang `completed` và hiện tổng kết |
| 5 | Quan sát toàn hành trình | Chuỗi chính xác `Browse → Match → Guess → Recall → Fill`; không có `Self assess` |

## IT-LEARN-002 — SM-2 đi đúng chuỗi `Browse` rồi `Self assess`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SM2-4`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Học mới | Mở `Browse`, không có màn chọn giai đoạn |
| 2 | Đi hết bốn thẻ ở `Browse` | Chuyển sang `Self assess` |
| 3 | Với mỗi thẻ, lật rồi chọn `Good` | Không xuất hiện `Match`, `Guess`, `Recall` hoặc `Fill` |
| 4 | Hết hàng đợi | Phiên chuyển sang `completed` và hiện tổng kết |

## IT-LEARN-004 — Mọi giai đoạn dùng cùng tập thẻ nhưng thứ tự độc lập

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; công cụ tự động ghi lại thứ tự mặt trước nhìn thấy.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi thứ tự năm thẻ ở `Browse` | Có đúng năm ID, không trùng và không thiếu |
| 2 | Ghi thứ tự và thẻ sở hữu lượt ở `Match` và `Guess` | Vẫn đúng cùng tập năm thẻ |
| 3 | So sánh các chuỗi | Với từ hai thẻ trở lên, giai đoạn sau không tái sử dụng nguyên chuỗi của giai đoạn trước |
| 4 | Chọn Tiếp tục giữa một giai đoạn | Thứ tự của giai đoạn đang dở không đổi chỉ vì dựng lại giao diện hoặc khởi động lại |

## IT-LEARN-005 — Thẻ thiếu câu ví dụ được bỏ qua ở `Fill` nhưng vẫn hoàn tất học mới

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-PLAIN`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đi hết `Browse`, `Match`, `Guess` và `Recall` | Năm thẻ đều tham gia các giai đoạn đủ dữ liệu |
| 2 | Tới chỗ `Fill` đáng lẽ bắt đầu | `Fill` bị bỏ qua thay vì hiện trạng thái rỗng/lỗi hoặc thẻ không có câu ví dụ |
| 3 | Quan sát tổng kết | Phiên đã `completed`; không có thẻ bị kẹt ở trạng thái chờ |
| 4 | Quay về bộ thẻ | Cả năm thẻ không còn trong tập `New` và có hạn đầu tiên vào ngày học kế tiếp |

## IT-LEARN-008 — Thẻ sai trong một vòng chỉ rời tập không đạt sau vòng sạch

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới vòng 1 của `Recall`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Trong vòng 1 của `Recall`, để `ST-01` hết giờ và lật đúng bốn thẻ còn lại | `ST-01` là thẻ duy nhất thuộc tập không đạt của vòng 1 |
| 2 | Quan sát vòng 2 | Chỉ có `ST-01`, không có bản sao trùng của thẻ này |
| 3 | Để `ST-01` hết giờ ở vòng 2 và vòng 3 | Mỗi vòng kế tiếp vẫn được tạo; ứng dụng không áp trần 3 của `Self assess` cho chế độ dùng vòng |
| 4 | Quan sát vòng 4 rồi lật `ST-01` trước hạn | Vòng 4 thực sự mở; chỉ vòng sạch mới kết thúc giai đoạn |

## IT-LEARN-009 — `Self assess` lặp thẻ đúng khoảng cách và bật cờ ở trần học lại

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-SM2-4`; đi hết `Browse` để tới `Self assess`; tất cả thẻ chưa được gắn cờ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Lật thẻ đầu và chọn `Again` | Thẻ chưa xuất hiện lại trước khi đã phục vụ ít nhất ba thẻ khác, hoặc ở cuối nếu hàng đợi không đủ |
| 2 | Chọn `Again` ở ba lượt học lại của cùng thẻ | Sau lượt học lại thứ ba, thẻ rời hàng đợi dù kết quả vẫn là `Again` |
| 3 | Hoàn tất phiên rồi mở danh sách thẻ | Thẻ đó được bật cờ và vẫn thuộc `New`, chưa có hạn; các thẻ khác không tự bị gắn cờ |
| 4 | Mở phiên khác | Ứng dụng không tự tắt cờ; bỏ cờ vẫn là thao tác người dùng |

## IT-LEARN-011 — Giới hạn thẻ là trần mỗi phiên, không phải hạn mức ngày

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; giới hạn hiệu lực là 20.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới | Phiên chứa tối đa 20 thẻ riêng biệt dù mỗi thẻ có nhiều giai đoạn/vòng |
| 2 | Hoàn tất phiên | Tổng kết nói còn đúng 1 thẻ mới ngoài phiên và cho hành động bắt đầu phiên tiếp |
| 3 | Bắt đầu phiên thứ hai trong cùng ngày | Phiên mở với thẻ còn lại; không báo đã hết “hạn mức ngày” |
| 4 | Hoàn tất | `New` về 0; hai phiên đều có tổng kết riêng |

## IT-LEARN-012 — Bỏ dở học mới không tạo lịch nửa chừng và lần sau học lại từ `Browse`

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới, đi hết `Browse`, ghép đúng một cặp rồi ghép sai một cặp `Match` | Tiến độ trong phiên được ghi, nhưng cả năm thẻ vẫn là `New` và `Due` vẫn 0 |
| 2 | Chạm ✕ và xác nhận thoát | Phiên kết thúc do người dùng; không có Tiếp tục cho phiên này |
| 3 | Đóng/mở ứng dụng rồi vào Học trong cùng ngày | `New 5`, `Due 0`; không thẻ nào bị đưa sang ôn tập chỉ vì đã đi qua một phần chuỗi |
| 4 | Bắt đầu Học mới lần nữa | Phiên mới bắt đầu từ `Browse` trên tập thẻ mới chốt; không nối thẳng vào `Match` của phiên đã bỏ |

## Nhóm: Kịch bản IT — Phiên ôn tập và thuật toán xếp lịch

## IT-REVIEW-001 — Hàng đợi ôn tập chỉ lấy thẻ đã học và đang đến hạn

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập và chọn `Recall` | Phiên `reviewing` mở với mẫu số 2 |
| 2 | Đi qua toàn bộ hàng đợi, ghi mặt trước đã thấy | Có đúng hai thẻ `Due`; không có hai thẻ `New` hoặc hai thẻ chưa đến hạn |
| 3 | Hoàn tất | Tổng kết không tính thẻ mới/chưa đến hạn là thẻ còn lại của phiên |

## IT-REVIEW-003 — Phiên ôn tập SM-2 lấy hành động trực tiếp từ người dùng

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-SM2-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Ôn tập | Vào thẳng `Self assess` |
| 2 | Trước khi lật | Chỉ thấy mặt trước; chưa thấy mặt sau hoặc hành động đánh giá |
| 3 | Lật | Hiện mặt sau cùng `Again`, `Hard`, `Good`, `Easy` |
| 4 | Chọn `Good` | Ghi đúng một kết quả và chuyển thẻ; không tự chấm lại lựa chọn của người dùng thành đúng/sai |

## IT-REVIEW-004 — Thẻ có hạn sớm hơn được phục vụ trước và giới hạn tính theo thẻ riêng biệt

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; đặt giới hạn thẻ là 3; `Recall` dùng được cho cả năm thẻ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đặt giới hạn thẻ là 3 và bắt đầu Ôn tập | Phiên chứa đúng ba thẻ riêng biệt dù thẻ có thể lặp ở vòng sau |
| 2 | Ghi thứ tự thẻ ở lượt đầu | Ba thẻ có `due_at` sớm nhất được phục vụ theo thứ tự tăng dần |
| 3 | Làm sai một thẻ để tạo vòng/học lại | Lượt lặp không làm một thẻ thứ tư lọt vào tập thẻ đã chốt của phiên |
| 4 | Hoàn tất | Tổng kết cho biết còn thẻ `Due` ngoài phiên |

## IT-REVIEW-008 — Không thể ôn lại trước hạn vừa được xếp

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Ôn tập, chọn `Match` và hoàn tất đúng mọi thẻ | Phiên chuyển sang `completed`; từng thẻ được xếp sang một hạn tương lai |
| 2 | Quay lại màn vào học ngay tại `T0`, rồi đóng/mở ứng dụng trong cùng ngày | `Due` về 0; không thẻ vừa xử lý nào mở lại được và không có đường “ôn sớm” |
| 3 | Dịch đồng hồ kiểm thử tới một giây trước 00:00 của hạn gần nhất | Thẻ vẫn chưa thuộc `Due` |
| 4 | Dịch tới đúng 00:00 địa phương của hạn gần nhất | Thẻ có hạn đó xuất hiện trong `Due`; thẻ có hạn muộn hơn vẫn chưa xuất hiện |

## IT-REVIEW-009 — Tổng kết phân biệt thẻ đã xử lý và thẻ đến hạn còn ngoài giới hạn

- **Ưu tiên:** P1
- **Tiền điều kiện:** `S-STUDY-REVIEW-EB-V2`; đặt giới hạn thẻ hiệu lực thành 3 trước khi mở phiên.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu rồi hoàn tất một phiên ôn tập | Tổng kết hiện 3 thẻ của phiên đã hoàn tất và còn đúng 2 thẻ `Due` ngoài phiên |
| 2 | Chạm bắt đầu phiên tiếp | Mở một phiên mới với tập thẻ mới chốt từ số thẻ `Due` còn lại |
| 3 | Quay lại bộ thẻ thay vì bắt đầu | Màn vào học vẫn hiển thị đúng số `Due` còn lại, không cộng lại thẻ đã xếp lịch |

## Nhóm: Kịch bản IT — Sáu chế độ học

## IT-MODE-001 — Khung phiên luôn nói rõ chế độ, bộ thẻ, loại phiên và tiến độ

- **Ưu tiên:** P1
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Học mới và quan sát thanh trên/dòng ngữ cảnh | Có nút đóng ✕, nhãn `Browse`, tên bộ thẻ, loại phiên Học mới và tiến độ chỉ của tập `New` |
| 2 | Chuyển giai đoạn trong phiên học mới | Nhãn chế độ, ngữ cảnh và tiến độ đổi theo giai đoạn nhưng vẫn giữ đúng bộ thẻ và phiên |
| 3 | Chủ động thoát, mở Ôn tập và chọn `Recall` | Cùng khung nhưng loại phiên là Ôn tập; tiến độ chỉ của tập `Due` và vị trí số đếm được thay bằng đồng hồ `Recall` |
| 4 | Quan sát màu trước và sau một kết cục | Màu thành công/nguy hiểm chỉ xuất hiện cho kết quả đúng/sai, không dùng làm màu nhận diện chế độ trước khi trả lời |

## IT-MODE-003 — `Match` giữ nguyên bàn và phân biệt ba trạng thái ô

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới `Match` với năm cặp.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn một thuật ngữ | Ô thuật ngữ chuyển sang trạng thái đang chọn; các ô không dịch vị trí |
| 2 | Chọn đúng ý nghĩa | Cả cặp ở lại đúng vị trí, có dấu đúng/mờ đi và không bấm lại được |
| 3 | Ghép cặp khác | Cặp đã xong không biến mất khiến hàng dưới dồn lên |
| 4 | Dựng lại giao diện nhẹ bằng xoay màn hình hoặc đưa ứng dụng ra trước nếu hồ sơ cho phép | Dấu cặp đã ghép vẫn còn trong cùng vòng |

## IT-MODE-005 — `Guess` luôn có đúng năm lựa chọn khác nghĩa và chỉ nhận lần chạm đầu

> **Tách thành** — `IT-MODE-005` (`HOST-WIDGET`) · `IT-MODE-005F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng UI tới Guess với năm `back_folded` khác nhau.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát câu hỏi | Có đúng năm lựa chọn A–E; đáp án đúng xuất hiện đúng một lần |
| 2 | Chọn một đáp án sai | Đáp án đúng hiện trạng thái thành công/✓, lựa chọn sai đã chọn hiện trạng thái nguy hiểm/✕, ba lựa chọn khác mờ |
| 3 | Chạm tiếp lựa chọn khác nhiều lần | Không thay đổi kết cục và không sinh lượt thứ hai |
| 4 | Sang câu kế | A–E phản ánh vị trí hiển thị mới, không được dùng như định danh thẻ |

## IT-MODE-007 — Thứ tự thẻ và lựa chọn ổn định khi Tiếp tục nhưng là hai hoán vị độc lập

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới `Guess`; có thể khởi động lại giữa lượt.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi thứ tự thẻ của vòng và thứ tự năm lựa chọn ở câu hiện tại | Có hai chuỗi làm mốc so sánh |
| 2 | Đưa ứng dụng xuống nền/ra trước, rồi khởi động lại tiến trình và chọn Tiếp tục | Thẻ hiện tại và năm lựa chọn giữ nguyên thứ tự |
| 3 | Sang vòng mới | Thứ tự thẻ được xáo riêng cho vòng mới |
| 4 | So các chuỗi | Đổi thứ tự thẻ không kéo theo cùng một hoán vị cho lựa chọn; hai thứ không khóa cứng vào nhau |

## IT-MODE-008 — `Recall` đo 20 giây tương tác, lật thủ công trước hạn được ưu tiên

> **Tách thành** — `IT-MODE-008` (`HOST-WIDGET`) · `IT-MODE-008F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới một lượt `Recall` mới; đo được đồng hồ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát lượt mới | Đáp án ẩn có nhãn ngữ nghĩa; thanh trên hiện tối đa 20 giây |
| 2 | Chờ một khoảng khi ứng dụng ở phía trước | Thời gian giảm theo thời gian tương tác; thời gian tải nội dung không bị tính vào lượt |
| 3 | Chạm Hiện đáp án trước hạn | Mặt sau hiện ra và kết cục được chốt một lần, không còn hành động khác để đổi |
| 4 | Quan sát trạng thái sau khi lật | Có lời xác nhận lượt đã chốt; màn hình không giống bị treo và chỉ vòng sau mới bắt đầu lại 20 giây |

## IT-MODE-009 — `Recall` hết giờ tự lật, khóa kết cục sai và giữ thời gian khi Tiếp tục

> **Tách thành** — `IT-MODE-009` (`HOST-WIDGET`) · `IT-MODE-009F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi tới `Recall`, giữ ứng dụng ở phía trước tới khi đồng hồ nằm trong `12.0…12.8` giây; chưa lật.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đưa ứng dụng xuống nền 5 giây rồi ra trước | Đồng hồ giảm không quá 1 giây do chuyển trạng thái; không mất 5 giây ở nền |
| 2 | Đóng tiến trình và chọn Tiếp tục trong cùng ngày | Quay đúng lượt, đáp án vẫn ẩn và đồng hồ tiếp tục từ thời gian còn lại, không đặt lại 20 giây |
| 3 | Không thao tác tới đúng hạn | Hệ thống tự lật, nói rõ đã hết giờ và chốt kết cục sai |
| 4 | Chạm vùng Hiện đáp án cũ hoặc thao tác lặp | Không đổi sang đúng và không sinh lượt thứ hai |

## IT-MODE-010 — `Fill` bỏ khoảng trắng, không phân biệt hoa thường nhưng giữ dấu; ô nhập rỗng không tiến lượt

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FILL-V2`; ba nhánh rỗng/hoa-thường/dấu nạp lại bộ dữ liệu sạch và mở Ôn tập > `Fill`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở nhánh rỗng, để trống hoặc nhập chỉ khoảng trắng rồi chạm Kiểm tra | Không ghi kết cục, không tiến độ; lỗi/hướng dẫn nằm tại ô nhập |
| 2 | Nạp lại bộ dữ liệu; nhập `  cÔnG  ` rồi chạm Kiểm tra | Được chấm đúng do bỏ khoảng trắng hai đầu và hạ chữ hoa/thường theo Unicode |
| 3 | Nạp lại bộ dữ liệu; nhập `cong` rồi chạm Kiểm tra | Bị chấm sai vì chính sách giữ dấu |
| 4 | Khởi động lại sau nhánh sai | Kết quả đã chấm còn hiệu lực; nội dung thô người dùng gõ không được điền lại như một câu trả lời đã lưu |

## IT-MODE-011 — Gợi ý không tự đổi kết quả và `Fill` chỉ nhận một lần gửi

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FILL-V2`; mở Ôn tập và chọn `Fill`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Gợi ý | Gợi ý xuất hiện; tiến độ và lịch chưa đổi |
| 2 | Nhập đáp án sai rồi chạm Kiểm tra | Kết quả vẫn sai; dùng gợi ý không biến nó thành đúng |
| 3 | Quan sát trạng thái sau chấm | Ô nhập đóng; hiện mặt sau thật của thẻ cùng trạng thái sai, không mời nhập lại trong cùng lượt |
| 4 | Chạm Kiểm tra lặp hoặc cố sửa ô nhập | Không sinh lần gửi/kết cục thứ hai |

## IT-MODE-012 — `Self assess` chỉ hiện hành động sau khi người dùng lật

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-ALL-MODES`; ở bộ thẻ gốc SM-2, chọn Học mới và đi hết `Browse` để tới `Self assess`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát ban đầu | Chỉ mặt trước và hành động lật; mặt sau cùng bốn hành động đều chưa hiện |
| 2 | Chạm lật | Mặt sau và `Again`/`Hard`/`Good`/`Easy` cùng xuất hiện |
| 3 | Chọn một hành động | Chỉ hành động người dùng chọn được dùng; giao diện khóa trong lúc ghi để chống bấm đôi |
| 4 | Ở một bộ thẻ Eight Box, mở màn chọn Ôn tập | Không có `Self assess` và không xuất hiện bốn nút SM-2; Eight Box chỉ đưa bốn chế độ chấm nhị phân đã định nghĩa |

## IT-MODE-014 — `Guess` chặn nguyên tử nếu một câu hỏi bất ngờ thiếu phương án nhiễu

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-GUESS-BLOCKED-V2`; màn chọn đã xác nhận `Guess` khả dụng.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn `Guess` và đi tới câu hỏi bị bộ tạo lỗi tác động | Màn chặn có nội dung rõ; không hiển thị câu hỏi dưới năm lựa chọn |
| 2 | Quan sát tiến độ trên màn chặn | Thẻ hiện tại, điểm dừng và tiến độ chưa đổi; câu hỏi không bị tự bỏ qua |
| 3 | Kiểm tra mọi hành động trên màn chặn | Chỉ có đường rời phiên; không có Thử lại/Tiếp tục/Bỏ qua làm tiến điểm dừng trái BR-STUDY-040 |
| 4 | Rời phiên, tắt lỗi, bắt đầu một phiên `Guess` mới | Câu hỏi mới dựng được với đúng năm lựa chọn; chỉ lựa chọn của người dùng trong phiên mới được chấm |

## IT-MODE-015 — `Guess` chỉ lấy phương án nhiễu hợp lệ trong cùng cây mà không lộ thẻ mới

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-GUESS-SOURCE-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở bộ thẻ gốc A, chọn Ôn tập rồi `Guess` | Phiên có câu hỏi của thẻ `Due`; bốn thẻ đã học nhưng chưa đến hạn trong cùng cây có thể làm nguồn nhiễu dù không nằm trong hàng đợi ôn tập |
| 2 | Ghi năm nghĩa trên câu hỏi | Có đáp án đúng đúng một lần và bốn phương án nhiễu tham chiếu bốn thẻ khác thẻ đang hỏi |
| 3 | Đối chiếu với bộ dữ liệu dựng sẵn | Không có `new-only-secret` và không có `other-root-secret`; chức năng học không làm lộ thẻ `New` hoặc lấy nội dung từ bộ thẻ gốc khác |
| 4 | Kiểm tra cặp nghĩa chỉ khác hoa/khoảng trắng | Chỉ tối đa một biến thể xuất hiện; năm lựa chọn luôn khác nhau theo `back_folded`, không chỉ khác chuỗi hiển thị |

## Nhóm: Kịch bản IT — Tiếp tục phiên, ngoại tuyến và lỗi

## IT-CONT-001 — Tiến trình bị hệ điều hành thu hồi trong cùng ngày vẫn Tiếp tục đúng điểm dừng

> **Tách thành** — `IT-CONT-001` (`HOST-FLOW`) · `IT-PLAT-003` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; người dùng chưa bấm ✕.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới, đi qua ít nhất hai lượt rồi ghi chế độ, vòng, thẻ hiện tại, tiến độ và trạng thái đang dở | Có mốc so sánh nhìn thấy được của phiên `in_progress` |
| 2 | Buộc đóng tiến trình như khi hệ điều hành thu hồi, không dùng hành động thoát trong ứng dụng | Ứng dụng đóng mà người dùng chưa chủ động bỏ phiên |
| 3 | Mở lại trong cùng ngày học và vào Học | Màn vào học có ba đường: Tiếp tục, Học mới, Ôn tập theo khả năng hiện tại |
| 4 | Chọn Tiếp tục | Quay đúng phiên/chế độ/vòng/thẻ/điểm dừng; hàng đợi và thứ tự không được dựng lại |

## IT-CONT-002 — Chọn phiên mới khi có phiên cùng ngày sẽ đóng phiên cũ do người dùng bỏ

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đã bắt đầu Học mới, đi qua ít nhất một lượt rồi buộc đóng tiến trình và mở lại cùng ngày.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Không chọn Tiếp tục; chọn Học mới | Phiên cũ được đóng và phiên `learning` mới mở; tài liệu không bắt buộc một bước xác nhận trung gian |
| 2 | Quay lại màn vào học | Phiên cũ không còn tiếp tục được; chỉ phiên mới là phiên đang chạy |
| 3 | Khởi động lại và mở màn vào học | Không xuất hiện hai phiên cùng cho Tiếp tục; chỉ trạng thái hợp lệ của phiên mới còn lại |
| 4 | Kiểm tra các lượt đã hoàn tất ở phiên cũ qua tiến độ người dùng | Kết quả đã ghi không bị hoàn tác vì bỏ phiên |

## IT-CONT-003 — Phiên từ ngày học trước bị đóng với lý do gián đoạn

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới, hoàn tất vài lượt rồi buộc đóng tiến trình mà không bấm ✕ | Phiên còn `in_progress` ở ngày học của `T0` |
| 2 | Dịch đồng hồ kiểm thử sang ngày học kế tiếp rồi mở ứng dụng | Phiên cũ không được tiếp tục như phiên cùng ngày |
| 3 | Mở màn vào học | Người dùng có thể tạo phiên mới; không thấy điểm dừng cũ giả như còn hợp lệ |
| 4 | Dùng công cụ kiểm tra chỉ đọc của Study v2 sau các thao tác giao diện | Phiên cũ là `abandoned/interrupted`, không phải `user_exit`; các lượt đã ghi trước khi đóng tiến trình vẫn giữ |

## IT-CONT-004 — Nút ✕ là thoát chủ động, không phải thao tác Quay lại vô hại

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; bắt đầu Học mới và đi qua ít nhất một lượt.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm ✕ | Có xác nhận nếu giao diện dùng; hậu quả thoát được nói rõ |
| 2 | Hủy xác nhận | Phiên vẫn nguyên điểm dừng, chưa kết thúc |
| 3 | Chạm ✕ và xác nhận | Hiện trạng thái phiên đã dừng vì người dùng thoát, không trình bày như một thành tích; có lối về bộ thẻ |
| 4 | Mở lại màn vào học | Không cho Tiếp tục phiên đã chủ động thoát; lượt đã ghi vẫn phản ánh trong tiến độ |

## IT-CONT-005 — Phiên hoàn tất có tổng kết và không còn hàng đợi chờ xử lý

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới khi phiên chỉ còn đúng một lượt hợp lệ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Hoàn tất lượt cuối | Không hiện thêm thẻ cũ hoặc vòng quay tải vô hạn |
| 2 | Quan sát tổng kết phiên học mới | Hiện số thẻ vừa hoàn tất chuỗi và số lượt sai; không có biểu đồ, chuỗi ngày học hoặc thống kê dài hạn |
| 3 | Chạm Quay về bộ thẻ | Trở về đúng bộ thẻ; số lượng phản ánh các lượt đã hoàn tất |
| 4 | Khởi động lại và mở màn vào học | Không có Tiếp tục cho phiên đã `completed` |

## IT-CONT-006 — Hàng đợi bất biến khi nội dung bộ thẻ đổi sau lúc mở phiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-RESUME-V2`; có cửa sổ ứng dụng thứ hai dùng cùng cơ sở dữ liệu kiểm thử.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi mẫu số và các thẻ đã thấy trong phiên | Có mốc so sánh cho tập thẻ đã chốt |
| 2 | Ở cửa sổ thứ hai, thêm một thẻ mới vào bộ thẻ | Thẻ mới được lưu cho bộ thẻ |
| 3 | Quay lại phiên | Mẫu số/tập thẻ không nhận thẻ mới; thứ tự hàng đợi không được dựng lại |
| 4 | Hoàn tất phần hàng đợi còn lại | Không có lượt nào của thẻ mới; thẻ đó chỉ có thể vào tập đã chốt của phiên tạo sau |

## IT-CONT-007 — Xóa bộ thẻ đang học kết thúc phiên và phục hồi điều hướng

> **Tách thành** — `IT-CONT-007` (`HOST-FLOW`) · `IT-CONT-007W` (`HOST-WIDGET`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-RESUME-V2`; cửa sổ thứ hai có thể xóa đúng bộ thẻ/bộ thẻ gốc.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở cửa sổ thứ hai, xóa bộ thẻ và xác nhận | Bộ thẻ biến mất theo UC-DECK-002 |
| 2 | Quay lại phiên và thực hiện hành động tiếp | Ứng dụng không sập, không lộ ID/SQL và không ghi vào thẻ đã mất |
| 3 | Quan sát điều hướng | Phiên kết thúc và đưa về danh sách bộ thẻ hợp lệ |
| 4 | Khởi động lại | Bộ thẻ hoặc phiên mồ côi không xuất hiện lại |

## IT-CONT-008 — Toàn bộ phiên học hoạt động ngoại tuyến

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; ứng dụng đang mở; thiết bị điều khiển được chế độ máy bay.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bật chế độ máy bay | Ứng dụng không yêu cầu đăng nhập hoặc mạng |
| 2 | Mở màn vào học, bắt đầu và hoàn tất một phiên | Mọi chế độ/nội dung cần thiết được tải cục bộ; lượt được ghi ngay và tổng kết hiện bình thường |
| 3 | Đóng hẳn rồi mở lại khi vẫn ngoại tuyến | Phiên vẫn `completed`, trạng thái và hạn của thẻ còn đúng |
| 4 | Bắt đầu hoặc Tiếp tục một phiên khác | Không có chặn mạng giả hoặc yêu cầu thử lại kết nối |

## IT-CONT-010 — Phiên thuộc thế hệ dữ liệu cũ bị từ chối nguyên tử

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-RESUME-V2`; công cụ tạo lỗi/nhiều cửa sổ tăng thế hệ dữ liệu nhưng chưa làm mất hiệu lực phiên trước khi gửi hành động.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Sau khi bộ thẻ gốc tăng thế hệ dữ liệu, gửi hành động từ phiên cũ | Hành động bị từ chối trước khi bất kỳ phần nào được ghi |
| 2 | Quan sát phiên | Phiên đóng với `invalidated/stale_generation` và giải thích tiến độ vừa được đặt lại |
| 3 | Quay về bộ thẻ | Trạng thái đang hoạt động hoàn toàn thuộc thế hệ mới |
| 4 | Kiểm tra bằng bề mặt lịch sử được phê duyệt | Không có dòng lịch sử cho hành động bị từ chối; các lượt cũ trước đó vẫn còn |

## IT-CONT-011 — Lỗi ghi tạm thời không tiến thẻ và thử lại chỉ ghi một lần

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FAILURE-V2` ở chế độ lỗi một lần rồi phục hồi.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Trả lời thẻ khi bộ tạo lỗi gây lỗi ghi đầu tiên | Hiện lỗi ngay; thẻ, tiến độ và hành động vẫn ở nguyên lượt |
| 2 | Chạm lại đúng hành động sau khi bộ tạo lỗi phục hồi | Ghi thành công và tiến đúng một thẻ |
| 3 | Khởi động lại/Tiếp tục | Không có lượt trùng do lần thử lại; lịch và trạng thái chỉ thay đổi một lần |

## IT-CONT-012 — Lỗi lưu trữ không thể tiếp tục đóng phiên ở trạng thái `failed` nhưng giữ lượt cũ

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FAILURE-V2` ở chế độ lỗi nghiêm trọng; phiên đã có ít nhất hai lượt thành công.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Thực hiện hành động tại điểm bộ tạo lỗi phát sinh lỗi nghiêm trọng | Ứng dụng không tiến sang thẻ tiếp và không giả vờ hoàn tất |
| 2 | Quan sát thông báo | Giải thích không thể tiếp tục, không lộ SQL/dấu vết ngăn xếp/nội dung riêng tư |
| 3 | Chọn lối phục hồi | Phiên đóng với `failed/persistence_error` và về danh sách bộ thẻ |
| 4 | Tắt bộ tạo lỗi, khởi động lại và xem tiến độ | Hai lượt đã thành công vẫn giữ; hành động gây lỗi không được ghi một phần |

## IT-CONT-013 — Lỗi đọc thẻ cho phép Thử lại mà không làm mất điểm dừng

> **Tách thành** — `IT-CONT-013` (`HOST-FLOW`) · `IT-CONT-013W` (`HOST-WIDGET`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FAILURE-V2` ở chế độ lỗi đọc một lần rồi phục hồi; phiên đang ở thẻ đã biết.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đi tới thẻ mà bộ tạo lỗi làm lỗi đọc | Hiện trạng thái lỗi có Thử lại; không lộ nội dung thẻ khác, ID kỹ thuật, SQL hoặc dấu vết ngăn xếp |
| 2 | Quan sát tiến độ | Thẻ hiện tại và điểm dừng chưa bị bỏ qua; không có kết cục học giả được ghi |
| 3 | Tắt lỗi và chạm Thử lại | Chính thẻ đó tải lại thành công; phiên không bị dựng mới hoặc đổi thứ tự |
| 4 | Hoàn tất lượt bằng thao tác bình thường | Chỉ lượt người dùng vừa thực hiện được tính và phiên tiếp tục |

## IT-CONT-014 — Chọn Ôn tập khi có phiên cùng ngày đóng phiên cũ do người dùng bỏ

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2`; đã bắt đầu Học mới, hoàn tất ít nhất một lượt rồi buộc đóng tiến trình và mở lại trong cùng ngày học.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở lại Study | Màn chọn hiện đủ ba đường Tiếp tục, Học mới và Ôn tập; phiên cũ chưa bị đóng chỉ vì quan sát màn |
| 2 | Không chọn Tiếp tục; chọn Ôn tập rồi chọn một chế độ khả dụng | Phiên học mới cũ được đóng và một phiên `reviewing` mới mở; không có hai phiên cùng `in_progress` |
| 3 | Thoát phiên ôn tập rồi mở lại Study | Phiên học mới cũ không còn được mời Tiếp tục; các lượt đã ghi trước khi bỏ phiên vẫn còn trong tiến độ |
| 4 | Dùng công cụ kiểm tra chỉ đọc Study v2 | Phiên cũ là `abandoned/user_exit`, không phải `interrupted`; phiên ôn tập mang đúng loại `reviewing` |

## Nhóm: Kịch bản ranh giới nền tảng

## IT-PLAT-003 — Phiên học bị hệ điều hành thu hồi vẫn tiếp tục đúng điểm dừng

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một bộ thẻ có đủ thẻ để mở phiên học mới.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở phiên học và trả lời ít nhất một thẻ | Bộ đếm tiến lên |
| 2 | Đóng hẳn tiến trình giữa phiên | App thoát hoàn toàn |
| 3 | Mở lại và chọn Tiếp tục | Phiên mở lại đúng thẻ kế tiếp, không quay về thẻ đầu |

Dẫn xuất từ `IT-CONT-001`. Ranh giới: `study_session.cursor` và hàng đợi
phải nằm trên đĩa chứ không trong bộ nhớ. Chuỗi vòng, tập không đạt và lịch
thì đã có ở `HOST-FLOW`.

## IT-PLAT-005 — Cử chỉ back của hệ thống trong phiên dùng cùng hợp đồng thoát như nút ✕

- **Ưu tiên:** P1
- **Tiền điều kiện:** Một phiên học đang mở.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Dùng cử chỉ back của hệ điều hành, không phải nút ✕ | Phiên đóng như người dùng bỏ, đúng BR-STUDY-014 |
| 2 | Quay lại màn vào học | Không còn phiên nào đang mở chờ tiếp tục |

Dẫn xuất từ `IT-NAV-010`. Ranh giới: cử chỉ predictive back của Android và
đường nó tới `PopScope`. Việc `PopScope` ghi gì thì `HOST-WIDGET` đã kiểm.
