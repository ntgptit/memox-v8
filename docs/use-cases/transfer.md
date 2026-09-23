# Use cases — Card transfer

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng TRANSFER, dưới ID vĩnh viễn `UC-TRANSFER-nnn` |
| **Scope** | Luồng import và export card. |
| **Source of truth for** | UC-TRANSFER-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-TRANSFER-001 · Import card hàng loạt vào một deck

| | |
|---|---|
| **Status** | active |

**Phạm vi:** sub-project sau — Import (spec §2).

**Actor:** Người dùng
**Trigger:** Chọn "Import cards" từ card list của một deck loại card, từ empty
state của card list, hoặc từ lựa chọn tạo phần tử con của một deck `unset`
**Preconditions:** Deck đích tồn tại và là sub-deck `unset` hoặc `card` (BR-TRANSFER-001)

**Main flow:**
1. Người dùng mở màn import; hệ thống hiển thị deck đích, số card hiện có và
   ba bước Source → Preview → Import.
2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV.
3. Người dùng bấm Preview; hệ thống parse nguồn trong bộ nhớ (BR-TRANSFER-006) — không
   ghi gì vào database.
4. Hệ thống mặc định coi hàng đầu là header và tự map các cột trùng tên
   (front, back, example, hint, pronunciation, tags — không phân biệt hoa
   thường); người dùng chỉnh mapping nếu cần. `front` và `back` bắt buộc phải
   được map; một cột nguồn không map vào hai đích (BR-TRANSFER-002).
5. Hệ thống validate toàn bộ hàng bằng đúng các rule của card (BR-TRANSFER-002), đánh
   dấu trùng lặp theo BR-TRANSFER-003, và hiển thị: tổng số hàng, số sẵn sàng, số trùng,
   số invalid kèm lý do, số hàng trống đã bỏ qua, cùng các hàng đầu tiên.
6. Người dùng bấm Continue rồi xác nhận ở bước Import — màn xác nhận nêu deck
   đích, số card sẽ ghi, số trùng bị bỏ/ghi, số invalid bị loại.
7. Hệ thống ghi toàn bộ trong một transaction (BR-TRANSFER-004): card, study state mới
   cho từng card, tag, và `content_type` nếu deck đang `unset` (BR-TRANSFER-005).
8. Hệ thống hiện kết quả — số đã ghi, số trùng bỏ qua, số invalid bị loại — với
   hai lối ra: View cards về card list (danh sách tự cập nhật qua stream),
   hoặc Import another file giữ deck đích và làm lại từ bước Source.

**Alternative flows:**
- **A1 — Dán văn bản:** ở bước Source người dùng dán các hàng CSV/TSV vào ô
  nhập; parse chỉ chạy khi bấm Preview, và văn bản giữ nguyên khi parse lỗi.
- **A2 — XLSX nhiều sheet:** hệ thống mặc định chọn sheet không rỗng đầu tiên
  và cho người dùng đổi sheet; đổi sheet chạy lại bước 4–5.
- **A3 — Không có header:** người dùng tắt "First row contains headers"; các
  cột hiển thị tên vị trí ổn định (Column A, Column B, …) và hàng đầu được
  validate như dữ liệu.
- **A4 — Bao gồm trùng lặp:** người dùng bật "Include duplicates"; số sẵn sàng
  gồm cả các hàng trùng, và commit ghi chúng như card mới (BR-TRANSFER-003).
- **A5 — Đổi file:** người dùng thay file đã chọn; hủy hộp chọn file không
  phải lỗi và không xoá lựa chọn trước đó.

**Error flows:**
- **E1 — File không đọc được:** file hỏng, có mật khẩu, đuôi không hỗ trợ hoặc
  encoding không phải UTF-8/UTF-8 BOM (BR-TRANSFER-006) → lỗi có kiểu kèm hướng dẫn
  (export lại UTF-8); nguồn đã chọn trước đó giữ nguyên.
- **E2 — Nguồn rỗng:** file/sheet/văn bản không có hàng dữ liệu nào → thông báo
  rõ ở bước Preview; không đi tiếp được.
