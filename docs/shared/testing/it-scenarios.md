# Kịch bản IT dùng chung

Kịch bản IT không truy vết về UC/BR của feature nào, và phần giới thiệu nhóm không thuộc riêng feature nào. Hướng dẫn thực thi và danh mục: [`README.md`](README.md), [`scenario-catalog.md`](scenario-catalog.md).

## Nhóm: Kịch bản IT — Khởi động, điều hướng và tiếp tục

## IT-NAV-005 — Route không hợp lệ có lối phục hồi an toàn

> **Tách thành** — `IT-NAV-005` (`HOST-WIDGET`) · `IT-PLAT-004` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có thể mở URL/deep link development trỏ tới route không tồn tại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở route không tồn tại | Hiện màn không tìm thấy bằng ngôn ngữ người dùng; không lộ stack trace, SQL hay ID nội bộ |
| 2 | Chạm hành động quay về Deck | Mở danh sách root deck và tab Thư viện được chọn |

## IT-NAV-007 — Hành trình quản lý nội dung chạy khi offline

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `D-EB > D-LEAF`; app đang mở; thiết bị có thể bật chế độ máy bay.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bật chế độ máy bay | App không chặn thao tác quản lý nội dung và không yêu cầu đăng nhập |
| 2 | Điều hướng tới `D-EB` và tạo một sub-deck mới | Deck được tạo và xuất hiện ngay trong `D-EB` |
| 3 | Tạo, sửa rồi gắn cờ một card trong `D-LEAF` | Mọi thay đổi được phản ánh trên UI |
| 4 | Đóng hẳn rồi mở lại app khi vẫn offline | Deck và card vừa thay đổi vẫn còn |
| 5 | Xoá card vừa tạo | Card bị xoá thành công khi không có mạng |

## Nhóm: IT scenarios — Tìm kiếm, tổ chức và tiến độ card

## IT-ORG-012 — Danh sách lớn tải theo cửa sổ và không mất card

- **Ưu tiên:** P2
- **Tiền điều kiện:** Dùng `S-LARGE` có 65 card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở deck | Ban đầu hiển thị tối đa 50 card và dòng “đang hiện 50/65” |
| 2 | Cuộn cuối danh sách | Có hành động tải thêm, không báo đã hiển thị tất cả |
| 3 | Chạm tải thêm | Danh sách tăng và cuối cùng hiện đủ 65/65, không trùng hoặc mất row |
| 4 | Mở một card rồi Back | Card list vẫn sử dụng được và dữ liệu đã tải không bị sai |

## Nhóm: Kịch bản IT — Sáu chế độ học

## IT-MODE-013 — Các chế độ học dùng được với trình đọc màn hình và cỡ chữ lớn

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-ALL-MODES`; bật được dịch vụ hỗ trợ tiếp cận/trình đọc màn hình Android; cỡ chữ 200%.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Duyệt thanh trên bằng trình đọc màn hình | Đọc được nút đóng phiên, chế độ, ngữ cảnh và tiến độ/đồng hồ bằng chữ; không chỉ bằng màu/biểu tượng |
| 2 | Duyệt `Match`/`Guess` | Mỗi lựa chọn có nhãn rõ; A–E không che nghĩa; trạng thái được chọn/đúng/sai/bị vô hiệu hóa được đọc |
| 3 | Duyệt `Recall`/`Fill` | Đọc được “đáp án đang ẩn”, đồng hồ, gợi ý, ô nhập và kết cục sau chấm |
| 4 | Quan sát ở cỡ chữ 200% | Nội dung quan trọng không bị cắt, chồng hoặc đẩy hành động ra ngoài màn; có thể cuộn tới mọi hành động |

## Nhóm: Kịch bản ranh giới nền tảng

**Đây là toàn bộ những gì còn cần thiết bị.** Mọi luật nghiệp vụ mà các kịch bản
dưới đây đi qua đã được chứng minh ở `HOST-FLOW` hoặc `HOST-WIDGET`; phần việc
còn lại của nhóm này là chứng minh **ranh giới với hệ điều hành**, không phải
chứng minh lại nghiệp vụ.

Vì vậy mỗi kịch bản ở đây dựng **trạng thái tối thiểu** cần để chạm tới ranh giới
ấy. Một kịch bản `IT-PLAT` đi lại cả một luồng nghiệp vụ là một kịch bản đặt sai
chỗ.

## IT-PLAT-009 — Hệ thống cấp CJK mà app đã thôi bundle

- **Ưu tiên:** P0
- **Tiền điều kiện:** Bản dựng đã cài trên thiết bị, không sửa font hệ thống.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Dựng `TextStyle` với `fontFamilyFallback` **rỗng** sau face Latin | Không face nào của app trả lời cho CJK |
| 2 | Raster hoá Hangul, kana, Han và Hán giản thể | Mỗi ảnh có mực, không rỗng |
| 3 | Raster hoá cùng số ký tự vùng Private Use làm đối chứng | Đây là hình dạng của "không tìm thấy glyph" |
| 4 | So từng cặp | Bốn script phải **khác** đối chứng |

Kịch bản duy nhất trong danh mục canh một **payload** chứ không canh một
đường đi. App từng bundle ba face Noto CJK — 14,4 MB deflated, nhiều hơn
toàn bộ phần còn lại của bản tải — vì một nền tảng thiếu font sẽ vẽ nội
dung thẻ thành ô vuông. Android là target phát hành duy nhất và đã mang
`NotoSansCJK-Regular.ttc` từ Lollipop, nên hai trong ba face là bản sao của
một file đã nằm sẵn trên máy; chúng đã được gỡ.

**Vì sao host không thay thế được.** `flutter test` không có font collection
của hệ điều hành, nên nó không phân biệt được "nền tảng đã trả lời" với
"không ai trả lời". Mọi unit test trong repo vẫn xanh trên một thiết bị chỉ
hiện tofu. Đây là đúng nghĩa "thứ host không với tới".

**Tofu là đối chứng, không phải ô trắng.** Glyph thiếu không phải là khoảng
trống: Skia vẽ `.notdef` với advance thật, nên cả bề rộng lẫn việc "có mực"
đều không chứng minh được gì. Hai codepoint Private Use không font nào nhận,
nên chúng là hình dạng chuẩn của thất bại.

Hangul vẫn nằm trong phép đo dù app còn bundle face Hàn: nếu chính nó cũng
đỏ thì probe hỏng, chứ không phải ROM thiếu font.
