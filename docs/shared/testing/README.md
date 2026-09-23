# Bộ kịch bản kiểm thử tích hợp theo hành trình người dùng

## 1. Mục tiêu

Bộ tài liệu này mô tả MemoX hoạt động đúng ở mức hành trình người dùng. **Nó
không nói kịch bản phải chạy ở đâu** — cột `Profile` của
[`scenario-catalog.md`](scenario-catalog.md) nói điều đó, và luật chọn nằm ở
[`testing-pyramid-audit.md`](testing-pyramid-audit.md).

**Ba hồ sơ, và cái tên nói đúng chỗ chạy:**

| Profile | Chạy bằng | Chứng minh cái gì |
|---|---|---|
| `HOST-FLOW` | `flutter test` | Luật nghiệp vụ, scheduler, truy vấn, transaction, hàng đợi, `due_at`, resume — qua rule và store thật trên SQLite in-memory thật |
| `HOST-WIDGET` | `flutter test` | Người dùng thao tác được qua giao diện Flutter thật, và giao diện phản ánh đúng state nghiệp vụ |
| `DEVICE-E2E` | emulator/thiết bị | Chỉ ranh giới với hệ điều hành: khởi động nguội, chết tiến trình, deep link, cử chỉ nền tảng, smoke phát hành |

**"Mọi bước kiểm tra phải đi qua UI" chỉ đúng cho `DEVICE-E2E`.** Ở đó, gọi
thẳng store là bỏ qua chính ranh giới đang cần chứng minh. Áp luật đó cho
*mọi* kịch bản thì mọi kịch bản đều đòi emulator theo mặc định. Một luật
`due_at` chứng minh bằng store + SQLite thật là bằng chứng **mạnh hơn**,
không yếu hơn, so với việc đọc một con số trên màn hình.

Một bộ dữ liệu dựng sẵn MAY được dùng để chuẩn bị trạng thái. Với `DEVICE-E2E`
nó vẫn phải có đường dẫn hiện vật và phiên bản; với hai hồ sơ host thì test tự
tạo database của chính nó, nên "dựng sẵn" chỉ là mã dựng hàng.

Hai tập thẻ học MUST tách hẳn theo BR-STUDY-051: **Học mới** có `learned_at IS
NULL`; **Ôn tập** có `learned_at IS NOT NULL AND due_at <= now`. Thẻ mới không
được gọi là “đến hạn”. Bộ dữ liệu dựng sẵn hoặc kịch bản nào còn gộp hai tập
này là `DOC-DRIFT`, không phải bằng chứng cho sản phẩm.

Phần chức năng học gồm **64 kịch bản** tách theo năm tệp năng lực; không phải 64
ca trong Bảng quyết định. Mỗi ID là một hành trình người dùng có tiền điều kiện,
thao tác, tiêu chí kết luận và mức sẵn sàng độc lập.

Bốn kịch bản Navigation liên quan trực tiếp tới chức năng học là `IT-NAV-002` và
`IT-NAV-008` tới `IT-NAV-010`. Vì vậy tổng phạm vi Study cần kiểm kê khi chạy là
**68 kịch bản**: 64 kịch bản năng lực Study cộng bốn kịch bản điều hướng.

AI agent MUST đọc theo thứ tự:

1. File này — phạm vi và dữ liệu nghiệp vụ chung.
2. [`agent-execution-guide.md`](agent-execution-guide.md) — cách chuẩn bị,
   kết luận và báo cáo mà không suy đoán.
3. [`scenario-catalog.md`](scenario-catalog.md) — mức sẵn sàng, hồ sơ thực thi,
   chuẩn bị, dọn dẹp và truy vết của đúng ID kịch bản.
4. Tệp năng lực chứa các bước của kịch bản.

## 2. Phạm vi hiện tại