- **E3 — Không còn hàng hợp lệ:** sau validate và policy trùng lặp, số sẽ ghi
  bằng 0 → Continue bị khoá; không có mutation nào (BR-TRANSFER-004).
- **E4 — Deck đích không còn hợp lệ lúc ghi:** deck biến mất, thành root-level
  hoặc đã giữ deck con → transaction từ chối bằng lý do có kiểu (BR-TRANSFER-001), không
  ghi gì; preview và mapping giữ nguyên.
- **E5 — Commit thất bại giữa chừng:** một write lỗi → rollback toàn bộ
  (BR-TRANSFER-004); màn import giữ nguyên nguồn, mapping và preview, hiện Try again.

**Postconditions:** Mọi card được ghi có đúng một study state mới theo scheduler
của root (BR-TRANSFER-004); card, tiến độ và history đã có từ trước không bị sửa;
`content_type` của deck đích phản ánh đúng nội dung sau import (BR-TRANSFER-005).

**Business rules:** BR-CARD-001, BR-CARD-002, BR-CARD-004, BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TAG-001, BR-TAG-002,
BR-CARD-003, BR-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005, BR-TRANSFER-006

**UI states:** initial (Source trống) · source đã chọn · parsing · parse error ·
preview loaded (đủ valid/invalid/duplicate/blank) · preview empty (E2/E3) ·
confirm · submitting · commit error · result. Không có state "refreshing" —
nguồn chỉ parse lại khi người dùng đổi nguồn, sheet, header hoặc bấm lại
Preview.

---

## UC-TRANSFER-002 · Export card của một deck ra file

| | |
|---|---|
| **Status** | active |

**Phạm vi:** sub-project sau — Export (spec §2).

**Actor:** Người dùng
**Trigger:** Chọn `Export cards` trong overflow menu của card list, hoặc
`Export selected` trên thanh hành động của chế độ chọn (UC-CARD-001 A6)
**Preconditions:** Deck đang mở là sub-deck loại `card` và có ít nhất một card;
với lối chọn nhiều thì tập chọn không rỗng (BR-TRANSFER-007)

**Main flow:**
1. Người dùng mở export từ một trong hai entry point; hệ thống mở một sheet và
   hiển thị **scope đã cố định, chỉ đọc**: `All N cards in this deck` hoặc
   `N selected cards`. Sheet không cho đổi scope — scope là hệ quả của lối vào
   (BR-TRANSFER-007).
2. Hệ thống hiển thị ba format — CSV (mặc định, gắn nhãn Recommended), TSV,
   XLSX — cùng một dòng nói file chứa nội dung và tag, và một dòng nói tiến độ
   học và lịch sử **không** nằm trong file (BR-TRANSFER-008).
3. Người dùng chọn format nếu muốn khác mặc định, rồi bấm `Export N cards`.
4. Hệ thống đọc một snapshot nhất quán gồm tên deck, nội dung sáu field và tag
   theo thứ tự xác định (BR-TRANSFER-010), không ghi gì vào database (BR-TRANSFER-011).
5. Hệ thống encode snapshot thành artifact theo format đã chọn — sáu header
   canonical, ô rỗng cho field trống, BOM cho CSV/TSV, ô text cho XLSX
   (BR-TRANSFER-012) — và đặt tên file từ tên deck đã sanitize cộng ngày (BR-TRANSFER-013).
6. Hệ thống ghi artifact vào vùng riêng tạm thời của ứng dụng rồi bàn giao cho
   share sheet của hệ điều hành (BR-TRANSFER-014).
7. Người dùng chọn đích ở share sheet. Hệ thống đóng sheet export và báo đã bàn
   giao file cho hệ thống — **không** khẳng định đã lưu ở đâu (BR-TRANSFER-014).

