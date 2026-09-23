---
id: UC-TRANSFER-002
title: Export card của một deck ra file
status: ready
rules: [BR-CARD-012, BR-DECK-015, BR-PRIVACY-001, BR-PRIVACY-002, BR-PRIVACY-004, BR-TAG-001, BR-TAG-002, BR-TRANSFER-007, BR-TRANSFER-008, BR-TRANSFER-009, BR-TRANSFER-010, BR-TRANSFER-011, BR-TRANSFER-012, BR-TRANSFER-013, BR-TRANSFER-014]
code: []
---
## Mục tiêu / Actor / Precondition

**Phạm vi:** sub-project sau — Export (spec §2).

**Actor:** Người dùng
**Trigger:** Chọn `Export cards` trong overflow menu của card list, hoặc
`Export selected` trên thanh hành động của chế độ chọn (UC-CARD-001 A6)
**Preconditions:** Deck đang mở là sub-deck loại `card` và có ít nhất một card;
với lối chọn nhiều thì tập chọn không rỗng (BR-TRANSFER-007)

## Main flow

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

## Alternative / Error flow

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

## UI

**UI states:** initial (scope + format, primary bật) · generating (primary khoá,
Cancel còn dùng được) · share requested · dismissed (về initial, không lỗi) ·
unavailable/platform error · read error · encoder error · invalid scope
(rỗng hoặc id đã cũ). Không có state `loading` khi mở sheet — scope và số card
đã có sẵn từ màn gọi; và không có state `empty`, vì scope rỗng là lỗi (E5) chứ
không phải một màn hình trống.

## Local

**Postconditions:** Database không đổi — nội dung, timestamp, `content_type`,
study state, history, cờ và tag đều nguyên vẹn (BR-TRANSFER-011). Artifact chỉ chứa sáu
field nội dung (BR-TRANSFER-008) và chỉ tồn tại ở vùng riêng tạm thời cho tới khi người
dùng chọn đích ở share sheet (BR-TRANSFER-014).

## API

Không áp dụng — ứng dụng local-only, không network ([quyết định nền tảng](../../../product/product.md#platform-decisions)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