| Nhóm | Trạng thái | Tài liệu |
|---|---|---|
| Giao thức thực thi cho AI agent | Bắt buộc đọc | [`agent-execution-guide.md`](agent-execution-guide.md) |
| Danh mục từng ID kịch bản | Bắt buộc tra cứu | [`scenario-catalog.md`](scenario-catalog.md) |
| Khởi động, điều hướng, tiếp tục | Có thể kiểm thử | [`features/deck/it-scenarios.md`](../../features/deck/it-scenarios.md) · [`features/progress/it-scenarios.md`](../../features/progress/it-scenarios.md) · [`features/study/it-scenarios.md`](../../features/study/it-scenarios.md) · [`features/transfer/it-scenarios.md`](../../features/transfer/it-scenarios.md) · [`shared/testing/it-scenarios.md`](it-scenarios.md) |
| Vòng đời bộ thẻ gốc | Có thể kiểm thử | [`features/deck/it-scenarios.md`](../../features/deck/it-scenarios.md) |
| Cây bộ thẻ, `content_type`, di chuyển | Có thể kiểm thử | [`features/card/it-scenarios.md`](../../features/card/it-scenarios.md) · [`features/deck/it-scenarios.md`](../../features/deck/it-scenarios.md) |
| Tìm kiếm, lọc, sắp xếp, tiến độ bộ thẻ | Có thể kiểm thử | [`features/deck/it-scenarios.md`](../../features/deck/it-scenarios.md) |
| Vòng đời thẻ | Có thể kiểm thử | [`features/card/it-scenarios.md`](../../features/card/it-scenarios.md) · [`features/transfer/it-scenarios.md`](../../features/transfer/it-scenarios.md) |
| Tìm kiếm, siêu dữ liệu, lọc, tiến độ thẻ | Có thể kiểm thử | [`features/card/it-scenarios.md`](../../features/card/it-scenarios.md) · [`features/tags/it-scenarios.md`](../../features/tags/it-scenarios.md) · [`shared/testing/it-scenarios.md`](it-scenarios.md) |
| Điểm vào chức năng học và tùy chọn | Có thể kiểm thử | [`features/deck/it-scenarios.md`](../../features/deck/it-scenarios.md) · [`features/study/it-scenarios.md`](../../features/study/it-scenarios.md) |
| Phiên học mới | Có thể kiểm thử | [`features/srs/it-scenarios.md`](../../features/srs/it-scenarios.md) · [`features/study-mode/it-scenarios.md`](../../features/study-mode/it-scenarios.md) · [`features/study/it-scenarios.md`](../../features/study/it-scenarios.md) |
| Phiên ôn tập và thuật toán xếp lịch | Cần bộ dữ liệu Study v2 cho phần lớn kịch bản | [`features/srs/it-scenarios.md`](../../features/srs/it-scenarios.md) · [`features/study-mode/it-scenarios.md`](../../features/study-mode/it-scenarios.md) · [`features/study/it-scenarios.md`](../../features/study/it-scenarios.md) |
| Sáu chế độ học | Có thể kiểm thử; một số ca biên cần dữ liệu dựng sẵn | [`features/study-mode/it-scenarios.md`](../../features/study-mode/it-scenarios.md) · [`features/study/it-scenarios.md`](../../features/study/it-scenarios.md) · [`shared/testing/it-scenarios.md`](it-scenarios.md) |
| Tiếp tục phiên, ngoại tuyến và lỗi | Có thể kiểm thử | [`features/srs/it-scenarios.md`](../../features/srs/it-scenarios.md) · [`features/study/it-scenarios.md`](../../features/study/it-scenarios.md) |
| Định nghĩa và lý do chọn hồ sơ thực thi cho từng kịch bản | Tham chiếu | [`testing-pyramid-audit.md`](testing-pyramid-audit.md) |
| Ranh giới nền tảng — thứ duy nhất còn cần thiết bị | Có thể kiểm thử | [`features/deck/it-scenarios.md`](../../features/deck/it-scenarios.md) · [`features/study/it-scenarios.md`](../../features/study/it-scenarios.md) · [`shared/testing/it-scenarios.md`](it-scenarios.md) |
| Hồ sơ thực thi và truy vết UC/BR theo từng kịch bản | Tham chiếu | [`host-coverage-map.md`](host-coverage-map.md) |

**Không có kịch bản `FIXTURE-BLOCKED` nào** — cả 141 dòng của
`scenario-catalog.md` đều `READY`. Luật "không được ghi thẳng vào cơ sở dữ
liệu" là luật viết cho **một thiết bị**; nó không áp cho một test host tự
dựng SQLite in-memory của chính nó (§4.3).

Các luồng sau MUST NOT được ghi nhận là đạt khi chạy trên bản dựng V8.0:

- Đổi trực tiếp thuật toán xếp lịch của bộ thẻ gốc đã khóa mà không đi qua
  Đặt lại tiến độ học không phải luồng được hỗ trợ.
- Luồng thuộc phạm vi ngoài V8.0 theo spec
  `docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md` §2: sáu
  sub-project sau (Trash, nhập/xuất, tag, nhắc học hằng ngày, thư viện
  starter deck tức UC-STARTER-001, thống kê mở rộng) và những gì ngoài V8 hoàn toàn
  (đa phương tiện, xác thực, đồng bộ/máy chủ, iOS/web/desktop). Kịch bản của
  các luồng này vẫn là tài liệu nghiệp vụ cho sub-project sau, không phải
  tiêu chí nghiệm thu của V8.0.

## 3. Quy ước kịch bản

