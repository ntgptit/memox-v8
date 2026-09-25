# Progress — dữ liệu

Bảng, cột, index và invariant nằm ở `shared/data/schema.md`. File này chỉ giữ phần dữ liệu riêng của feature.

## Đọc lịch sử học

Progress chỉ đọc `review_log`, nối với `card` và `deck`. Nó không ghi hàng nào và không
mở hay đóng phiên nào (BR-PROGRESS-007, BR-PROGRESS-009).

- **Lượt được tính:** lượt của thẻ còn sống, thẻ và deck không nằm trong Trash. Hàng có
  `mode = 'browse'` không bao giờ được tính (BR-PROGRESS-012). Card bị xoá cứng mang lịch
  sử của nó đi theo cascade của schema (BR-PROGRESS-017).
- **Ngày của một lượt:** `(answered_at + offset) / 86400`, với `answered_at` tính bằng
  giây UTC và offset là UTC offset của lần đọc, áp cho mọi hàng kể cả hàng cũ
  (BR-PROGRESS-011). Dart tính hôm nay, ngày đầu của mỗi khoảng và nửa đêm kế tiếp; SQL
  không tự dẫn xuất nửa đêm (BR-PROGRESS-013).
- **Card-day:** một thẻ trong một ngày là một card-day. Card-day là Learning khi ngày đó
  có ít nhất một lượt `kind = 'learning'`, còn lại là Reviewing (BR-PROGRESS-002,
  BR-PROGRESS-005, BR-PROGRESS-014). Lịch sử quy cho vị trí hiện tại của thẻ
  (BR-PROGRESS-004).

## Các câu lệnh

`/progress` đọc ba câu lệnh trong một transaction:

1. các ngày có học trên toàn lịch sử tới hôm nay, cho streak (BR-PROGRESS-016);
2. card-day của bảy ngày gần nhất, tách Learning và Reviewing, cho Today và biểu đồ
   (BR-PROGRESS-014, BR-PROGRESS-015);
3. mọi root deck với bốn số của cả cây cho 7 và 30 ngày, và một hàng tổng từ cùng câu
   lệnh (BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-003).

`/progress/:deckId` đọc đường dẫn của deck, rồi các deck con trực tiếp với bốn số của
subtree và hàng tổng của cả subtree, gồm thẻ nằm trực tiếp trong deck. Deck không còn
hoặc đang trong Trash cho ra trạng thái "deck không còn" (UC-PROGRESS-002 E2).

## Khi nào đọc lại

Sau mỗi lần ghi vào `review_log`, `card` hay `deck` (một transaction, một lần đọc), và ở
mỗi nửa đêm địa phương (BR-PROGRESS-008, BR-PROGRESS-018).
