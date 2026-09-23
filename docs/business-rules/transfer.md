# Business rules — Card transfer (import/export)

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng TRANSFER, dưới ID vĩnh viễn `BR-TRANSFER-nnn` |
| **Scope** | Luật import và export card ra file. |
| **Source of truth for** | BR-TRANSFER-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

**Phạm vi:** sub-project sau — Import (spec §2).

## Import card từ file

Nửa nhập của Card Transfer.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-TRANSFER-001 | active | Deck đích của một lần import MUST thoả cùng điều kiện với việc tạo card đơn lẻ: là sub-deck có `content_type` `unset` hoặc `card`; root deck (BR-DECK-004) và deck đang giữ deck con (BR-DECK-010) MUST bị từ chối bằng lý do có kiểu. Điều kiện này MUST được kiểm tra lại **bên trong** transaction commit — deck có thể đã đổi loại hoặc biến mất giữa lúc preview và lúc ghi. | store | UC-TRANSFER-001, BR-DECK-004, BR-DECK-008, BR-DECK-010 |
| BR-TRANSFER-002 | active | Mỗi hàng import MUST có cả `front` và `back` sau khi trim; hàng chỉ có một trong hai là invalid, hàng trống toàn bộ được bỏ qua không tính là lỗi. Validation nội dung MUST tái sử dụng đúng các rule hiện có — BR-CARD-001/BR-CARD-002 cho hai mặt, BR-CARD-003 cho ba trường phụ, BR-TAG-001/BR-TAG-002 cho tag — MUST NOT có bộ validation thứ hai trong parser hoặc UI. Tag trong một ô MUST tách bằng dấu chấm phẩy `;`, MUST NOT dùng dấu phẩy vì nó là delimiter phổ biến của CSV. `front` MUST NOT bị từ chối chỉ vì không chứa Hangul — từ vay mượn, chữ số và ký hiệu vẫn hợp lệ. | rule | UC-TRANSFER-001, BR-CARD-001, BR-CARD-002, BR-TAG-001, BR-TAG-002, BR-CARD-003 |
| BR-TRANSFER-003 | active | Trùng lặp khi import MUST đo bằng khoá `front_folded + back_folded`, trong hai phạm vi: card đang có trong **chính deck đích**, và các hàng lặp lại trong cùng nguồn import; card ở deck khác MUST NOT bị coi là trùng. Mặc định trùng lặp bị bỏ qua; người dùng MAY bật "Include duplicates". Import MUST NOT cập nhật hay gộp vào card hiện có — trùng thì hoặc bỏ hoặc tạo bản thứ hai, không có đường thứ ba. Kiểm tra trùng MUST chạy lại **bên trong** transaction commit theo policy đã chọn, vì database có thể đổi giữa preview và import. | rule + store | UC-TRANSFER-001, BR-TRANSFER-004 |
| BR-TRANSFER-004 | active | Một lần import MUST ghi trong **đúng một** Drift transaction: toàn bộ card, **đúng một** study state mới cho mỗi card theo bảng khởi tạo BR-CARD-004 với scheduler và generation đọc từ root **một lần trong transaction đó**, tag tạo mới hoặc dùng lại theo tên đã fold (BR-TAG-001), và `content_type` của deck đích. Một write thất bại MUST rollback toàn bộ — không có partial card, state, tag hay content type. Không còn hàng hợp lệ nào để ghi thì MUST NOT có mutation nào. Import MUST NOT mang theo lịch học: không due date, không box, không SM-2 state, không history — card import là card mới. | store | UC-TRANSFER-001, BR-CARD-004, BR-TAG-001, BR-CARD-011 |
| BR-TRANSFER-005 | active | Deck đích đang `unset` MUST thành `card` trong cùng transaction với batch nếu có ít nhất một card được ghi (BR-DECK-008 áp cho lô); một lần import ghi zero card MUST NOT đổi `content_type`. | store | UC-TRANSFER-001, BR-DECK-008, BR-DECK-015 |
| BR-TRANSFER-006 | active | Nội dung import là dữ liệu riêng tư cùng mức với nội dung card (BR-STARTER-002): MUST NOT log nội dung card, văn bản đã dán, tên file hay hàng dữ liệu thô ở bất kỳ level nào — diagnostic chỉ MAY ghi format, số hàng, thời lượng và lỗi có kiểu. File MUST xử lý trong bộ nhớ ứng dụng, MUST NOT để lại bản sao ở thư mục dùng chung. V1 chỉ hỗ trợ UTF-8 và UTF-8 BOM; encoding khác MUST báo lỗi có hướng dẫn, MUST NOT đoán mò. | store + UI | UC-TRANSFER-001, BR-STARTER-002 |

---

## Export card ra file

**Phạm vi:** sub-project sau — Export (spec §2).

