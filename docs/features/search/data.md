# Search — dữ liệu

Bảng, cột, index và invariant nằm ở `shared/data/schema.md`. File này chỉ giữ phần dữ liệu riêng của feature.

## Những gì được tìm

Tìm kiếm chỉ đọc bốn trường: tên deck, mặt trước và mặt sau của card, tên tag. Nó không
đọc `example`, `hint` hay `pronunciation` (BR-SEARCH-001). Deck và card nằm trong Trash,
và card của một deck nằm trong Trash, không bao giờ hiện: mọi câu lệnh lọc
`delete_batch_id IS NULL`, trên card lẫn trên deck của nó.

- **Chuẩn hoá:** câu truy vấn đi qua đúng hàm fold mà các cột `*_folded` dùng khi ghi:
  bỏ khoảng trắng hai đầu, hạ chữ theo Unicode của Dart, giữ dấu (BR-SEARCH-002). SQL
  không dùng `lower()` hay `COLLATE NOCASE`. Câu truy vấn fold thành rỗng không chạy câu
  lệnh nào (BR-SEARCH-003).
- **Tên deck** không có cột folded: tên được fold trong Dart, từ một lần đọc cây deck.
- **Card và tag** được so trên `card.front_folded`, `card.back_folded` và
  `tags.name_folded`, bằng `=` và `instr`. Không dùng `LIKE`, nên `%` và `_` trong câu
  truy vấn là ký tự thường.

## Thứ tự

- Khớp đúng, rồi khớp tiền tố, rồi khớp chứa (BR-SEARCH-004). Bậc của một card là bậc
  tốt nhất trong mặt trước, mặt sau và các tag của nó. Card khớp ở nhiều trường vẫn là
  một kết quả, và chỉ mang tên tag khi không mặt nào khớp (BR-SEARCH-006).
- Deck trước, card sau (BR-SEARCH-005). Trong mỗi nhóm: bậc khớp, rồi văn bản đã fold
  (tên deck; `front_folded` của card), `created_at`, `id` (BR-SEARCH-007). Văn bản được
  so theo code point. Đó là thứ tự BINARY của SQLite trên UTF-8, nên Dart (nhóm deck) và
  SQLite (nhóm card) sắp theo cùng một cách.

## Các câu lệnh

Mỗi lần đọc chạy trong một transaction:

1. một câu lệnh đọc mọi deck không nằm trong Trash: các deck để khớp tên, và đường dẫn
   của mọi kết quả, cả deck lẫn card (BR-SEARCH-009);
2. câu lệnh card: mỗi card một hàng, bậc của từng trường tính bằng subquery tương quan,
   không `DISTINCT` trên phép join. Câu lệnh phân trang theo keyset
   `(bậc, front_folded, created_at, id)` với `LIMIT`, không `OFFSET` (BR-SEARCH-007).

Một trang có 50 kết quả, deck trước. Màn hình xem mọi kết quả tới con trỏ `through`
(trang đầu khi chưa có con trỏ). Mỗi lần đọc trả về `nextThrough`, con trỏ kết thúc trang
kế tiếp, hoặc không trả về con trỏ nào khi đã hết kết quả. Khi mọi kết quả tới `through`
đã biến mất trong khi vẫn còn kết quả phía sau, trang đầu hiện ra. Một lần đọc chạy tối
đa hai câu lệnh card; ba chỉ trong trường hợp vừa nói.

## Khi nào đọc lại

Sau mỗi lần ghi vào `deck`, `card`, `card_tags` hay `tags` (một transaction, một lần
đọc), nên đường dẫn, tên và tag đang hiển thị luôn đúng. Tìm kiếm không ghi hàng nào và
không mở phiên nào (BR-SEARCH-008).

## Hiệu năng

Không có index hay bảng FTS nào cho tìm kiếm (BR-SEARCH-009): câu lệnh card quét mọi card
còn sống bằng `instr`. `EXPLAIN QUERY PLAN` và thời gian đo trên khoảng 10.000 và 50.000
card nằm ở D11 của
[spec gói 5](../../superpowers/specs/2026-09-25-library-search-backend-design.md).
