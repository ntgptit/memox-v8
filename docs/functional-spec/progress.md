# Progress — functional specification

Các chức năng của feature progress. Định dạng: [docs/README.md](../README.md), mục "UC, FN và
screen spec". Progress không có failure type riêng: lỗi đọc database đi theo mô hình lỗi của
ADR-016.

Cả hai chức năng chỉ đọc: chúng không ghi hàng nào và không mở, tiếp tục hay đóng phiên nào, kể cả
khi lỗi hay thử lại. Đơn vị đếm là **card-day** — một cặp phân biệt (thẻ, ngày địa phương) — không
phải số lượt trả lời; một card-day là *Learning* khi ngày đó thẻ có ít nhất một lượt `learning`, và
*Reviewing* khi không. `browse` không ghi lượt nên không tạo card-day. Lịch sử được tính cho **vị
trí hiện tại** của thẻ, nên chuyển thẻ thì toàn bộ lịch sử của nó đi theo. Đặt lại tiến độ học
giữ lịch sử, nên không đổi con số nào; thẻ bị xoá cứng mất khỏi mọi ngày, kể cả ngày quá khứ.

**Bốn số** của một phạm vi trong một khoảng là: số thẻ có hoạt động, số ngày có hoạt động, số
card-day Learning và số card-day Reviewing. Có đúng hai khoảng, 7 ngày và 30 ngày, mỗi khoảng là
trọn các ngày địa phương kết thúc bằng hôm nay. Một danh sách deck sắp theo số thẻ có hoạt động
giảm dần của khoảng đang xét, hoà thì theo tên đã gập rồi `id`; deck không có hoạt động vẫn có
hàng, ở cuối. Đổi khoảng không cần đọc lại.

Mỗi lần phát đọc đồng hồ và múi giờ **một** lần, và mọi con số của lần đó dùng chung ranh giới
"hôm nay" (từ 00:00 địa phương). Cả hai chức năng phát lại khi lịch sử, thẻ hay deck đổi, và tại
nửa đêm địa phương, không cần thao tác nào.

## FN-PROGRESS-001 — Xem tiến độ của thư viện
Status: active · Code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/domain/models/progress_overview_model.dart, lib/features/progress/domain/models/progress_level_model.dart]

### Precondition

Không có. Thư viện rỗng và thư viện chưa học lần nào đều là kết quả hợp lệ.

### Input

Không có.

### Kết quả

Một stream, mỗi lần phát gồm:

- **Tổng quan:** Today — tổng card-day của hôm nay cùng phân rã Learning / Reviewing; Last 7 days —
  đúng bảy ngày, hôm nay và sáu ngày trước, cũ → mới, ngày trống là 0; Current streak — số ngày
  liên tiếp có hoạt động, tính từ hôm nay nếu hôm nay đã học, **giữ nguyên** từ hôm qua nếu hôm nay
  chưa học mà hôm qua có, và 0 khi không; cùng trạng thái của nó (gồm hôm nay, đang giữ từ hôm
  qua, đã mất, chưa từng học) và ngày có hoạt động gần nhất.
- **Cấp thư viện:** cho mỗi khoảng, bốn số của toàn bộ dữ liệu, và danh sách mỗi root deck một
  hàng với bốn số của **cả cây** của nó.
- Thời điểm kết quả hết hiệu lực: nửa đêm địa phương kế tiếp.

Không có con số nào ngoài các con số trên (độ chính xác, streak dài nhất, mục tiêu, điểm, heatmap…).

### Lỗi

- Đọc database thất bại: stream báo lỗi; không gì được ghi, và đọc lại là thử lại.

### Business rules

- BR-MODE-005
- BR-PROGRESS-001
- BR-PROGRESS-002
- BR-PROGRESS-003
- BR-PROGRESS-004
- BR-PROGRESS-005
- BR-PROGRESS-006
- BR-PROGRESS-007
- BR-PROGRESS-008
- BR-PROGRESS-009
- BR-PROGRESS-010
- BR-PROGRESS-011
- BR-PROGRESS-012
- BR-PROGRESS-013
- BR-PROGRESS-014
- BR-PROGRESS-015
- BR-PROGRESS-016
- BR-PROGRESS-017
- BR-PROGRESS-018
- BR-SRS-015
- BR-SRS-023
- BR-STUDY-074

## FN-PROGRESS-002 — Xem tiến độ của một deck
Status: active · Code: [lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart, lib/features/progress/domain/models/progress_model.dart, lib/features/progress/domain/models/progress_level_model.dart]

### Precondition

Không có.

### Input

- Deck: root hoặc deck con.

### Kết quả

Một stream, mỗi lần phát là một trong hai:

- **Cấp của deck:** đường dẫn từ root tới deck; cho mỗi khoảng, bốn số của cả cây con của deck,
  và danh sách mỗi deck con **trực tiếp** một hàng với bốn số của cây con của nó. Deck chỉ chứa thẻ
  có tổng mà không có hàng nào. Kèm thời điểm kết quả hết hiệu lực: nửa đêm địa phương kế tiếp.
- **Deck không còn:** deck đã bị xoá, đang ở Trash hoặc không tồn tại. Đây không phải lỗi: đọc lại
  sẽ cho cùng kết quả.

### Lỗi

- Đọc database thất bại: stream báo lỗi; không gì được ghi, và đọc lại là thử lại.

### Business rules

- BR-DECK-003
- BR-PROGRESS-001
- BR-PROGRESS-002
- BR-PROGRESS-003
- BR-PROGRESS-004
- BR-PROGRESS-005
- BR-PROGRESS-006
- BR-PROGRESS-007
- BR-PROGRESS-008
- BR-STUDY-074
