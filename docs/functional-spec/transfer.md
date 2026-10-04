# Transfer — functional specification

Các chức năng của feature transfer (import và export card). Định dạng:
[docs/README.md](../README.md), mục "UC, FN và screen spec". Lỗi là các giá trị của
`TransferRejection` (`lib/features/transfer/domain/failures/transfer_failure.dart`); lỗi ghi hay đọc
database không nằm trong đó mà đi theo mô hình lỗi của ADR-016.

Một file trao đổi có đúng sáu cột nội dung, theo thứ tự: `front`, `back`, `example`, `hint`,
`pronunciation`, `tags`. Ô `tags` dùng **một** cách mã hoá cho cả import lẫn export. Tiến độ học và
lịch sử không bao giờ nằm trong file. Nội dung được đọc vào hay xuất ra là dữ liệu riêng tư như nội
dung card.

## FN-TRANSFER-001 — Đọc nguồn import
Status: active · Code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/models/source_table_model.dart, lib/features/transfer/domain/models/transfer_source_model.dart]

### Precondition

Không có.

### Input

- Nguồn: một file CSV, TSV hoặc XLSX, hoặc văn bản CSV/TSV được dán vào.
- Sheet, với XLSX nhiều sheet: không có nghĩa là sheet không rỗng đầu tiên.

### Kết quả

Nguồn được đọc thành bảng các hàng, trong bộ nhớ; không gì được ghi. Văn bản phải là UTF-8, có hoặc
không có BOM. TSV phân cách bằng tab. CSV phân cách bằng `,` hoặc `;`: tính phần ngoài dấu nháy kép,
dấu nào xuất hiện cùng số lần, ít nhất một lần, ở mọi hàng trong tối đa 20 hàng không trống đầu tiên
thì được chọn; khi cả hai hoặc không dấu nào như vậy, file phân cách bằng `;` nếu hàng không trống
đầu tiên có `;` mà không có `,`, còn lại bằng `,`. Văn bản dán vào là TSV khi hàng không trống đầu
tiên có tab ngoài dấu nháy kép, còn lại được đọc như CSV. Với XLSX, kết quả gồm cả danh sách sheet
để đổi sang sheet khác.

### Lỗi

- `unreadableFile` — file không phải CSV, TSV hay XLSX, hoặc hỏng, hoặc có mật khẩu.
- `badEncoding` — văn bản không phải UTF-8.

### Business rules

- BR-TRANSFER-006

## FN-TRANSFER-002 — Xem trước một lần import
Status: active · Code: [lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/models/import_preview_model.dart, lib/features/transfer/domain/models/column_mapping_model.dart]

### Precondition

Nguồn đã được đọc.

### Input

- Deck đích.
- Bảng nguồn.
- Cách map cột nguồn sang sáu cột nội dung; mặc định các cột có tên trùng (không phân biệt hoa
  thường) được map sẵn.
- Hàng đầu có phải header không: mặc định có; không thì các cột mang tên theo vị trí (Column A,
  Column B, …) và hàng đầu là dữ liệu.

### Kết quả

Trạng thái của từng hàng dữ liệu so với deck **lúc này**, xét theo thứ tự: **trống** (bị bỏ qua);
**không hợp lệ**, kèm luật card đầu tiên nó vi phạm — đúng các luật như khi tạo card, kể cả tag;
**trùng một card trong deck**; **trùng một hàng hợp lệ trước đó** trong nguồn, kèm hàng đó; hoặc
**sẵn sàng**. Trùng là trùng cả mặt trước lẫn mặt sau sau khi gập. Kèm các con số: tổng, sẵn sàng,
trùng, không hợp lệ, trống. Không gì được ghi.

### Lỗi

- `mappingIncomplete` — `front` hoặc `back` chưa được map, hoặc hai cột nguồn map vào cùng một cột.
- `emptySource` — không hàng dữ liệu nào có nội dung.

### Business rules

- BR-CARD-001
- BR-CARD-002
- BR-CARD-003
- BR-CARD-004
- BR-TAG-001
- BR-TAG-002
- BR-TRANSFER-002
- BR-TRANSFER-003
- BR-TRANSFER-006
- BR-TRANSFER-009

## FN-TRANSFER-003 — Import card vào deck
Status: active · Code: [lib/features/transfer/domain/usecases/commit_import_use_case.dart, lib/features/transfer/domain/models/import_summary_model.dart]

### Precondition

Đã có bản xem trước, và người dùng đã xác nhận deck đích, số card sẽ ghi và cách xử lý hàng trùng.

### Input

- Deck đích.
- Bản xem trước.
- Có ghi cả hàng trùng không: mặc định không; có thì cả hai loại trùng được ghi thành card mới.

### Kết quả