**Alternative flows:**
- **A1 — Scope là tập đã chọn:** vào từ thanh hành động chọn nhiều; file chứa
  đúng tập id đã materialize, id trùng chỉ xuất hiện một lần, và thứ tự vẫn là
  `created_at ASC` chứ không phải thứ tự chạm (BR-TRANSFER-007, BR-TRANSFER-010). Selection giữ
  nguyên sau khi export xong (BR-TRANSFER-011).
- **A2 — Đổi format:** chọn TSV hoặc XLSX; canonical schema, thứ tự card và ô
  tags không đổi, chỉ lớp mã hoá đổi (BR-TRANSFER-012).
- **A3 — Đóng share sheet:** người dùng thoát share sheet mà không chọn đích.
  Đây là **cancel**: không báo lỗi, sheet export trở lại trạng thái ban đầu với
  scope và format đang chọn, và không có tuyên bố nào về việc đã lưu (BR-TRANSFER-014).
- **A4 — Bấm export lần thứ hai khi đang tạo file:** hệ thống MUST bỏ qua lần
  bấm sau; primary action bị khoá cho tới khi lần đầu kết thúc, và không có hai
  artifact nào được tạo cho một lần mở sheet.
- **A5 — Huỷ trước khi submit:** `Cancel`, chạm ra ngoài sheet hoặc Android Back
  đóng sheet, không tạo file, không đụng selection.

**Error flows:**
- **E1 — Nền tảng không có share sheet:** hệ thống báo rằng chia sẻ không khả
  dụng trên thiết bị này, giữ sheet mở với scope và format đang chọn, và không
  để lại artifact nào.
- **E2 — Lỗi từ nền tảng khi chia sẻ:** exception của platform channel map
  thành lý do có kiểu; thông báo MUST NOT lộ đường dẫn, tên file hay nội dung
  card (BR-TRANSFER-013, BR-TRANSFER-014); Retry giữ nguyên scope và format.
- **E3 — Đọc dữ liệu thất bại:** đọc dữ liệu lỗi khi lấy snapshot → lý do có
  kiểu, không có file, không có mutation (BR-TRANSFER-011); Retry chạy lại từ bước 4.
- **E4 — Encode thất bại:** encoder lỗi → lý do có kiểu phân biệt được với lỗi
  đọc, không có artifact một phần nào được bàn giao.
- **E5 — Không có gì để export:** deck rỗng hoặc tập chọn rỗng → domain từ chối
  bằng lý do có kiểu (BR-TRANSFER-007). Entry point không hiện khi deck rỗng, nên đây là
  chặn tầng dưới cho deep link và cho cây đổi sau khi sheet đã mở.
- **E6 — Id đã chọn không còn hợp lệ:** một id trong tập chọn đã bị xoá hoặc đã
  chuyển sang deck khác → **cả request** thất bại có kiểu, không sinh file một
  phần (BR-TRANSFER-007); thông báo mời người dùng chọn lại.

**Postconditions:** Database không đổi — nội dung, timestamp, `content_type`,
study state, history, cờ và tag đều nguyên vẹn (BR-TRANSFER-011). Artifact chỉ chứa sáu
field nội dung (BR-TRANSFER-008) và chỉ tồn tại ở vùng riêng tạm thời cho tới khi người
dùng chọn đích ở share sheet (BR-TRANSFER-014).

**Business rules:** BR-PRIVACY-001, BR-PRIVACY-002, BR-PRIVACY-004, BR-TAG-001, BR-TAG-002, BR-DECK-015, BR-CARD-012, BR-TRANSFER-007,
BR-TRANSFER-008, BR-TRANSFER-009, BR-TRANSFER-010, BR-TRANSFER-011, BR-TRANSFER-012, BR-TRANSFER-013, BR-TRANSFER-014

**UI states:** initial (scope + format, primary bật) · generating (primary khoá,
Cancel còn dùng được) · share requested · dismissed (về initial, không lỗi) ·
unavailable/platform error · read error · encoder error · invalid scope
(rỗng hoặc id đã cũ). Không có state `loading` khi mở sheet — scope và số card
đã có sẵn từ màn gọi; và không có state `empty`, vì scope rỗng là lỗi (E5) chứ
không phải một màn hình trống.