| Trường | Ý nghĩa |
|---|---|
| ID | Ổn định theo năng lực: các nhóm cũ và `IT-STUDY`, `IT-LEARN`, `IT-REVIEW`, `IT-MODE`, `IT-CONT` |
| Ưu tiên `P0` | Luồng chính hoặc bất biến nghiệp vụ; hỏng thì không thể tin cậy hoặc phát hành năng lực tương ứng, đặc biệt chức năng học |
| Ưu tiên `P1` | Chức năng quan trọng nhưng có đường vòng hoặc không chặn luồng chính |
| Ưu tiên `P2` | Trạng thái phụ, usability hoặc dữ liệu lớn |
| Tiền điều kiện | Trạng thái có trước khi người dùng bắt đầu kịch bản |
| Các bước | Thao tác nghiệp vụ qua bề mặt nhìn thấy; tiêu chí chỉ kiểm được ở dữ liệu lưu trữ phải dùng công cụ kiểm tra chỉ đọc theo hướng dẫn thực thi |
| Hậu điều kiện | Dữ liệu còn lại để quyết định có thể nối kịch bản hay phải đặt lại dữ liệu ứng dụng |

Mức sẵn sàng (`Readiness`), hồ sơ thực thi, chuẩn bị và dọn dẹp không lặp lại trong từng
kịch bản. Chúng nằm trong một dòng duy nhất theo ID tại `scenario-catalog.md`.
Giá trị dọn dẹp chính là hợp đồng hậu điều kiện để kịch bản kế tiếp không vô
tình nhận dữ liệu sót lại.

Mỗi kịch bản SHOULD chạy độc lập. Nếu chạy nối chuỗi, người kiểm thử MUST dùng đúng hậu
điều kiện của kịch bản trước làm tiền điều kiện cho kịch bản sau.

### 3.1. Thuật ngữ dành cho người rà soát và AI agent

Phần diễn giải MUST dùng tiếng Việt có dấu. Chỉ giữ tiếng Anh trong dấu backtick
khi đó là enum, tên trường dữ liệu, mã chuẩn bị hoặc nhãn phải đối chiếu nguyên văn.

| Cách gọi trong tài liệu | Giá trị canonical khi cần đối chiếu |
|---|---|
| phiên học thẻ mới | `learning` |
| phiên ôn tập | `reviewing` |
| giai đoạn học | `stage` |
| chế độ học | `mode` |
| hàng đợi | `queue` |
| tập thẻ đã chốt khi mở phiên | `snapshot` |
| thuật toán xếp lịch | `scheduler` |
| bộ dữ liệu dựng sẵn | `fixture` |
| tiêu chí kết luận | `oracle` |
| thẻ mới / thẻ đến hạn | nhãn `New` / `Due` nếu giao diện dùng đúng hai nhãn này |

AI agent MUST hiểu cột bên trái là ngôn ngữ rà soát; cột bên phải chỉ dùng để
đối chiếu tài liệu kỹ thuật hoặc giao diện, không phải một khái niệm thứ hai.

## 4. Môi trường và dữ liệu chuẩn

### 4.1. Môi trường

- Target chính: Android, locale tiếng Việt, kích thước màn hình điện thoại.
- Web MAY dùng làm kênh E2E development nhưng không thay thế vòng xác nhận Android.
- Chế độ máy bay là **tiền điều kiện của lượt chạy, không phải một bước**: không
  widget nào tắt được sóng, nên môi trường CI cho `DEVICE-E2E` MUST bật trước
  và tắt sau khi chạy.
- “Khởi động lại ứng dụng” nghĩa là đóng hẳn tiến trình rồi mở lại, không chỉ
  chuyển tab. **Bên trong `flutter test` thì không làm được điều đó** — một
  tiến trình không tự giết mình rồi đi tiếp; harness chỉ mở lại được cơ sở dữ
  liệu trong cùng tiến trình test (mục 6.1 của
  [`agent-execution-guide.md`](agent-execution-guide.md)), bằng chứng
  thấp hơn một lần hệ điều hành thật thu hồi tiến trình.

### 4.2. Dữ liệu tạo qua UI

| Mã | Dữ liệu |
|---|---|
| `D-EB` | Bộ thẻ gốc `Giao tiếp hằng ngày`, thuật toán Eight Box |
| `D-SM2` | Bộ thẻ gốc `IELTS 2026`, thuật toán SM-2 |
| `D-BRANCH` | Bộ thẻ con `Vocabulary`, loại `deck` sau khi có bộ thẻ con |
| `D-LEAF` | Bộ thẻ con `Academic words`, loại `card` sau khi tạo thẻ đầu tiên |
| `C-001` | Mặt trước `abandon`, mặt sau `từ bỏ`, câu ví dụ `He abandoned the plan.`, phát âm `/əˈbændən/` |
| `C-002` | Mặt trước `benevolent`, mặt sau `nhân từ`, gợi ý `starts with bene`, nhãn `IELTS` |
| `C-003` | Mặt trước `concise`, mặt sau `ngắn gọn`, nhãn `Writing`, đã gắn cờ |