Trong một transaction, tất cả hoặc không gì: mỗi hàng được ghi thành một card mới với đúng một
trạng thái học mới theo scheduler của root, cùng tag của nó; deck đích chưa chứa gì thì thành deck
chứa card. Không có lịch sử ôn tập nào được tạo, và không card hay tiến độ nào có từ trước bị sửa.
Việc kiểm tra trùng với deck **chạy lại** trong transaction, nên một hàng đã thành trùng từ lúc xem
trước không được ghi khi trùng bị loại. Kết quả: số card đã ghi, số hàng trống, và từng hàng bị bỏ
qua — không hợp lệ, trùng, hoặc vừa thành trùng lúc ghi — với số dòng và lý do. Không ghi được card
nào thì deck không đổi gì, kể cả loại nội dung.

### Lỗi

- `nothingToImport` — theo cách xử lý trùng đã chọn, không hàng nào sẽ được ghi; không gì được ghi.
- `targetRejected` — deck đích không còn, là root, hoặc đã chứa deck con; không gì được ghi.
- Ghi database thất bại: rollback toàn bộ.

### Business rules

- BR-DECK-004
- BR-DECK-008
- BR-DECK-010
- BR-TRANSFER-001
- BR-TRANSFER-003
- BR-TRANSFER-004
- BR-TRANSFER-005

## FN-TRANSFER-004 — Đếm card một lần export sẽ có
Status: active · Code: [lib/features/transfer/domain/usecases/count_export_cards_use_case.dart]

### Precondition

Không có.

### Input

- Deck.

### Kết quả

Số card active của deck mà một lần export cả deck sẽ chứa; 0 khi deck không có card nào. Không ghi
gì.

### Lỗi

- Đọc database thất bại.

### Business rules

- BR-TRANSFER-007

## FN-TRANSFER-005 — Tạo file export
Status: active · Code: [lib/features/transfer/domain/usecases/build_export_use_case.dart, lib/features/transfer/domain/models/export_artifact_model.dart, lib/features/transfer/domain/models/transfer_format_model.dart, lib/features/transfer/domain/models/tags_cell_model.dart]

### Precondition

Chỉ khi người dùng yêu cầu.

### Input

- Deck.
- Phạm vi: cả deck, hoặc một tập card đã chọn; phạm vi là hệ quả của nơi người dùng bắt đầu, không
  đổi được sau đó.
- Định dạng: CSV, TSV hoặc XLSX.
- Ngày hôm nay theo đồng hồ của app.

### Kết quả

Một file, từ **một** lần đọc nhất quán: tên deck, và sáu cột nội dung cùng tag của từng card, card
theo `created_at` rồi `id` — không theo thứ tự người dùng chọn — và tag theo tên đã gập. Mỗi card
xuất hiện đúng một lần. File có sáu header chuẩn, ô rỗng cho cột trống, BOM với CSV và TSV, và mọi
ô XLSX là text — `=1+1` hay `001` không thành công thức hay số. Tên file là tên deck đã bỏ các ký tự
hệ thống tệp không nhận, khoảng trắng gộp thành `-`, rồi ngày và đuôi của định dạng; tên rỗng sau
khi làm sạch thành `cards`. Không gì được ghi vào database, kể cả khi lỗi.

### Lỗi

- `emptyScope` — không có card nào để export.
- `staleSelection` — một card đã chọn đã bị xoá hoặc đã chuyển sang deck khác; cả yêu cầu thất bại,
  không có file một phần.
- `encodeFailed` — không ghi được file; không có file một phần nào.
- Đọc database thất bại.

### Business rules

- BR-CORE-004
- BR-TRANSFER-007
- BR-TRANSFER-008
- BR-TRANSFER-009
- BR-TRANSFER-010
- BR-TRANSFER-011
- BR-TRANSFER-012
- BR-TRANSFER-013

## FN-TRANSFER-006 — Chia sẻ file export
Status: active · Code: [lib/features/transfer/domain/usecases/share_export_use_case.dart]

### Precondition

File export đã được tạo.

### Input

- File export.

### Kết quả

File nằm trong vùng tạm riêng của app và được giao cho bảng chia sẻ của hệ điều hành. Kết quả là
**đã giao** khi người dùng chọn một đích, hoặc **đã đóng** khi người dùng thoát mà không chọn — đó là
huỷ, không phải lỗi. Không kết quả nào nói file đã được lưu ở đâu.

### Lỗi

- `shareUnavailable` — thiết bị không có bảng chia sẻ.
- `shareFailed` — nền tảng lỗi khi chia sẻ; lý do không chứa đường dẫn, tên file hay nội dung card.

### Business rules

- BR-CORE-001
- BR-TRANSFER-013
- BR-TRANSFER-014