Nửa còn lại của Card Transfer. Các rule dưới đây **không** phát biểu lại
validation nội dung (BR-CARD-001, BR-CARD-002, BR-CARD-003), luật tag (BR-TAG-001, BR-TAG-002) hay luật
riêng tư chung (BR-PRIVACY-001…BR-PRIVACY-004) — chúng chỉ nói phần mà chiều export thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-TRANSFER-007 | active | Export MUST hỗ trợ đúng hai scope và MUST NOT có scope thứ ba ở v1. `all`: toàn bộ card **trực tiếp** của deck đang mở, độc lập với filter, search term, sort và pagination đang bật, MUST NOT gồm card của deck descendant. `selected`: đúng tập id đã materialize từ chế độ chọn (BR-CARD-012), id trùng MUST được normalize về một lần và MUST NOT nhân bản hàng trong file. Một id không còn tồn tại, hoặc không còn thuộc chính deck đó tại thời điểm đọc snapshot, MUST làm **cả request** thất bại bằng lý do có kiểu — MUST NOT export một phần im lặng. Scope rỗng (deck không còn card, hoặc tập chọn rỗng) MUST bị từ chối ở tầng nghiệp vụ kể cả khi UI đã ẩn action. | rule + store | UC-TRANSFER-002, BR-CARD-012 |
| BR-TRANSFER-008 | active | Artifact export MUST chỉ mang đúng sáu field nội dung canonical — `front · back · example · hint · pronunciation · tags` — và MUST NOT mang bất cứ thứ gì khác: id card hay deck, timestamp, cờ (BR-CARD-009), scheduler type/version/generation, box, ease factor, interval, due date, `learned_at`, review history hay dữ liệu session. Đây là **content transfer, không phải backup**: import lại chính file này MUST sinh id và study state mới (BR-TRANSFER-004). Rule này chi phối **dữ liệu thẻ và dữ liệu học ghi vào các ô của file**. Metadata do chính định dạng container sinh ra — cụ thể là timestamp của từng entry trong file zip mà XLSX là — nằm ngoài phạm vi: nó không dẫn xuất từ bất kỳ thẻ nào, không mô tả thẻ nào, và MUST NOT được đọc ngược thành dữ liệu. Hệ quả là hai lần export cùng một dữ liệu ra XLSX MAY khác nhau ở mức byte; điều phải giống nhau là nội dung logic, và đó là BR-TRANSFER-010. | rule | UC-TRANSFER-002, BR-TRANSFER-004, BR-TRANSFER-010 |
| BR-TRANSFER-009 | active | Ô `tags` MUST đi qua đúng **một** codec dùng chung cho cả Import và Export; MUST NOT có bản thứ hai trong encoder, decoder hay preview. Encode: các tag nối bằng `;` (BR-TRANSFER-002); `;` bên trong một tag MUST escape thành `\;` và `\` MUST escape thành `\\`. Decode: backslash MUST chỉ được coi là escape khi đứng ngay trước `;` hoặc `\`; backslash trước ký tự khác và backslash ở cuối ô MUST giữ nguyên verbatim, vì nguồn legacy chưa từng escape. Round-trip export → import MUST giữ nguyên cả spelling lẫn tập tag. | rule | UC-TRANSFER-002, UC-TRANSFER-001, BR-TAG-001, BR-TRANSFER-002 |
| BR-TRANSFER-010 | active | Cùng một dữ liệu MUST cho ra cùng một artifact **về mặt nội dung logic**: cùng tập record, cùng thứ tự record, cùng thứ tự tag trong mỗi record, và cùng giá trị từng ô. Determinism này MUST NOT được hiểu là byte-identical — container của XLSX ghi timestamp riêng của nó vào từng zip entry (BR-TRANSFER-008), nên hai file byte khác nhau vẫn thoả rule khi giải mã ra cùng nội dung. Card MUST sắp theo `created_at ASC` với tie-break `id ASC`, **áp cho cả hai scope**; scope `selected` MUST NOT theo thứ tự người dùng chạm. Tag của mỗi card MUST sắp theo tên đã fold (BR-TAG-001) với tie-break ổn định. Tên deck, nội dung card và tag MUST đến từ **một snapshot nhất quán**, MUST NOT ghép từ nhiều lần đọc rời nhau và MUST NOT đọc tag theo kiểu N+1. | store | UC-TRANSFER-002, BR-TAG-001 |
| BR-TRANSFER-011 | active | Export MUST là thao tác chỉ-đọc: MUST NOT ghi hay chạm tới nội dung card, `updated_at` hay bất kỳ timestamp nào, `content_type` của deck (BR-DECK-015), study state, review history, session, cờ hay quan hệ tag. Export thành công MUST NOT xoá selection hiện tại — BR-CARD-012 chỉ bắt xoá selection sau một **mutation** thành công, và export không phải mutation. | store + UI | UC-TRANSFER-002, BR-DECK-015, BR-CARD-012 |
| BR-TRANSFER-012 | active | Mọi file export MUST mở đầu bằng đúng sáu header canonical theo đúng thứ tự đã liệt kê ở BR-TRANSFER-008, chữ thường tiếng Anh, và MUST NOT localize theo ngôn ngữ app. Field tuỳ chọn không có giá trị MUST là ô rỗng, MUST NOT là `null`, `-` hay chuỗi placeholder. CSV và TSV MUST ghi kèm UTF-8 BOM — đối xứng với encoding mà Import chấp nhận (BR-TRANSFER-006). XLSX MUST ghi mọi ô dưới dạng **text**, nên nội dung bắt đầu bằng `=`, `+`, `-` hoặc `@` MUST NOT trở thành formula, và chuỗi trông như số (`001`, `1e3`, `+84…`) MUST giữ nguyên nguyên văn. | store | UC-TRANSFER-002, BR-TRANSFER-008, BR-TRANSFER-006 |
| BR-TRANSFER-013 | active | Tên file export MUST dẫn xuất từ tên deck đã sanitize — loại ký tự phân cách đường dẫn, ký tự điều khiển và ký tự không hợp lệ của hệ tệp, gộp khoảng trắng liên tiếp thành một, trim hai đầu — cộng một ngày lấy từ `clockProvider` và phần mở rộng theo format đã chọn. Sanitize ra chuỗi rỗng thì phần tên MUST fallback về `cards`. MUST NOT gọi `DateTime.now()` ở bất kỳ layer nào, và tên file MUST NOT xuất hiện trong log ở bất kỳ level nào (BR-TRANSFER-006). | rule | UC-TRANSFER-002, BR-TRANSFER-006 |
| BR-TRANSFER-014 | active | File export là dữ liệu riêng tư cùng mức nội dung card (BR-PRIVACY-001, BR-PRIVACY-002) và MUST chỉ được tạo khi người dùng chủ động yêu cầu (BR-PRIVACY-004). Ứng dụng MUST NOT xin quyền truy cập bộ nhớ diện rộng, và MUST NOT ghi artifact vào thư mục dùng chung trước một hành động tường minh của người dùng; bản tạm MUST nằm trong vùng riêng của ứng dụng và là transient. Bàn giao file MUST đi qua share sheet của hệ điều hành. Người dùng đóng share sheet MUST được hiểu là **cancel**, MUST NOT báo lỗi. UI MUST NOT nói file đã được lưu khi hệ điều hành không xác nhận điều đó — copy trung thực nói "đã bàn giao cho hệ thống", không nói "đã lưu". | store + UI | UC-TRANSFER-002, BR-PRIVACY-001, BR-PRIVACY-002, BR-PRIVACY-004, BR-TRANSFER-006 |

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Import vào deck `unset`, có ít nhất một card ghi được | Deck thành `card` trong cùng transaction (BR-TRANSFER-005) |
| Import mà mọi hàng đều trùng hoặc invalid | Không mutation nào; `content_type` giữ nguyên (BR-TRANSFER-004, BR-TRANSFER-005) |
| Import vào root deck hoặc deck đang giữ deck con | Chặn trong transaction, lỗi có kiểu (BR-TRANSFER-001) |
| Hàng chỉ có `front`, thiếu `back` | Hàng invalid, hiện lý do; các hàng khác không bị ảnh hưởng (BR-TRANSFER-002) |
| Hai hàng trong file cùng `front`+`back` sau fold | Hàng sau đánh dấu trùng-trong-file; mặc định bỏ qua (BR-TRANSFER-003) |
| Card cùng nội dung đã có sẵn trong deck đích | Đánh dấu trùng-với-deck; bật Include duplicates thì vẫn ghi (BR-TRANSFER-003) |
| Một write giữa batch thất bại | Rollback toàn bộ — không partial card/state/tag (BR-TRANSFER-004) |
| Export scope `all` khi danh sách đang bật filter/search | File vẫn chứa toàn bộ card trực tiếp của deck, không phải tập đã lọc (BR-TRANSFER-007) |
| Export scope `selected` có id lặp lại | Normalize còn một hàng; số card trong file khớp số id phân biệt (BR-TRANSFER-007) |
| Một card trong tập chọn bị xoá hoặc chuyển deck trước lúc đọc | Cả request thất bại có kiểu; không sinh file một phần (BR-TRANSFER-007) |
| Tag chứa `;` hoặc `\` | Escape khi ghi, khôi phục nguyên văn khi import lại (BR-TRANSFER-009) |
| Ô nội dung bắt đầu bằng `=` hoặc `+` | Ghi như text trong XLSX; mở bằng spreadsheet không thành formula (BR-TRANSFER-012) |
| Tên deck chỉ gồm ký tự bị loại khi sanitize | Tên file dùng `cards` + ngày + đuôi format (BR-TRANSFER-013) |
| Người dùng đóng share sheet | Coi là cancel; không toast lỗi, không nói đã lưu (BR-TRANSFER-014) |