### 4.3. Dữ liệu seed dành riêng cho trạng thái học

Các mã `S-PROGRESS`, `S-DUE`, `S-LARGE` và `S-STUDY-*` có hợp đồng xác định tại
[`agent-execution-guide.md`](agent-execution-guide.md) mục 5–6.

**Tám kịch bản `DEVICE-E2E` không dùng loader nào.** Mỗi kịch bản tự dựng đúng
trạng thái tối thiểu nó cần, qua giao diện. Đó là điều kiện tiên quyết chứ không
phải một bước, và nó giữ cho bộ device không mọc lại một tầng fixture thứ hai.

**Luật "không tự tạo SQL" là luật của thiết bị, không phải của mọi tầng.** Agent
MUST NOT sửa cơ sở dữ liệu **của ứng dụng đang chạy trên thiết bị** để vượt trở
ngại — làm thế là chứng minh một trạng thái mà sản phẩm không tự đến được. Một
test host dựng SQLite in-memory của chính nó thì không nằm trong luật ấy: cơ sở
dữ liệu đó *là* fixture.

Dữ liệu dựng sẵn MUST dùng nội dung giả, không dùng dữ liệu cá nhân thật.

## 5. Traceability nghiệp vụ

| Nguồn | Scenario chính |
|---|---|
| UC-DECK-001 — tạo bộ thẻ gốc | `IT-DECK-001`, `IT-DECK-002`, `IT-DECK-003`, `IT-DECK-004` |
| UC-DECK-002 — sửa/xoá bộ thẻ | `IT-DECK-005`, `IT-DECK-006`, `IT-DECK-007`, `IT-DECK-008`, `IT-TREE-007`, `IT-TREE-008`, `IT-TREE-014` |
| UC-CARD-001 — quản lý thẻ | `IT-CARD-001` tới `IT-CARD-011`; `IT-ORG-001` tới `IT-ORG-012` |
| UC-DECK-003 — danh sách bộ thẻ và tiến độ | `IT-DISC-001` tới `IT-DISC-008`; `IT-ORG-011` |
| UC-DECK-004 — tạo phần tử con, xác lập loại | `IT-TREE-001` tới `IT-TREE-008`; `IT-TREE-013` |
| UC-DECK-005 — di chuyển bộ thẻ | `IT-TREE-009` tới `IT-TREE-013` |
| UC-STUDY-001 — điểm vào và tùy chọn | `IT-STUDY-001` tới `IT-STUDY-013` |
| UC-STUDY-001 — điều hướng Study | `IT-NAV-002`, `IT-NAV-008` tới `IT-NAV-010` |
| UC-STUDY-001 — học mới | `IT-LEARN-001` tới `IT-LEARN-012` |
| UC-STUDY-001 — ôn tập và thuật toán xếp lịch | `IT-REVIEW-001` tới `IT-REVIEW-010` |
| UC-STUDY-001 — StudyMode | `IT-MODE-001` tới `IT-MODE-015` |
| UC-STUDY-001 — tiếp tục và lỗi | `IT-CONT-001` tới `IT-CONT-014` |
| Hành trình deck/card xuyên suốt và ngoại tuyến | `IT-NAV-006`, `IT-NAV-007`, `IT-PLAT-002` |
| Ranh giới nền tảng — thứ duy nhất còn chạy trên thiết bị | `IT-PLAT-001` tới `IT-PLAT-006`; `IT-NAV-007`, `IT-CONT-008` |

Bảng trên giúp người đọc định hướng. Traceability machine-readable theo từng ID
nằm tại [`scenario-catalog.md`](scenario-catalog.md) và là nguồn chuẩn.

## 6. Definition of ready cho AI agent

Một kịch bản chỉ sẵn sàng để agent chạy khi:

- ID tồn tại đúng một lần trong tệp kịch bản và đúng một lần trong danh mục.
- Catalog ghi `READY`.
- Mã chuẩn bị có công thức hoặc hiện vật đã được triển khai.
- Agent điều khiển được nền tảng và hồ sơ thực thi yêu cầu. Cột `Profile` của
  `scenario-catalog.md` là thứ quyết định kịch bản chạy ở đâu — tài liệu kịch
  bản MUST NOT phát biểu lại điều đó.
- Kết quả mong đợi có thể kết luận theo quy tắc kiểm tra trong hướng dẫn thực thi.

Thiếu một điều kiện trên thì agent MUST báo `BLOCKED` hoặc `DOC-DRIFT`; không tự
điền phần còn thiếu bằng phỏng đoán.
